// DNShareBridge.swift
// @_cdecl FFI entry points for the dart_native_share plugin.
//
// Exposes UIActivityViewController as a small set of C functions so Dart
// apps can share text and one-or-more files without Flutter platform
// channels.
//
// Ported from share_plus 13.1.0, FPPSharePlusPlugin.m:
// Copyright 2019 The Flutter Authors. All rights reserved.
// BSD-3-Clause; the full licence is reproduced in THIRD_PARTY_NOTICES.

import LinkPresentation
import UIKit

// MARK: - Helpers

/// The app's primary icon, resolved from Info.plist (asset-catalog icons are
/// addressable by their CFBundleIconFiles name) — re-rendered large at
/// scale 1: the share sheet draws iconProvider images at their POINT size,
/// so the ~60pt app-icon rendition would float small inside the white
/// preview tile instead of filling it.
private func dnAppIcon() -> UIImage? {
  guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
        let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
        let files = primary["CFBundleIconFiles"] as? [String],
        let name = files.last,
        let icon = UIImage(named: name)
  else { return nil }
  let side: CGFloat = 300
  let format = UIGraphicsImageRendererFormat()
  format.scale = 1
  return UIGraphicsImageRenderer(
    size: CGSize(width: side, height: side), format: format
  ).image { _ in
    icon.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
  }
}

/// Wraps a plain-text share so the sheet header shows the APP's icon instead
/// of the system's generic text glyph — bare strings in activityItems get
/// Apple's default preview; LPLinkMetadata via UIActivityItemSource is the
/// supported way to brand it. The header title stays the text's first line.
private final class DNShareTextItemSource: NSObject, UIActivityItemSource {
  private let text: String
  init(_ text: String) { self.text = text }

  func activityViewControllerPlaceholderItem(
    _ activityViewController: UIActivityViewController
  ) -> Any { text }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? { text }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    text.components(separatedBy: .newlines).first ?? text
  }

  func activityViewControllerLinkMetadata(
    _ activityViewController: UIActivityViewController
  ) -> LPLinkMetadata? {
    let md = LPLinkMetadata()
    md.title = text.components(separatedBy: .newlines).first ?? text
    if let icon = dnAppIcon() {
      md.iconProvider = NSItemProvider(object: icon)
    }
    return md
  }
}

/// Walk the VC hierarchy to find the topmost presented controller.
private func topViewController(
  base: UIViewController? = nil
) -> UIViewController? {
  let root = base ?? UIApplication.shared
    .connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .first { $0.activationState == .foregroundActive }?
    .windows
    .first { $0.isKeyWindow }?
    .rootViewController
  if let nav = root as? UINavigationController {
    return topViewController(base: nav.visibleViewController)
  }
  if let tab = root as? UITabBarController,
     let selected = tab.selectedViewController {
    return topViewController(base: selected)
  }
  if let presented = root?.presentedViewController {
    return topViewController(base: presented)
  }
  return root
}

/// Present the sheet. When `completion` is non-nil it is installed as the
/// activity controller's `completionWithItemsHandler`; returns false when
/// there is no view controller to present from.
@discardableResult
private func presentShareSheet(
  items: [Any],
  completion: UIActivityViewController.CompletionWithItemsHandler? = nil
) -> Bool {
  guard let vc = topViewController() else { return false }

  let activity = UIActivityViewController(
    activityItems: items,
    applicationActivities: nil
  )
  activity.completionWithItemsHandler = completion

  // iPad: anchor the popover to a sensible default (top-center of the screen)
  // so the app doesn't crash with the "no sourceView" assertion.
  if let popover = activity.popoverPresentationController {
    popover.sourceView = vc.view
    let w = vc.view.bounds.width
    popover.sourceRect = CGRect(x: w / 2, y: 0, width: 1, height: 1)
    popover.permittedArrowDirections = .up
  }

  vc.present(activity, animated: true)
  return true
}

// MARK: - Result dispatcher (Option 3 — framework-invalidated slot)
//
// Dart hands us ONE dispatcher address for the whole plugin
// (`DNShareSetDispatcher`). We never capture it in a closure: it lives in a
// heap slot registered with the framework via DNRegisterAsyncDispatcherSlot,
// which zeroes it BEFORE the old isolate dies on hot restart — so a share
// sheet still open across a restart delivers into 0 and drops, never into a
// freed trampoline. Every fire re-reads the slot and runs on the main thread.
// Recipe: dartnative docs, plugin_async_callbacks.md (option 3).

/// (token, status, raw) — status: 0 dismissed, 1 success, 2 unavailable.
private typealias ShareResultDispatch =
  @convention(c) (Int64, Int32, UnsafePointer<CChar>) -> Void

private let _dispatcherSlot: UnsafeMutablePointer<Int64> = {
  let p = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
  p.pointee = 0
  return p
}()
private var _slotRegistered = false

@_cdecl("DNShareSetDispatcher")
public func DNShareSetDispatcher(_ callbackPtr: Int64) {
  _dispatcherSlot.pointee = callbackPtr
  if !_slotRegistered {
    _slotRegistered = true
    typealias RegFn = @convention(c) (UnsafeMutablePointer<Int64>) -> Void
    if let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2),
                       "DNRegisterAsyncDispatcherSlot") {
      unsafeBitCast(sym, to: RegFn.self)(_dispatcherSlot)
    }
  }
}

/// EVERY delivery to Dart goes through here — main thread, fresh slot read.
private func fireShareResult(token: Int64, status: Int32, raw: String) {
  DispatchQueue.main.async {
    let addr = _dispatcherSlot.pointee   // read FRESH — nulled pre-teardown
    guard addr != 0 else { return }      // hot restart happened → drop
    raw.withCString { cStr in
      unsafeBitCast(addr, to: ShareResultDispatch.self)(token, status, cStr)
    }
    // Dart copies the string during the call — no ownership to manage.
  }
}

/// Builds the completion handler for a `*WithResult` request.
private func resultHandler(
  _ token: Int64
) -> UIActivityViewController.CompletionWithItemsHandler {
  return { activityType, completed, _, _ in
    fireShareResult(
      token: token,
      status: completed ? 1 : 0,
      raw: activityType?.rawValue ?? ""
    )
  }
}

private func cString(_ ptr: UnsafePointer<CChar>?) -> String? {
  guard let ptr = ptr else { return nil }
  let s = String(cString: ptr)
  return s.isEmpty ? nil : s
}

/// Read a `const char**` array of `count` UTF-8 string pointers into
/// `[String]`. Skips NULL elements. Returns `[]` for a NULL array.
private func cStringArray(
  _ ptr: UnsafePointer<UnsafePointer<CChar>?>?,
  count: Int32
) -> [String] {
  guard let ptr = ptr, count > 0 else { return [] }
  var result: [String] = []
  result.reserveCapacity(Int(count))
  for i in 0..<Int(count) {
    if let s = ptr[i] {
      result.append(String(cString: s))
    }
  }
  return result
}

// MARK: - Share text

/// Present the system share sheet for `text`.
///
/// Dispatches to the main thread automatically — safe to call from any
/// Dart isolate or UI callback.
@_cdecl("DNShareText")
public func DNShareText(_ textPtr: UnsafePointer<CChar>?) {
  guard let text = cString(textPtr) else { return }
  DispatchQueue.main.async {
    presentShareSheet(items: [DNShareTextItemSource(text)])
  }
}

// MARK: - Share file(s) (+ optional caption text)

/// Present the system share sheet for one or more files, optionally
/// accompanied by caption `text`.
///
/// - `pathsPtr` / `pathCount`: required, array of absolute filesystem paths.
/// - `mimeTypesPtr` / `mimeCount`: optional on iOS (UIActivityViewController
///   infers from extension); accepted for API parity with Android. If
///   `mimeCount == 0` or `mimeTypesPtr == nullptr`, ignored.
/// - `textPtr`: optional caption (e.g. WhatsApp caption). May be NULL.
@_cdecl("DNShareFiles")
public func DNShareFiles(
  _ pathsPtr: UnsafePointer<UnsafePointer<CChar>?>?,
  _ pathCount: Int32,
  _ mimeTypesPtr: UnsafePointer<UnsafePointer<CChar>?>?,
  _ mimeCount: Int32,
  _ textPtr: UnsafePointer<CChar>?
) {
  let paths = cStringArray(pathsPtr, count: pathCount)
  guard !paths.isEmpty else { return }
  _ = cStringArray(mimeTypesPtr, count: mimeCount)  // unused on iOS
  let caption = cString(textPtr)

  DispatchQueue.main.async {
    var items: [Any] = paths.map { URL(fileURLWithPath: $0) as Any }
    if let caption = caption {
      items.append(caption)
    }
    presentShareSheet(items: items)
  }
}

// MARK: - Share with result

/// Like DNShareText, but reports the outcome to the Dart dispatcher under
/// `token`: success(activityType) when the user picked a target, dismissed
/// when they closed the sheet, unavailable when there was nothing to
/// present from.
@_cdecl("DNShareTextWithResult")
public func DNShareTextWithResult(
  _ token: Int64,
  _ textPtr: UnsafePointer<CChar>?
) {
  guard let text = cString(textPtr) else {
    fireShareResult(token: token, status: 2, raw: "")
    return
  }
  DispatchQueue.main.async {
    if !presentShareSheet(items: [DNShareTextItemSource(text)],
                          completion: resultHandler(token)) {
      fireShareResult(token: token, status: 2, raw: "")
    }
  }
}

/// Like DNShareFiles, but reports the outcome to the Dart dispatcher under
/// `token`. See DNShareTextWithResult for the status semantics.
@_cdecl("DNShareFilesWithResult")
public func DNShareFilesWithResult(
  _ token: Int64,
  _ pathsPtr: UnsafePointer<UnsafePointer<CChar>?>?,
  _ pathCount: Int32,
  _ mimeTypesPtr: UnsafePointer<UnsafePointer<CChar>?>?,
  _ mimeCount: Int32,
  _ textPtr: UnsafePointer<CChar>?
) {
  let paths = cStringArray(pathsPtr, count: pathCount)
  guard !paths.isEmpty else {
    fireShareResult(token: token, status: 2, raw: "")
    return
  }
  _ = cStringArray(mimeTypesPtr, count: mimeCount)  // unused on iOS
  let caption = cString(textPtr)

  DispatchQueue.main.async {
    var items: [Any] = paths.map { URL(fileURLWithPath: $0) as Any }
    if let caption = caption {
      items.append(caption)
    }
    if !presentShareSheet(items: items, completion: resultHandler(token)) {
      fireShareResult(token: token, status: 2, raw: "")
    }
  }
}

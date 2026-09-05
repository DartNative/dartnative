# dartnative_podhelper.rb — DartNative CocoaPods helpers (iOS)
#
# Generic build-time fixups for DartNative apps, applied from the app's Podfile
# `post_install` so they work for EVERY plugin with no per-plugin setup.
#
#   require_relative '<path>/dartnative_ios/ios/dartnative_podhelper.rb'
#   ...
#   post_install do |installer|
#     installer.pods_project.targets.each { |t| flutter_additional_ios_build_settings(t) }
#     DartNative.resign_native_asset_frameworks(installer)
#   end
#
module DartNative
  RESIGN_PHASE_NAME = 'DartNative — Re-sign Native Asset Frameworks'.freeze

  # Re-sign any embedded *.framework that carries only an ad-hoc (local)
  # signature, using the app's real codesigning identity.
  #
  # Why: some DartNative plugins ship a **native-asset** framework built by a
  # Dart `build.dart` hook (e.g. dartnative_sqlite's `sqlite3.framework`, from
  # the `sqlite3` package). Those frameworks are signed **ad-hoc**
  # (`Signature=adhoc`, no TeamIdentifier). iOS `installd` rejects ad-hoc embedded
  # frameworks on a device install with `0xe8008014` ("invalid signature").
  #
  # This adds a single, idempotent build phase to the Runner target that detects
  # and re-signs any such framework — so it works generically for any current or
  # future native-asset plugin, with zero Podfile changes per plugin. Simulator
  # builds (no Frameworks dir / no signing) are a no-op.
  def self.resign_native_asset_frameworks(installer)
    runner_project = installer.aggregate_targets
      .find { |t| t.name == 'Pods-Runner' }&.user_project
    return unless runner_project

    runner_target = runner_project.targets.find { |t| t.name == 'Runner' }
    return unless runner_target

    return if runner_target.shell_script_build_phases.any? { |p| p.name == RESIGN_PHASE_NAME }

    phase = runner_target.new_shell_script_build_phase(RESIGN_PHASE_NAME)
    phase.shell_script = <<~'SCRIPT'
      # Re-sign embedded frameworks that carry only an ad-hoc (local) signature
      # with the app's real identity, so iOS installd accepts them on device.
      [ -d "${CODESIGNING_FOLDER_PATH}/Frameworks" ] || exit 0
      find "${CODESIGNING_FOLDER_PATH}/Frameworks" -name "*.framework" | while read -r fw; do
        if codesign -dv "$fw" 2>&1 | grep -q "Signature=adhoc"; then
          echo "DartNative: re-signing ad-hoc framework $(basename "$fw")"
          codesign --force \
            --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
            --preserve-metadata=identifier,entitlements,flags \
            "$fw" 2>/dev/null || true
        fi
      done
    SCRIPT

    runner_project.save
  end
end

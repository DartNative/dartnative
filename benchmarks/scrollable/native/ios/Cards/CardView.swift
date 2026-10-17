import UIKit

/// The example's palette.
enum Palette {
  static let screenBackground = UIColor(rgb: 0x445566)
  static let headerBox = UIColor(rgb: 0x456AAA)
  static let outerBackground = UIColor(rgb: 0x050505)
  static let cardBackground = UIColor(rgb: 0x141414)
  static let border = UIColor(rgb: 0x323232)
  static let divider = UIColor(rgb: 0x1F1F1F)
  static let success = UIColor(rgb: 0x22C55E)
  static let textPrimary = UIColor(rgb: 0xF4F4F5)
  static let textSecondary = UIColor(rgb: 0xD4D4D8)
  static let textMuted = UIColor(rgb: 0x9CA3AF)
  /// The React Native app's stack header follows the system theme with
  /// React Navigation's card colour: #121212 in dark mode, white in light
  /// mode.
  static let header = UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: 0x121212) : .white }
}

extension UIColor {
  convenience init(rgb: Int) {
    self.init(
      red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
      blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
  }
}

/// Loads each image once: images are decoded off the main thread and kept
/// in an in-memory cache, with one request per address however many cells
/// ask for it.
final class ImageLoader {
  static let shared = ImageLoader()
  private let cache = NSCache<NSURL, UIImage>()
  private var waiting: [URL: [(UIImage?) -> Void]] = [:]

  func load(_ url: URL, completion: @escaping (UIImage?) -> Void) {
    if let image = cache.object(forKey: url as NSURL) { completion(image); return }
    if waiting[url] != nil { waiting[url]!.append(completion); return }
    waiting[url] = [completion]
    URLSession.shared.dataTask(with: url) { data, _, _ in
      let image = data.flatMap(UIImage.init(data:))?.preparingForDisplay()
      DispatchQueue.main.async {
        if let image { self.cache.setObject(image, forKey: url as NSURL) }
        self.waiting.removeValue(forKey: url)?.forEach { $0(image) }
      }
    }.resume()
  }
}

/// The card's fonts and the line heights `UILabel` gives them: a label is
/// as tall as its font's line height rounded up to the device pixel.
enum CardFonts {
  static let author = UIFont.systemFont(ofSize: 16, weight: .semibold)
  static let timestamp = UIFont.systemFont(ofSize: 12)
  static let title = UIFont.boldSystemFont(ofSize: 18)
  static let body = UIFont.systemFont(ofSize: 14)
  static let small = UIFont.systemFont(ofSize: 14)
  static let scale = UIScreen.main.scale

  static func lineHeight(_ font: UIFont) -> CGFloat { ceil(font.lineHeight * scale) / scale }
  /// A width rounded up to the device pixel, as a label's own is.
  static func pixelCeil(_ v: CGFloat) -> CGFloat { ceil(v * scale) / scale }
  /// A position on the device pixel grid, where a stack view puts its
  /// arranged views.
  static func snap(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }

  /// The body's attributed text: 14 points on 20-point lines, as the
  /// example sets it; `expanded` doubles the text.
  static func body(_ text: String, expanded: Bool) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = 20
    paragraph.maximumLineHeight = 20
    return NSAttributedString(
      string: expanded ? text + text : text,
      attributes: [.font: body, .paragraphStyle: paragraph, .foregroundColor: Palette.textSecondary])
  }
}

/// Where everything in a card of a given width goes, and how tall the card
/// is: the example's layout (16 points of padding, the avatar and author
/// lines, the title, the text, the rail, a divider, the footer and the
/// PERF_TEST line, with the example's gaps), measured with the text's own
/// fonts rather than left to Auto Layout at the moment the cell appears.
/// It depends only on its inputs, so it can be made on any thread.
struct CardLayout {
  static let avatarSide: CGFloat = 40
  static let padding: CGFloat = 16

  let width: CGFloat
  let height: CGFloat
  let avatar: CGRect
  let author: CGRect
  let timestamp: CGRect
  let title: CGRect
  let body: CGRect
  let rail: CGRect
  let divider: CGRect
  let footer: [CGRect]
  let perf: CGRect

  static let footerTexts = ["❤️ 42", "💬 12", "🔄 8"]

  init(width: CGFloat, bodyText: NSAttributedString, advanced: Bool) {
    self.width = width
    let inner = width - 2 * Self.padding
    let x = Self.padding
    var y = Self.padding
    let authorHeight = CardFonts.lineHeight(CardFonts.author)
    let stampHeight = CardFonts.lineHeight(CardFonts.timestamp)
    let linesHeight = authorHeight + 2 + stampHeight
    let headHeight = max(Self.avatarSide, linesHeight)
    avatar = CGRect(x: x, y: CardFonts.snap(y + (headHeight - Self.avatarSide) / 2), width: Self.avatarSide, height: Self.avatarSide)
    let linesX = x + Self.avatarSide + 12
    let linesY = CardFonts.snap(y + (headHeight - linesHeight) / 2)
    author = CGRect(x: linesX, y: linesY, width: inner - Self.avatarSide - 12, height: authorHeight)
    timestamp = CGRect(x: linesX, y: linesY + authorHeight + 2, width: author.width, height: stampHeight)
    y += headHeight + 12
    title = CGRect(x: x, y: y, width: inner, height: CardFonts.lineHeight(CardFonts.title))
    y += title.height + 8
    let measured = bodyText.boundingRect(
      with: CGSize(width: inner, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin], context: nil)
    let bodyHeight = ceil(measured.height * CardFonts.scale) / CardFonts.scale
    body = CGRect(x: x, y: y, width: inner, height: bodyHeight)
    y += bodyHeight + 12
    if advanced {
      rail = CGRect(x: x, y: y, width: inner, height: RailView.side)
      y += RailView.side + 12
    } else {
      rail = .zero
    }
    divider = CGRect(x: x, y: y, width: inner, height: 1)
    y += 1 + 12
    let smallHeight = CardFonts.lineHeight(CardFonts.small)
    var fx = x
    footer = Self.footerTexts.map { text in
      let w = CardFonts.pixelCeil((text as NSString).size(withAttributes: [.font: CardFonts.small]).width)
      let r = CGRect(x: fx, y: y, width: w, height: smallHeight)
      fx += w + 16
      return r
    }
    y += smallHeight
    if advanced {
      y += 8
      perf = CGRect(x: x, y: y, width: inner, height: smallHeight)
      y += smallHeight
    } else {
      perf = .zero
    }
    height = y + Self.padding
  }
}

/// A card made ready to show: its layout measured and its per-card work
/// done. `CardPreparer` makes these ahead of the scroll.
struct PreparedCard {
  let layout: CardLayout
  let bodyText: NSAttributedString
  let perfText: String?
}

/// Prepares cards off the main thread, ahead of the rows the table is
/// about to show (`UITableViewDataSourcePrefetching`): it measures the text
/// for the layout, does the example's per-card work, and requests the
/// avatar and rail images. A row the scroll reaches before its card is
/// ready is prepared on the main thread at that moment, so no row is ever
/// shown empty. Prepared cards stay cached while they are near the rows on
/// screen. The labels draw the text itself when the row appears, as UIKit
/// draws text.
final class CardPreparer {
  private struct Key: Hashable {
    let index: Int
    let width: CGFloat
    let expanded: Bool
  }

  private let queue = DispatchQueue(label: "cards.prepare", qos: .userInitiated)
  private var ready: [Key: PreparedCard] = [:]
  private var inFlight = Set<Key>()
  private let advanced: Bool
  /// How many rows beyond the ones on screen a prepared card is kept, ahead
  /// and behind: about a screen of cards, roughly as far ahead as the table
  /// prefetches.
  private let keepWithin = 4

  init(advanced: Bool) { self.advanced = advanced }

  /// The card's height at this width, measured now when it has not been.
  func height(of index: Int, width: CGFloat, expanded: Bool) -> CGFloat {
    let key = Key(index: index, width: width, expanded: expanded)
    if let card = ready[key] { return card.layout.height }
    return Self.layout(for: CardFixture.cards[index], width: width, expanded: expanded, advanced: advanced).height
  }

  /// The card, prepared ahead or on the spot.
  func card(_ index: Int, width: CGFloat, expanded: Bool) -> PreparedCard {
    let key = Key(index: index, width: width, expanded: expanded)
    if let card = ready[key] { return card }
    let card = Self.make(CardFixture.cards[index], width: width, expanded: expanded, advanced: advanced)
    ready[key] = card
    return card
  }

  /// Starts preparing these rows on the background queue.
  func prefetch(_ indices: [Int], width: CGFloat, expanded: Set<Int>) {
    for index in indices {
      let key = Key(index: index, width: width, expanded: expanded.contains(index))
      if ready[key] != nil || inFlight.contains(key) { continue }
      inFlight.insert(key)
      let data = CardFixture.cards[index]
      if advanced {
        ImageLoader.shared.load(data.avatarURL) { _ in }
        data.railURLs.forEach { ImageLoader.shared.load($0) { _ in } }
      }
      queue.async { [advanced] in
        let card = Self.make(data, width: width, expanded: key.expanded, advanced: advanced)
        DispatchQueue.main.async {
          self.inFlight.remove(key)
          self.ready[key] = card
        }
      }
    }
  }

  /// Drops a card's old preparation when its state changes on screen, as
  /// when a tap expands it.
  func forget(_ index: Int) {
    for key in ready.keys where key.index == index { ready.removeValue(forKey: key) }
  }

  /// Drops the prepared cards far from the rows on screen, `first` to
  /// `last`.
  func trim(visible first: Int, _ last: Int) {
    for key in ready.keys where key.index < first - keepWithin || key.index > last + keepWithin {
      ready.removeValue(forKey: key)
    }
  }

  private static func layout(for data: CardData, width: CGFloat, expanded: Bool, advanced: Bool) -> CardLayout {
    let text = CardFonts.body(advanced ? data.longBody : data.body, expanded: expanded)
    return CardLayout(width: width, bodyText: text, advanced: advanced)
  }

  private static func make(_ data: CardData, width: CGFloat, expanded: Bool, advanced: Bool) -> PreparedCard {
    let text = CardFonts.body(advanced ? data.longBody : data.body, expanded: expanded)
    let layout = CardLayout(width: width, bodyText: text, advanced: advanced)
    var perfText: String?
    if advanced {
      let (prime, fib) = data.perfTest()
      perfText = "🧮 Prime: \(prime ? "✓" : "✗") | Fib: \(fib)"
    }
    return PreparedCard(layout: layout, bodyText: text, perfText: perfText)
  }
}

/// One card: the example's layout, colours and interactions. An avatar, the
/// author line, a title, one to twelve sentences, a footer; a tap expands
/// the text; a swipe to the left reveals an 80-point "Complete" action
/// behind the card, which settles open past half the action's width and
/// closed otherwise, as the example's `Swipeable` does. Everything is
/// placed by frames from a `CardLayout`.
final class CardView: UIView {
  var onTap: (() -> Void)?

  private let action = UIView()
  private let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
  private let complete = UILabel()
  private let card = UIView()
  private let avatar = UIImageView()
  private let author = UILabel()
  private let timestamp = UILabel()
  private let title = UILabel()
  private let body = UILabel()
  /// Advanced mode: the rail of images under the text, hidden otherwise.
  private let rail = RailView()
  private let divider = UIView()
  private let footer: [UILabel]
  /// Advanced mode: the result line of the example's PERF_TEST work.
  private let perf = UILabel()
  private let sidewaysOnly = SidewaysPanGate()
  private var loadedURL: URL?
  private var layout: CardLayout?
  /// How far the card is slid to the left, revealing the action.
  private var slide: CGFloat = 0
  private static let actionWidth: CGFloat = 80

  override init(frame: CGRect) {
    footer = CardLayout.footerTexts.map { text in
      let l = UILabel()
      l.text = text
      l.font = CardFonts.small
      l.textColor = Palette.textMuted
      return l
    }
    super.init(frame: frame)
    backgroundColor = Palette.success
    layer.cornerRadius = 12

    // The action behind the card.
    check.tintColor = .white
    check.contentMode = .scaleAspectFit
    complete.text = "Complete"
    complete.textColor = .white
    complete.font = .systemFont(ofSize: 12, weight: .semibold)
    complete.textAlignment = .center
    action.addSubview(check)
    action.addSubview(complete)
    addSubview(action)

    card.backgroundColor = Palette.cardBackground
    card.layer.cornerRadius = 12
    // The example's border is two hairlines: two device pixels.
    card.layer.borderWidth = 2 / UIScreen.main.scale
    card.layer.borderColor = Palette.border.cgColor
    addSubview(card)

    avatar.layer.cornerRadius = 20
    avatar.clipsToBounds = true
    avatar.contentMode = .scaleAspectFill
    author.font = CardFonts.author
    author.textColor = Palette.textPrimary
    timestamp.font = CardFonts.timestamp
    timestamp.textColor = Palette.textMuted
    title.font = CardFonts.title
    title.textColor = Palette.textPrimary
    body.numberOfLines = 0
    divider.backgroundColor = Palette.divider
    rail.isHidden = true
    perf.isHidden = true
    perf.font = CardFonts.small
    perf.textColor = Palette.textMuted
    for v in [avatar, author, timestamp, title, body, rail, divider, perf] + footer { card.addSubview(v) }

    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    card.addGestureRecognizer(tap)
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    pan.delegate = sidewaysOnly
    addGestureRecognizer(pan)
  }

  required init?(coder: NSCoder) { fatalError() }

  func show(_ data: CardData, prepared: PreparedCard, advanced: Bool = false) {
    layout = prepared.layout
    author.text = data.authorName
    timestamp.text = data.timestamp
    title.text = data.title
    body.attributedText = prepared.bodyText
    rail.isHidden = !advanced
    perf.isHidden = !advanced
    if advanced {
      rail.show(data.railURLs)
      perf.text = prepared.perfText
    }
    slide = 0
    loadedURL = data.avatarURL
    avatar.image = nil
    ImageLoader.shared.load(data.avatarURL) { [weak self] image in
      guard let self, self.loadedURL == data.avatarURL else { return }
      self.avatar.image = image
    }
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let w = bounds.width, h = bounds.height
    action.frame = CGRect(x: w - Self.actionWidth, y: 0, width: Self.actionWidth, height: h)
    // The check over its label, 4 points apart, centred in the action.
    let labelHeight = CardFonts.lineHeight(complete.font)
    let top = (h - 24 - 4 - labelHeight) / 2
    check.frame = CGRect(x: (Self.actionWidth - 24) / 2, y: top, width: 24, height: 24)
    complete.frame = CGRect(x: 0, y: top + 28, width: Self.actionWidth, height: labelHeight)
    card.frame = CGRect(x: slide, y: 0, width: w, height: h)
    guard let l = layout else { return }
    avatar.frame = l.avatar
    author.frame = l.author
    timestamp.frame = l.timestamp
    title.frame = l.title
    body.frame = l.body
    rail.frame = l.rail
    divider.frame = l.divider
    for (label, frame) in zip(footer, l.footer) { label.frame = frame }
    perf.frame = l.perf
  }

  @objc private func tapped() { onTap?() }

  @objc private func panned(_ pan: UIPanGestureRecognizer) {
    switch pan.state {
    case .changed:
      slide = min(0, slide + pan.translation(in: self).x)
      pan.setTranslation(.zero, in: self)
      card.frame.origin.x = slide
    case .ended, .cancelled:
      slide = slide < -Self.actionWidth / 2 ? -Self.actionWidth : 0
      UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) { self.card.frame.origin.x = self.slide }
    default: break
    }
  }
}

/// The card's pan begins only on a sideways drag, which reveals the action;
/// a vertical drag is left to the list, so it scrolls from anywhere on a
/// card.
final class SidewaysPanGate: NSObject, UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let v = pan.velocity(in: pan.view)
    return abs(v.x) > abs(v.y)
  }
}

/// The 100 × 100 box the example puts at the top of the list.
final class HeaderBoxView: UIView {
  static let height: CGFloat = 116
  private let box = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    box.backgroundColor = Palette.headerBox
    box.layer.cornerRadius = 12
    addSubview(box)
  }
  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    box.frame = CGRect(x: (bounds.width - 100) / 2, y: 8, width: 100, height: 100)
  }
}

/// Advanced mode's rail: ten square images in a horizontal collection
/// view, 80 points a side with 8 between, scrolling on its own inside the
/// card.
final class RailView: UIView, UICollectionViewDataSource {
  static let side: CGFloat = 80
  static let gap: CGFloat = 8
  private let collection: UICollectionView
  private var urls: [URL] = []

  override init(frame: CGRect) {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = CGSize(width: Self.side, height: Self.side)
    layout.minimumLineSpacing = Self.gap
    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(frame: frame)
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    collection.register(RailCell.self, forCellWithReuseIdentifier: "image")
    collection.dataSource = self
    collection.frame = bounds
    collection.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(collection)
  }
  required init?(coder: NSCoder) { fatalError() }

  func show(_ urls: [URL]) {
    self.urls = urls
    collection.reloadData()
    collection.contentOffset = .zero
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { urls.count }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! RailCell
    cell.show(urls[indexPath.item])
    return cell
  }
}

final class RailCell: UICollectionViewCell {
  private let image = UIImageView()
  private var loadedURL: URL?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = Palette.divider
    contentView.layer.cornerRadius = 8
    contentView.clipsToBounds = true
    image.contentMode = .scaleAspectFill
    image.frame = contentView.bounds
    image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(image)
  }
  required init?(coder: NSCoder) { fatalError() }

  func show(_ url: URL) {
    loadedURL = url
    image.image = nil
    ImageLoader.shared.load(url) { [weak self] img in
      guard let self, self.loadedURL == url else { return }
      self.image.image = img
    }
  }
}

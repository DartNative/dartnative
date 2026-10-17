import Lottie
import UIKit

/// The Chat screen in UIKit: Legend List's chat example (ChatExample.tsx),
/// with its messages, bubbles and attachment cards, plus two kinds of
/// message added. After every fourth message comes a photo with a bubble's
/// rounded corners and no padding, at one of five aspect ratios; after
/// every third, a sticker, a looping Lottie animation (lottie-ios, the
/// library React Native's lottie-react-native uses) shown without a
/// bubble. Both sit on the sender's side.
/// The messages are the ones the example's own generator makes
/// (`tool/extract_chat.sh` writes them to `assets/chat.json`); the stickers
/// are six from each of four packs of the DartNative playground's sticker
/// keyboard. The table is turned upside down, newest message first, the
/// usual way of opening a UIKit chat at its newest message.
struct ChatAttachment: Decodable {
  let accent: String
  let height: CGFloat
  let label: String
  let subtitle: String
}

struct ChatMessage: Decodable {
  let sender: String
  let senderName: String
  let text: String
  let timestampLabel: String
  let attachment: ChatAttachment?
}

/// One item of the thread: a message, a sticker or a photo.
enum ChatItem {
  case message(ChatMessage)
  case sticker(name: String, mine: Bool)
  case photo(url: URL, height: CGFloat, mine: Bool)
}

enum Chat {
  /// A sticker follows every this many messages, as on the React Native
  /// screen (STICKER_EVERY).
  static let stickerEvery = 3

  /// A sticker's side, as a messaging app shows one.
  static let stickerSide: CGFloat = 160

  /// A photo follows every this many messages (PHOTO_EVERY), 240 points
  /// wide; its height follows its shape.
  static let photoEvery = 4
  static let photoWidth: CGFloat = 240

  /// The photos' shapes, in turn: the pixel size asked of the image service
  /// (720 wide, three pixels a point) and the height shown, in points: 4:3,
  /// 3:4, 1:1, 16:9 and 9:16.
  static let photoShapes: [(Int, Int, CGFloat)] = [
    (720, 540, 180), (720, 960, 320), (720, 720, 240), (720, 405, 135), (720, 1280, 427),
  ]

  /// The photos: 24 images from picsum.photos, picked by id, the same in
  /// every app.
  static let firstPhotoId = 10
  static let photoCount = 24

  /// The light fill a chat shows while a photo loads.
  static let photoFill = UIColor(rgb: 0xE5E7EB)

  // The example's chat palette (screens/examples/shared.tsx).
  static let background = UIColor(rgb: 0xF6F3EE)
  static let selfBubble = UIColor(rgb: 0xDBEAFE)
  static let otherBubble = UIColor(rgb: 0xFFFFFF)
  static let text = UIColor(rgb: 0x111827)
  static let timestamp = UIColor(rgb: 0x64748B)
  static let scrim = UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 0.14)

  /// The sticker files: six from each of four packs, the same in every app.
  static let stickers: [String] = ["duck", "mia_bunny", "hot_cherry", "baby_yoda"]
    .flatMap { pack in (0..<6).map { "\(pack)_\($0)" } }

  /// The thread, newest first: the example's messages, with a photo after
  /// the second of every four and a sticker after the third of every three,
  /// each from the sender of the message before it. The sticker is picked
  /// by a small generator with a fixed seed, the same in every app, so a
  /// sticker file never repeats at a fixed distance: a list reuses its views
  /// in turn, and a file that came back to the view still holding it would
  /// be shown without being built again.
  static let newestFirst: [ChatItem] = {
    guard let url = Bundle.main.url(forResource: "chat", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return [] }
    var thread: [ChatItem] = []
    var stickerSeed = 2026
    for (i, message) in messages.enumerated() {
      thread.append(.message(message))
      if i % photoEvery == 1 {
        let n = i / photoEvery
        let (w, h, height) = photoShapes[n % photoShapes.count]
        let url = URL(string: "https://picsum.photos/id/\(firstPhotoId + n % photoCount)/\(w)/\(h)")!
        thread.append(.photo(url: url, height: height, mine: message.sender == "self"))
      }
      if i % stickerEvery == stickerEvery - 1 {
        stickerSeed = stickerSeed * 48271 % 2147483647
        thread.append(.sticker(name: stickers[stickerSeed % stickers.count], mine: message.sender == "self"))
      }
    }
    return thread.reversed()
  }()

  /// Loads a sticker from the app's bundle, parsing each file only once.
  static func animation(_ name: String) -> LottieAnimation? {
    guard let path = Bundle.main.path(forResource: name, ofType: "json", inDirectory: "stickers") else { return nil }
    return LottieAnimation.filepath(path, animationCache: DefaultAnimationCache.sharedCache)
  }
}

private let upsideDown = CGAffineTransform(scaleX: 1, y: -1)

final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDataSourcePrefetching {
  private let table = UITableView(frame: .zero, style: .plain)
  private let stickers = StickerPreparer()
  private var nextTarget = 0

  /// The messages the bar's Scroll button goes to, in turn, the same in
  /// every app, by number (0 is the oldest, 999 the newest). Each press
  /// scrolls, animated, until that message's top is at the top of the list.
  /// The first, to a message a few rows from the newest one where the
  /// thread opens, lands among rows every list has measured, so it shows
  /// where a message's top sits when it is at the top. Every scroll goes up
  /// the history, away from where the thread opens: the one to message 598
  /// moves two messages, the others hundreds, past messages no list has
  /// measured, the oldest last.
  static let scrollTargets = [996, 600, 598, 300, 0]

  /// Each message's row in the newest-first table, by its number.
  private lazy var messageRows: [Int] = Chat.newestFirst.indices.filter {
    if case .message = Chat.newestFirst[$0] { return true } else { return false }
  }.reversed()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chat (Swift)"
    let scrollItem = UIBarButtonItem(
      image: UIImage(systemName: "arrow.up"), style: .plain, target: self, action: #selector(scrollToNext))
    scrollItem.accessibilityLabel = "Scroll"
    navigationItem.rightBarButtonItem = scrollItem
    view.backgroundColor = Chat.background
    table.backgroundColor = Chat.background
    table.separatorStyle = .none
    table.estimatedRowHeight = 168
    table.rowHeight = UITableView.automaticDimension
    table.transform = upsideDown
    // The example's 16 points above and below the thread; the table sits
    // inside the safe area, as the example keeps the thread above the home
    // indicator.
    table.contentInsetAdjustmentBehavior = .never
    table.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    table.register(MessageCell.self, forCellReuseIdentifier: "message")
    table.register(StickerCell.self, forCellReuseIdentifier: "sticker")
    table.register(PhotoCell.self, forCellReuseIdentifier: "photo")
    table.dataSource = self
    table.prefetchDataSource = self
    table.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(table)
    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  /// Brings the next message of `scrollTargets` to the top with the table's
  /// own animated `scrollToRow`. The table is upside down, so the screen's
  /// top is its bottom.
  @objc private func scrollToNext() {
    let message = Self.scrollTargets[nextTarget % Self.scrollTargets.count]
    nextTarget += 1
    table.scrollToRow(at: IndexPath(row: messageRows[message], section: 0), at: .bottom, animated: true)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Chat.newestFirst.count }

  /// The rows the table expects to show next: their stickers are built
  /// now, ahead of the frame that shows the row.
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      if case .sticker(let name, _) = Chat.newestFirst[indexPath.row] {
        stickers.prepare(row: indexPath.row, name: name)
      }
    }
  }

  func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths { stickers.drop(row: indexPath.row) }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch Chat.newestFirst[indexPath.row] {
    case .message(let message):
      let cell = tableView.dequeueReusableCell(withIdentifier: "message", for: indexPath) as! MessageCell
      cell.show(message)
      return cell
    case .sticker(let name, let mine):
      let cell = tableView.dequeueReusableCell(withIdentifier: "sticker", for: indexPath) as! StickerCell
      cell.show(stickers.take(row: indexPath.row, name: name), mine: mine)
      return cell
    case .photo(let url, let height, let mine):
      let cell = tableView.dequeueReusableCell(withIdentifier: "photo", for: indexPath) as! PhotoCell
      cell.show(url, height: height, mine: mine)
      return cell
    }
  }
}

/// Builds sticker views ahead of their rows, when the table names the rows
/// it expects to show next (`prefetchRowsAt`), the way the other apps'
/// lists build their rows ahead of the screen. lottie-ios builds a view's
/// animations when its root layer is first displayed, so a view built here
/// is also displayed at once, and the cell that takes it has nothing left
/// to build. A row the table did not name gets its view when its cell is
/// made.
final class StickerPreparer {
  private var ready: [Int: LottieAnimationView] = [:]

  func prepare(row: Int, name: String) {
    guard ready[row] == nil else { return }
    ready[row] = Self.makeView(name)
  }

  func take(row: Int, name: String) -> LottieAnimationView {
    ready.removeValue(forKey: row) ?? Self.makeView(name)
  }

  func drop(row: Int) {
    ready[row] = nil
  }

  /// Makes a playing view at the size the cell shows it, so the cell's
  /// layout changes nothing. The view keeps playing while it is not in a
  /// window, so adding it to the cell rebuilds nothing either.
  static func makeView(_ name: String) -> LottieAnimationView {
    let view = LottieAnimationView(frame: CGRect(x: 0, y: 0, width: Chat.stickerSide, height: Chat.stickerSide))
    view.contentMode = .scaleAspectFit
    view.loopMode = .loop
    view.backgroundBehavior = .continuePlaying
    view.animation = Chat.animation(name)
    view.play()
    displayPending(view.layer, depth: 0)
    return view
  }

  /// The root animation layer is two layers under the view's; the one
  /// marked for display is the root, and displaying it builds the animations.
  private static func displayPending(_ layer: CALayer, depth: Int) {
    for sub in layer.sublayers ?? [] {
      if sub.needsDisplay() {
        sub.displayIfNeeded()
      } else if depth < 2 {
        displayPending(sub, depth: depth + 1)
      }
    }
  }
}

/// A sticker: 160 points square, without a bubble, on the sender's side,
/// with 12 points of space below. The cell holds a box of that size and
/// shows in it the view it is handed.
final class StickerCell: UITableViewCell {
  private let box = UIView()
  private var mineSide: NSLayoutConstraint!
  private var otherSide: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.transform = upsideDown
    box.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(box)
    mineSide = box.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    otherSide = box.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    let height = box.heightAnchor.constraint(equalToConstant: Chat.stickerSide)
    height.priority = .defaultHigh
    NSLayoutConstraint.activate([
      box.topAnchor.constraint(equalTo: contentView.topAnchor),
      box.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      box.widthAnchor.constraint(equalToConstant: Chat.stickerSide),
      height,
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  func show(_ sticker: LottieAnimationView, mine: Bool) {
    mineSide.isActive = mine
    otherSide.isActive = !mine
    box.subviews.forEach { $0.removeFromSuperview() }
    sticker.frame = CGRect(x: 0, y: 0, width: Chat.stickerSide, height: Chat.stickerSide)
    box.addSubview(sticker)
  }
}

/// A photo with a bubble's rounded corners and no padding, with 12 points
/// of space below.
final class PhotoCell: UITableViewCell {
  private let photo = UIImageView()
  private var url: URL?
  private var height: NSLayoutConstraint!
  private var mineSide: NSLayoutConstraint!
  private var otherSide: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.transform = upsideDown
    photo.backgroundColor = Chat.photoFill
    photo.contentMode = .scaleAspectFill
    photo.layer.cornerRadius = 18
    photo.clipsToBounds = true
    photo.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(photo)
    mineSide = photo.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    otherSide = photo.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    height = photo.heightAnchor.constraint(equalToConstant: 0)
    height.priority = .defaultHigh
    NSLayoutConstraint.activate([
      photo.topAnchor.constraint(equalTo: contentView.topAnchor),
      photo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      photo.widthAnchor.constraint(equalToConstant: Chat.photoWidth),
      height,
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  func show(_ url: URL, height: CGFloat, mine: Bool) {
    mineSide.isActive = mine
    otherSide.isActive = !mine
    self.height.constant = height
    self.url = url
    photo.image = nil
    ImageLoader.shared.load(url) { [weak self] image in
      guard let self, self.url == url else { return }
      self.photo.image = image
    }
  }
}

/// The example's bubble: the sender's name, the attachment card if any,
/// the text and the time, at most 84 % of the thread's width. A bubble
/// with an attachment card takes all of that width, the card filling it.
final class MessageCell: UITableViewCell {
  private let bubble = UIView()
  private let stack = UIStackView()
  private let sender = UILabel()
  private let attachment = UIView()
  private let scrim = UIView()
  private let label = UILabel()
  private let subtitle = UILabel()
  private let body = UILabel()
  private let time = UILabel()
  private var attachmentHeight: NSLayoutConstraint!
  private var full: NSLayoutConstraint!
  private var mineSide: NSLayoutConstraint!
  private var otherSide: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.transform = upsideDown
    bubble.layer.cornerRadius = 18
    bubble.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(bubble)

    sender.font = .systemFont(ofSize: 12, weight: .bold)
    sender.textColor = Chat.text
    body.numberOfLines = 0
    time.font = .systemFont(ofSize: 12)
    time.textColor = Chat.timestamp

    attachment.layer.cornerRadius = 16
    attachment.clipsToBounds = true
    scrim.backgroundColor = Chat.scrim
    scrim.translatesAutoresizingMaskIntoConstraints = false
    attachment.addSubview(scrim)
    label.font = .systemFont(ofSize: 12, weight: .heavy)
    label.textColor = .white
    subtitle.font = .systemFont(ofSize: 20, weight: .heavy)
    subtitle.textColor = .white
    let labels = UIStackView(arrangedSubviews: [label, subtitle])
    labels.axis = .vertical
    labels.alignment = .leading
    labels.spacing = 6
    labels.translatesAutoresizingMaskIntoConstraints = false
    attachment.addSubview(labels)
    attachmentHeight = attachment.heightAnchor.constraint(equalToConstant: 0)

    stack.axis = .vertical
    stack.alignment = .leading
    stack.translatesAutoresizingMaskIntoConstraints = false
    for view in [sender, attachment, body, time] { stack.addArrangedSubview(view) }
    stack.setCustomSpacing(4, after: sender)
    stack.setCustomSpacing(10, after: attachment)
    stack.setCustomSpacing(8, after: body)
    bubble.addSubview(stack)

    full = bubble.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.84, constant: -32 * 0.84)
    mineSide = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    otherSide = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    NSLayoutConstraint.activate([
      bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
      bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.84, constant: -32 * 0.84),
      stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 14),
      stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -14),
      stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
      stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
      attachment.widthAnchor.constraint(equalTo: stack.widthAnchor),
      attachmentHeight,
      scrim.topAnchor.constraint(equalTo: attachment.topAnchor),
      scrim.bottomAnchor.constraint(equalTo: attachment.bottomAnchor),
      scrim.leadingAnchor.constraint(equalTo: attachment.leadingAnchor),
      scrim.trailingAnchor.constraint(equalTo: attachment.trailingAnchor),
      labels.leadingAnchor.constraint(equalTo: attachment.leadingAnchor, constant: 12),
      labels.trailingAnchor.constraint(lessThanOrEqualTo: attachment.trailingAnchor, constant: -12),
      labels.bottomAnchor.constraint(equalTo: attachment.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  func show(_ message: ChatMessage) {
    let mine = message.sender == "self"
    mineSide.isActive = mine
    otherSide.isActive = !mine
    bubble.backgroundColor = mine ? Chat.selfBubble : Chat.otherBubble
    sender.text = message.senderName
    full.isActive = message.attachment != nil
    if let a = message.attachment {
      attachment.isHidden = false
      attachment.backgroundColor = UIColor(rgb: Int(a.accent.dropFirst(), radix: 16) ?? 0)
      attachmentHeight.constant = a.height
      label.attributedText = NSAttributedString(string: a.label.uppercased(), attributes: [.kern: 0.5])
      subtitle.text = a.subtitle
    } else {
      attachment.isHidden = true
    }
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = 20
    paragraph.maximumLineHeight = 20
    body.attributedText = NSAttributedString(string: message.text, attributes: [
      .font: UIFont.systemFont(ofSize: 14), .foregroundColor: Chat.text, .paragraphStyle: paragraph,
    ])
    time.text = message.timestampLabel
  }
}

import UIKit

/// One card per row: a `UITableView` with 1,000 rows and the header box,
/// the example's "Cards" screen in the benchmark's advanced mode
/// (`CardView` keeps the example's plain card for `advanced: false`). The
/// rows' heights come from `CardPreparer`, which measures and prepares the
/// cards ahead of the scroll on a background queue as the table asks for
/// rows it is about to show (`UITableViewDataSourcePrefetching`); the cell
/// places its views by frames. The bar's Scroll button brings the next card
/// of `scrollTargets` to the top with the table's own animated
/// `scrollToRow`.
final class CardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
  UITableViewDataSourcePrefetching
{
  private let table = UITableView(frame: .zero, style: .plain)
  private var expanded = Set<Int>()
  private let advanced = true
  private lazy var preparer = CardPreparer(advanced: advanced)
  private var nextTarget = 0
  private lazy var scrollItem = barItem("arrow.down", "Scroll", #selector(scrollToNext))

  private func barItem(_ symbol: String, _ label: String, _ action: Selector) -> UIBarButtonItem {
    let item = UIBarButtonItem(image: UIImage(systemName: symbol), style: .plain, target: self, action: action)
    item.accessibilityLabel = label
    item.tintColor = .label
    return item
  }

  /// The cards the Scroll button goes to, in turn, the same in every app.
  /// Each press scrolls, animated, until that card's top is at the top of
  /// the list. The list opens at its first card and every scroll goes
  /// down it, away from there. Two are short: the first, to card 1, lands
  /// among cards every list has measured, so it shows where a card's title
  /// sits when the card is at the top, and the one to card 402 moves two
  /// cards. The others go far, hundreds of cards, past cards no list has
  /// measured.
  static let scrollTargets = [1, 400, 402, 700, 950]

  /// A card's width: the row less the 12 points of padding on each side.
  private var cardWidth: CGFloat { table.bounds.width - 24 }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cards (Swift)"
    navigationItem.rightBarButtonItem = scrollItem
    view.backgroundColor = Palette.screenBackground
    table.backgroundColor = Palette.screenBackground
    table.separatorStyle = .none
    // Rows not yet measured count as 400 points in the content size; a
    // row's own height is exact the moment the table asks for it.
    table.estimatedRowHeight = 400
    table.register(CardCell.self, forCellReuseIdentifier: "card")
    table.register(HeaderCell.self, forCellReuseIdentifier: "header")
    table.dataSource = self
    table.delegate = self
    table.prefetchDataSource = self
    table.frame = view.bounds
    table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(table)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    CardFixture.count + 1
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row == 0 { return HeaderBoxView.height }
    let index = indexPath.row - 1
    return preparer.height(of: index, width: cardWidth, expanded: expanded.contains(index)) + 24
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row == 0 {
      return tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath)
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "card", for: indexPath) as! CardCell
    let index = indexPath.row - 1
    show(index, in: cell)
    cell.card.onTap = { [weak self, weak tableView] in
      guard let self, let tableView else { return }
      if !self.expanded.insert(index).inserted { self.expanded.remove(index) }
      self.preparer.forget(index)
      self.show(index, in: cell)
      tableView.performBatchUpdates(nil)
    }
    return cell
  }

  private func show(_ index: Int, in cell: CardCell) {
    let prepared = preparer.card(index, width: cardWidth, expanded: expanded.contains(index))
    cell.card.show(CardFixture.cards[index], prepared: prepared, advanced: advanced)
  }

  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    preparer.prefetch(indexPaths.map(\.row).filter { $0 > 0 }.map { $0 - 1 }, width: cardWidth, expanded: expanded)
  }

  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let rows = tableView.indexPathsForVisibleRows, let first = rows.first, let last = rows.last else { return }
    preparer.trim(visible: first.row - 1, last.row - 1)
  }

  /// The table's first row is the header box, so card n is row n + 1.
  @objc private func scrollToNext() {
    let card = Self.scrollTargets[nextTarget % Self.scrollTargets.count]
    nextTarget += 1
    table.scrollToRow(at: IndexPath(row: card + 1, section: 0), at: .top, animated: true)
  }
}

/// A row: the example's outer container, 12 points of padding on a
/// near-black background, around the card.
final class CardCell: UITableViewCell {
  let card = CardView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = Palette.outerBackground
    contentView.backgroundColor = Palette.outerBackground
    contentView.addSubview(card)
  }
  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    card.frame = contentView.bounds.insetBy(dx: 12, dy: 12)
  }
}

final class HeaderCell: UITableViewCell {
  private let box = HeaderBoxView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.addSubview(box)
  }
  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    box.frame = contentView.bounds
  }
}

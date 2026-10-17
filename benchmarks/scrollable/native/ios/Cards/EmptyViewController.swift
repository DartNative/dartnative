import UIKit

/// Nothing to scroll: the bar and one line of text, the same in every app.
/// Its memory is what the app costs before any list, the floor every other
/// screen's number sits on.
final class EmptyViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Empty (Swift)"
    view.backgroundColor = Palette.screenBackground
    let label = UILabel()
    label.text = "Nothing to scroll"
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

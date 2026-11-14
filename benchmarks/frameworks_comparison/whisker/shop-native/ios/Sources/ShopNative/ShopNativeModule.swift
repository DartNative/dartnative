import Foundation
import UIKit
import WhiskerModule

@WhiskerModule
public final class ShopNativeModule: Module {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    public override func definition() -> ModuleDefinition {
        ModuleDefinition {
            Name("ShopNative")

            // post(url, body) -> response body (2xx) or error.
            AsyncFunction("post") { (args: [WhiskerValue], promise: WhiskerPromise) in
                guard let urlString = args.first?.asString, let url = URL(string: urlString) else {
                    promise.reject("invalid url")
                    return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = (args.count > 1 ? args[1].asString ?? "" : "").data(using: .utf8)
                ShopNativeModule.session.dataTask(with: request) { data, response, error in
                    let result: WhiskerValue
                    if let error = error {
                        result = .error(error.localizedDescription)
                    } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        result = .error("HTTP \(http.statusCode)")
                    } else {
                        result = .string(data.flatMap { String(data: $0, encoding: .utf8) } ?? "")
                    }
                    DispatchQueue.main.async {
                        if case .error(let message) = result {
                            promise.reject(message)
                        } else {
                            promise.resolve(result)
                        }
                    }
                }.resume()
            }

            AsyncFunction("sleep") { (args: [WhiskerValue], promise: WhiskerPromise) in
                let ms = args.first?.asInt ?? 0
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(ms))) {
                    promise.resolve(.null)
                }
            }

            Function("alert") { (args: [WhiskerValue]) -> WhiskerValue in
                let message = args.first?.asString ?? ""
                DispatchQueue.main.async {
                    guard var top = ShopNativeModule.keyWindow()?.rootViewController else { return }
                    while let presented = top.presentedViewController { top = presented }
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    top.present(alert, animated: true)
                }
                return .null
            }

            // Sets the automation identifier on the app's native text field.
            Function("tagTextField") { (args: [WhiskerValue]) -> WhiskerValue in
                let identifier = args.first?.asString ?? ""
                guard let window = ShopNativeModule.keyWindow(),
                      let field = ShopNativeModule.firstTextField(in: window) else { return .bool(false) }
                field.accessibilityIdentifier = identifier
                return .bool(true)
            }

            Function("log") { (args: [WhiskerValue]) -> WhiskerValue in
                NSLog("%@", args.first?.asString ?? "")
                return .null
            }
        }
    }

    private static func firstTextField(in view: UIView) -> UITextField? {
        if let field = view as? UITextField { return field }
        for sub in view.subviews {
            if let found = firstTextField(in: sub) { return found }
        }
        return nil
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

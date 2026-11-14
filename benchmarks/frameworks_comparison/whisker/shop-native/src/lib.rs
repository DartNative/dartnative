//! App-private platform services for Everbloom.
//!
//! - [`post_json`]: HTTP POST through the platform stack (URLSession on iOS,
//!   HttpURLConnection on Android).
//! - [`log_line`]: one line to the iOS unified log (`NSLog`) / Android logcat.

pub mod plugin;

use whisker::platform_module::WhiskerValue;

/// POSTs `body` as `application/json` to `url` and returns the response body
/// for a 2xx status, or an error message otherwise.
pub async fn post_json(url: &str, body: String) -> Result<String, String> {
    let result = whisker::module!("ShopNative")
        .invoke_async(
            "post",
            vec![
                WhiskerValue::String(url.to_string()),
                WhiskerValue::String(body),
            ],
        )
        .await;
    match result {
        WhiskerValue::String(s) => Ok(s),
        WhiskerValue::Error(e) => Err(e),
        other => Err(format!("unexpected response: {other:?}")),
    }
}

/// Writes one line to the platform system log.
pub fn log_line(message: &str) {
    let _ = whisker::module!("ShopNative")
        .invoke("log", vec![WhiskerValue::String(message.to_string())]);
}

/// Resolves after `ms` milliseconds on the platform main loop.
pub async fn sleep_ms(ms: u64) {
    let _ = whisker::module!("ShopNative")
        .invoke_async("sleep", vec![WhiskerValue::Int(ms as i64)])
        .await;
}

/// Shows a native alert with one OK button.
pub fn alert(message: &str) {
    let _ = whisker::module!("ShopNative")
        .invoke("alert", vec![WhiskerValue::String(message.to_string())]);
}

/// iOS: sets `identifier` as the accessibility identifier of the app's
/// native text field. Returns false when no text field is mounted yet.
pub fn tag_text_field(identifier: &str) -> bool {
    matches!(
        whisker::module!("ShopNative").invoke(
            "tagTextField",
            vec![WhiskerValue::String(identifier.to_string())]
        ),
        WhiskerValue::Bool(true)
    )
}

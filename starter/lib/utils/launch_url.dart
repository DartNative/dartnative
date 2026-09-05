import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';

/// Opens [url] in the system browser.
///
/// The scheme is added when missing, because a bare "example.com" is not a
/// URL the OS can open. [canLaunch] is checked first so a device with no
/// browser logs instead of throwing.
///
/// Production apps grow this: routing known domains to their native app,
/// or opening some links in an in-app web view. Keep that logic here, in
/// one place, rather than at each call site.
Future<void> openUrl(String url) async {
  var target = url;
  if (!target.startsWith('http://') && !target.startsWith('https://')) {
    target = 'https://$target';
  }
  try {
    if (DartNativeUrlLauncher.canLaunch(target)) {
      await DartNativeUrlLauncher.launch(target);
    } else {
      dnLog('openUrl: nothing can open $target');
    }
  } catch (e) {
    dnLog('openUrl: failed to open $target: $e');
  }
}

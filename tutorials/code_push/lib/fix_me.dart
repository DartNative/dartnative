// The four things this app shipped wrong, each as a small function.
//
// This is the only file you edit in the tutorial. Every function here
// returns a plain value that the screen (checkout_screen.dart) reads while it
// draws. A fix swaps the code of a function, so when you correct one of these
// and run `dn patch`, phones that already have the app start getting the
// corrected value from this same call, everywhere it is made, the next time
// the app starts.
//
// Why plain values and not widgets: today a fix may build only a handful of
// framework widgets (Text, Column, Row, SizedBox, Padding, Center, Container,
// EdgeInsets.all and Color), and it may not create an instance of any class
// declared in the file it changes. Keeping the changed file to numbers, text
// and true/false keeps every fix inside those rules. The screen turns the
// values into widgets, and the screen never changes.
//
// Two things to keep in mind while you fix:
//   * Change what the functions return. Do not change their names or types,
//     and do not add a class or an enum to this file: such a fix is refused
//     when it is built.
//   * Keep the fix to these four functions. A brand-new function added here
//     shows up in the iPhone's launch report as "not found" (the installed
//     app has no function by that name); the fix still applies.

/// The total for something that costs [cents], with 8% tax added.
///
/// Shipped wrong: it forgets the tax, so 100 comes back as 100.
/// The fix:
///   return cents + (cents * 8) ~/ 100;
int priceWithTax(int cents) {
  return cents;
}

/// The title at the top of the screen.
///
/// Shipped wrong: a typo.
/// The fix:
///   return 'Checkout';
String screenTitle() {
  return 'Chekout';
}

/// How large the total is drawn, in points.
///
/// Shipped wrong: far too small to read.
/// The fix:
///   return 40;
double totalFontSize() {
  return 12;
}

/// Which icon sits next to the word "Paid": 'check' or 'cart'.
///
/// Shipped wrong: a shopping cart, as if the order were still open. The
/// screen turns this word into an icon (iconNamed in checkout_screen.dart),
/// because a fix may not build an Icon itself.
/// The fix:
///   return 'check';
String paidIcon() {
  return 'cart';
}

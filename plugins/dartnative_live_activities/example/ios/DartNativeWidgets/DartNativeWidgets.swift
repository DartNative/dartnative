// Written by DartNative at pod install, from the widget extension parts
// the app's plugins declare. Do not edit: the next pod install rewrites it.

import SwiftUI
import WidgetKit
import dartnative_live_activities_extension

@main
struct DartNativeWidgets: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
    }
}

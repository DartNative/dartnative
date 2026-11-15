// Written by DartNative at pod install, from the widget extension parts
// the app's plugins declare. Do not edit: the next pod install rewrites it.

import SwiftUI
import WidgetKit
import dartnative_home_widget_extension

@main
struct DartNativeWidgets: WidgetBundle {
    var body: some Widget {
        DartNativeAppWidget_weather()
        DartNativeAppWidget_counter()
    }
}

struct DartNativeAppWidget_weather: Widget {
    var body: some WidgetConfiguration {
        HomeWidget.configuration(
            kind: "weather",
            name: "Weather",
            description: "The temperature and the sky where you are.",
            sizes: ["small", "medium", "lockRectangular", "lockCircular", "lockInline"])
    }
}

struct DartNativeAppWidget_counter: Widget {
    var body: some WidgetConfiguration {
        HomeWidget.configuration(
            kind: "counter",
            name: "Counter",
            description: "A number you raise from the widget.",
            sizes: ["small"])
    }
}

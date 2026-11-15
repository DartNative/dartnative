// Written by DartNative at pod install, from the App Intents packages the
// app's plugins declare. Do not edit: the next pod install rewrites it.

import AppIntents
import dartnative_live_activities

@available(iOS 17.0, *)
struct DartNativeAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [
            dartnative_live_activities.LiveActivitiesIntents.self,
        ]
    }
}

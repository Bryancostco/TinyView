import UIKit    // uikit for the app and scene lifecycle

// 10/31/26 app entry point, @main tells swift to start the app here
@main                                                             // marks this class as where the app starts
final class app_delegate: UIResponder, UIApplicationDelegate {    // UIResponder so it can sit in the responder chain like apple wants
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {    // first thing that runs on launch
        true                                                      // nothing extra to set up, the scene delegate builds the window
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {    // uikit asks which scene delegate to use
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)    // basic config
        configuration.delegateClass = scene_delegate.self    // point it at our scene delegate in code so we dont need a storyboard or plist entry
        return configuration                                 // hand it back
    }
}

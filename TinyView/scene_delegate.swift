import UIKit    // uikit for the window and navigation controller

// 10/31/26 builds the window and puts home inside a navigation controller
final class scene_delegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?    // uikit needs this exact name, its the apps main window

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {    // runs when the app window is being created
        guard let window_scene = scene as? UIWindowScene else { return }    // only care about real window scenes

        apply_navigation_bar_style()    // style every nav bar the same

        let navigation_controller = UINavigationController(rootViewController: home_view_controller())    // home is the root, everything else gets pushed on top
        navigation_controller.navigationBar.prefersLargeTitles = true    // big titles like the figma

        let new_window = UIWindow(windowScene: window_scene)     // the window for this scene
        new_window.tintColor = app_theme.accent_color            // every button and switch defaults to terracotta
        new_window.overrideUserInterfaceStyle = .light           // design is light only for now
        new_window.rootViewController = navigation_controller    // show the nav stack
        new_window.makeKeyAndVisible()                           // put it on screen
        window = new_window                                      // hold onto it or it disappears

        open_screenshot_screen_if_requested(on: navigation_controller)    // only does anything when ci passes a screen name
    }

    // 10/31/26 same background and text colors on every nav bar, no line under it
    private func apply_navigation_bar_style() {
        let bar_appearance = UINavigationBarAppearance()                                              // style object
        bar_appearance.configureWithOpaqueBackground()                                                // solid background instead of see through
        bar_appearance.backgroundColor = app_theme.background_color                                   // match the page
        bar_appearance.shadowColor = .clear                                                           // hide the line under the bar
        bar_appearance.titleTextAttributes = [.foregroundColor: app_theme.primary_text_color]         // small title color
        bar_appearance.largeTitleTextAttributes = [.foregroundColor: app_theme.primary_text_color]    // large title color
        UINavigationBar.appearance().standardAppearance = bar_appearance                              // normal state
        UINavigationBar.appearance().scrollEdgeAppearance = bar_appearance                            // when scrolled to the top
        UINavigationBar.appearance().compactAppearance = bar_appearance                               // landscape / small bar
    }

    // 10/31/26 github actions launches the app with -screenshot_screen library (etc) to jump straight to a screen
    // launch arguments that start with a dash show up in UserDefaults automatically
    private func open_screenshot_screen_if_requested(on navigation_controller: UINavigationController) {
        guard let requested_screen = UserDefaults.standard.string(forKey: "screenshot_screen") else { return }    // normal launch, do nothing
        guard let sample_book = book_store.shared.continue_reading_book else { return }    // need a book for reader and edit

        switch requested_screen {                                                                   // which screen ci asked for
        case "library":                                                                             // screen 2
            navigation_controller.pushViewController(library_view_controller(), animated: false)    // push library with no animation
        case "reader":                                                                              // screen 3
            navigation_controller.pushViewController(reader_view_controller(book_id: sample_book.id), animated: false)    // push reader with no animation
        case "edit":                                                                                // screen 4
            navigation_controller.pushViewController(library_view_controller(), animated: false)    // library underneath so it looks like the real flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {                                 // wait a beat, cant present until the window is on screen
                let edit_screen = edit_book_view_controller(book_id: sample_book.id)                // edit the sample book
                navigation_controller.present(UINavigationController(rootViewController: edit_screen), animated: false)    // show the sheet
            }
        default:     // "home" or anything else
            break    // home is already showing
        }
    }
}

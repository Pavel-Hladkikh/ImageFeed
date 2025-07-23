import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                tabBarAppearance.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
                
                UITabBar.appearance().standardAppearance = tabBarAppearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
                UITabBar.appearance().isTranslucent = false
        
        return true
    }

 

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
       
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
      
    }


}


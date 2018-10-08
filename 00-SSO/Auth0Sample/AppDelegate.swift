// AppDelegate.swift
// Auth0Sample
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Auth0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print("in my method of opening url")
        
        
        
        
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        var email :String? = nil
        var code :String? = nil
        
        
        if(urlComponents?.queryItems != nil){
            let items = (urlComponents?.queryItems)! as [NSURLQueryItem]
            if (url.scheme == "nmmdemo") {
                var vcTitle = ""
                if let _ = items.first, let propertyName = items.first?.name, let propertyValue = items.first?.value {
                    vcTitle = url.query!//"propertyName"
                    print(vcTitle)
                    
                    
                }
                
                
                for item in items{
                        let propertyName = item.name
                        let propertyValue = item.value
                    
                    print(propertyName)
                    print(propertyValue)
                    
                    if(propertyName == "email"){
                        email = propertyValue
                    }
                    
                    if(propertyName == "code"){
                        code = propertyValue
                    }
                    
                }
                
            }
            
        }
        
        let verifyRenewToken = DispatchGroup()
//        verifyRenewToken.enter()

        
        if(email != nil && code == nil){
//            Auth0
//                .authentication()
//                .startPasswordless(email: email!, type: PasswordlessType.Code, connection: "email")
//                .start { result in
//                    switch result {
//                    case .success:
//                        print("Sent OTP to " + email!)
//                    case .failure(let error):
//                        print(error)
//                    }
//            }
         
            
            
            login(email!, dispatchGroup: verifyRenewToken)
            
       // verifyRenewToken.wait()

        
        
        
        }
        
        
        if(code != nil && email != nil){
            
            // Auth0.webAuth().parameters(["email":"teste"]);
            
            
//            Auth0
//                .authentication()
//                .login(
//                    usernameOrEmail: email!,
//                    password: code!,
//                    realm: "email"
//                )
//                .start { result in
//                    switch result {
//                    case .success(let credentials):
//                        print("access_token: \(credentials.accessToken)")
//                    case .failure(let error):
//                        print(error)
//                    }
//
//
//            }
        }
        
        
        
        
//        let id = SessionManager.shared.credentials == nil ? "Home" : "WelcomeNavigation"
//
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let exampleVC: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: id) as UIViewController
//        self.window?.rootViewController = exampleVC
//        self.window?.makeKeyAndVisible()
      
        
        
        
        //guard let clientInfo = plistValues(bundle: Bundle.main) else {  }
        SessionManager.shared.patchMode = false
        
    //    let APIIdentifier = "https://asdasd/api/v2/"
        
        
       
        
        
//        Auth0
//            .webAuth()
//           // .audience(APIIdentifier)
//            .scope("openid profile read:current offline_access read:current_user")
//            .start {
//                switch $0 {
//                case .failure(let error):
//                    print("Error: \(error)")
//                case .success(let credentials):
//                    if(!SessionManager.shared.store(credentials: credentials)) {
//                        print("Failed to store credentials")
//                    } else {
//                        SessionManager.shared.retrieveProfile { error in
//                            DispatchQueue.main.async {
//
//                                //self.performSegue(withIdentifier: "ShowProfileNonAnimated", sender: nil)
//                            }
//                        }
//                    }
//                }
//        }
        
return Auth0.resumeAuth(url, options: options)
        
    }
    
    func login(_ email: String, dispatchGroup : DispatchGroup){
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return  }
        SessionManager.shared.patchMode = false
        
        
        let APIIdentifier = "https://" + clientInfo.domain + "/api/v2/"
        
        Auth0
            .webAuth()
            .audience(APIIdentifier)
            .scope("openid profile read:current offline_access read:current_user")
            .start {
                print("is started")
                switch $0 {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let credentials):
                    if(!SessionManager.shared.store(credentials: credentials)) {
                        print("Failed to store credentials")
                    } else {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil);
                        let viewController: ProfileViewController = storyboard.instantiateViewController(withIdentifier: "Welcome") as! ProfileViewController;
                        
                        
                        
                        print("view controller is ")
                        print(viewController)
                        // Then push that view controller onto the navigation stack
                        let rootViewController = self.window!.rootViewController as! HomeViewController;
                        rootViewController.performSegue(withIdentifier: "ShowProfileNonAnimated", sender: nil)
                    }
                }
        }
        
        print("entering in waiting stage")
        
//        dispatchGroup.wait()
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        let verifyRenewToken = DispatchGroup()
        verifyRenewToken.enter()
        
        
        SessionManager.shared.renewAuth { error in
            
            SessionManager.shared.retrieveProfile { error in
                print(error)
                if error != nil  {
                    print("Failed to retrieve profile check token in Home: \(String(describing: error))")
                    // return callback()
                    SessionManager.shared.credentials = nil
                    
                }else{
                    print("profile retrieved")
                }
                verifyRenewToken.leave()
            }
            print("waited 2")
        }
        
        verifyRenewToken.wait()
        
        let id = SessionManager.shared.credentials == nil ? "Home" : "WelcomeNavigation"
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let exampleVC: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: id) as UIViewController
        self.window?.rootViewController = exampleVC
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

    
    
}

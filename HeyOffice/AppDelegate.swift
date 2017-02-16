//
//  AppDelegate.swift
//  HeyOffice
//
//  Created by Colin Harris on 2/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider
import AWSLex

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSCognitoIdentityInteractiveAuthenticationDelegate {

    var window: UIWindow?
    var storyboard: UIStoryboard?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //setup logging
        AWSLogger.default().logLevel = AWSLogLevel.verbose

        //setup service config
        let serviceConfig = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: nil)
        
        //create a user pool
        let userPoolConfig = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoIdentityUserPoolAppClientId, clientSecret: CognitoIdentityUserPoolAppClientSecret, poolId: CognitoIdentityUserPoolId)
        
        AWSCognitoIdentityUserPool.register(with: serviceConfig, userPoolConfiguration: userPoolConfig, forKey: "UserPool")
        
        let pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        pool.delegate = self
        
        //setup lex
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityUserPoolRegion, identityPoolId: CognitoIdentityPoolId, identityProviderManager: pool)
        let configuration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: credentialsProvider)
        let chatConfig = AWSLexInteractionKitConfig.defaultInteractionKitConfig(withBotName: BotName, botAlias: BotAlias)
        AWSLexInteractionKit.register(with: configuration!, interactionKitConfiguration: chatConfig, forKey: "AWSLexVoiceButton")
        
        self.storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        return true
    }
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        print("startPasswordAuthentication")
        let navigationController = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! UINavigationController
        DispatchQueue.main.async {
            self.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
        }
        return navigationController.viewControllers[0] as! LoginViewController
    }
    
    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        print("startNewPasswordRequired")
        let newPasswordController = self.storyboard?.instantiateViewController(withIdentifier: "NewPassword") as! NewPasswordViewController
        DispatchQueue.main.async {
            self.window?.rootViewController?.present(newPasswordController, animated: true, completion: nil)
        }
        return newPasswordController
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print("application:openUrl")
        if url.scheme == "heyoffice" {
            let command = url.host
            if command == "confirm_registration" {
                if let navController = self.window?.rootViewController?.presentedViewController as? UINavigationController {
                    let params = url.query!.parametersFromQueryString
                    let code = params["code"]
                    let username = params["username"]
                    if let confirmRegistrationController = navController.topViewController as? ConfirmRegistrationViewController {
                        // Already visible
                        confirmRegistrationController.codeField?.text = code
                        return true
                    } else {
                        // Display confirm view
                        let controller = initConfirmRegistrationController(username: username!, code: code!)
                        navController.pushViewController(controller, animated: false)
                    }
                    return true
                }
            }
        }
        return false
    }
    
    func initConfirmRegistrationController(username: String, code: String) -> ConfirmRegistrationViewController {
        let confirmRegistrationController = self.storyboard?.instantiateViewController(withIdentifier: "ConfirmRegistration") as! ConfirmRegistrationViewController
        confirmRegistrationController.user = AWSCognitoIdentityUserPool(forKey: "UserPool").getUser(username)
        confirmRegistrationController.initialCodeValue = code
        return confirmRegistrationController
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


//
//  AppDelegate.swift
//  HeyOffice
//
//  Created by Colin Harris on 2/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSLex
import OAuthSwift
import AWSS3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSCognitoIdentityInteractiveAuthenticationDelegate {

    var window: UIWindow?
    var storyboard: UIStoryboard?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //setup logging
        AWSDDLog.sharedInstance.logLevel = .debug

        //setup service config
        let serviceConfig = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: nil)
        
        //create a user pool
        let userPoolConfig = AWSCognitoIdentityUserPoolConfiguration(
            clientId: CognitoIdentityUserPoolAppClientId,
            clientSecret: CognitoIdentityUserPoolAppClientSecret,
            poolId: CognitoIdentityUserPoolId
        )
        
        AWSCognitoIdentityUserPool.register(with: serviceConfig, userPoolConfiguration: userPoolConfig, forKey: "UserPool")
        
        let pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        pool.delegate = self
        
        // setup credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: CognitoIdentityUserPoolRegion,
            identityPoolId: CognitoIdentityPoolId,
            identityProviderManager: pool
        )
        
        // setup default aws config (with credentials provider)
        let configuration = AWSServiceConfiguration(
            region: CognitoIdentityUserPoolRegion,
            credentialsProvider: credentialsProvider
        )
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // setup lex
        let chatConfig = AWSLexInteractionKitConfig.defaultInteractionKitConfig(
            withBotName: BotName,
            botAlias: BotAlias
        )
        AWSLexInteractionKit.register(
            with: configuration!,
            interactionKitConfiguration: chatConfig,
            forKey: "AWSLexVoiceButton"
        )
        
        // setup dynamo db
        let dynamoDBMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        AWSDynamoDBObjectMapper.register(
            with: configuration!,
            objectMapperConfiguration: dynamoDBMapperConfig,
            forKey: "UserDetails"
        )
        
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
            } else if command == "confirm_forgot_password" {
                if let navController = self.window?.rootViewController?.presentedViewController as? UINavigationController {
                    let params = url.query!.parametersFromQueryString
                    let code = params["code"]
                    let username = params["username"]
                    if let confirmForgotPasswordController = navController.topViewController as? ConfirmForgotPasswordViewController {
                        // Already visible
                        confirmForgotPasswordController.codeField?.text = code
                        return true
                    } else {
                        // Display confirm view
                        let controller = initConfirmForgotPasswordController(username: username!, code: code!)
                        navController.pushViewController(controller, animated: false)
                    }
                    return true
                }
            } else if command == "authenticate_uber" {
                OAuthSwift.handle(url: url)
            }
            return true
        }
        return false
    }
    
    func initConfirmRegistrationController(username: String, code: String) -> ConfirmRegistrationViewController {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "ConfirmRegistration") as! ConfirmRegistrationViewController
        controller.user = AWSCognitoIdentityUserPool(forKey: "UserPool").getUser(username)
        controller.initialCodeValue = code
        return controller
    }
    
    func initConfirmForgotPasswordController(username: String, code: String) -> ConfirmForgotPasswordViewController {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "ConfirmForgotPassword") as! ConfirmForgotPasswordViewController
        controller.user = AWSCognitoIdentityUserPool(forKey: "UserPool").getUser(username)
        controller.initialCodeValue = code
        return controller
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}

/*
 AppDelegate.swift
 RestAPIExplorerSwift
 
 Created by Nicholas McDonald on 1/3/18.
 
 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import SalesforceSDKCore
import SalesforceSwiftSDK
import MobileCoreServices

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    override
    init()
    {
        
        super.init()
        
        SalesforceSwiftSDKManager.initSDK()
            .Builder.configure { (appconfig: AppConfig) -> Void in
                //set custom config if needed. By default this object should read from the bootconfig.plist
            }.postInit {
                //Uncomment following block to enable IDP Login flow.
                // NOTE: If advanced authentication is configured for domain, it will launch Safari to handle authentication.
                /*
                 // scheme of idpApp
                 SalesforceSwiftSDKManager.shared().idpAppURIScheme = "sampleidpapp"
                 // user friendly display name
                 SalesforceSwiftSDKManager.shared().appDisplayName = "RestAPIExplorerSwift"
                 
                 // Use the following code to replace the login flow selection dialog
                 SalesforceSwiftSDKManager.shared().idpLoginFlowSelectionBlock = {
                 let controller = IDPLoginNavViewController()
                 return controller as UIViewController & SFSDKLoginFlowSelectionView
                 }
                 */
                SFSDKAuthHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
                    self?.resetViewState {
                        self?.initializeAppViewState()
                        self?.setupRootViewController()
                    }
                })
            }
            .done()
        
    }
    
    // MARK: - App delegate lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState();
        
        // If you wish to register for push notifications, uncomment the line below.  Note that,
        // if you want to receive push notifications from Salesforce, you will also need to
        // implement the application:didRegisterForRemoteNotificationsWithDeviceToken: method (below).
        //
        // SFPushNotificationManager.sharedInstance().registerForRemoteNotifications()
        
        //Uncomment the code below to see how you can customize the color, textcolor, font and fontsize of the navigation bar
        //var loginViewConfig = SFSDKLoginViewControllerConfig()
        //Set showSettingsIcon to NO if you want to hide the settings icon on the nav bar
        //loginViewConfig.showSettingsIcon = false
        //Set showNavBar to NO if you want to hide the top bar
        //loginViewConfig.showNavbar = true
        //loginViewConfig.navBarColor = UIColor(red: 0.051, green: 0.765, blue: 0.733, alpha: 1.0)
        //loginViewConfig.navBarTextColor = UIColor.white
        //loginViewConfig.navBarFont = UIFont(name: "Helvetica", size: 16.0)
        //SFUserAccountManager.sharedInstance().loginViewControllerConfig = loginViewConfig
        
        SFSDKAuthHelper.loginIfRequired { [weak self] in
            self?.setupRootViewController()
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        //
        // Uncomment the code below to register your device token with the push notification manager
        //
        //
        // SFPushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        // if (SFUserAccountManager.sharedInstance().currentUser?.credentials.accessToken != nil)
        // {
        //     SFPushNotificationManager.sharedInstance().registerSalesforceNotifications(completionBlock: nil, fail: nil)
        // }
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error )
    {
        // Respond to any push notification registration errors here.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // If you're using advanced authentication:
        // --Configure your app to handle incoming requests to your
        //   OAuth Redirect URI custom URL scheme.
        // --Uncomment the following line and delete the original return statement:
        
        return  UserAccountManager.sharedInstance().handleAdvancedAuthenticationResponse(url, options: options)
        //        return false;
    }
    
    // MARK: - Private methods
    func initializeAppViewState()
    {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController()
    {
        let rootVC = RootViewController(nibName: nil, bundle: nil)
        let navVC = UINavigationController(rootViewController: rootVC)
        self.window!.rootViewController = navVC
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ())
    {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        postResetBlock()
    }

    func exportTestingCredentials() {
        guard let creds = UserAccountManager.sharedInstance().currentUser?.credentials,
            let instance = creds.instanceUrl,
            let identity = creds.identityUrl
            else {
                return
        }
        
        var config = ["test_client_id": SalesforceSwiftSDKManager.shared().appConfig?.remoteAccessConsumerKey,
                      "test_login_domain": UserAccountManager.sharedInstance().loginHost,
                      "test_redirect_uri": SalesforceSwiftSDKManager.shared().appConfig?.oauthRedirectURI,
                      "refresh_token": creds.refreshToken,
                      "instance_url": instance.absoluteString,
                      "identity_url": identity.absoluteString,
                      "access_token": "__NOT_REQUIRED"]
        if let community = creds.communityUrl {
            config["community_url"] = community.absoluteString
        }
        
        let configJSON = SFJsonUtils.jsonRepresentation(config)
        let board = UIPasteboard.general
        board.setValue(configJSON, forPasteboardType: kUTTypeUTF8PlainText as String)
    }
}


//
//  AppDelegate.swift
//  SnowBallEngineDemo
//
//  Created by Liu Xudong on 2024/7/4.
//

import UIKit

import UserNotifications
// 引入 Firebase 及 SnowBallEngine
import FirebaseCore

import SnowBallEngine

import UserNotifications
import FirebaseMessaging

typealias SnowBallLog = SnowBallEngine.Log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	

	private static let log = SnowBallLog(type: AppDelegate.self)

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// 配置日志系统
		#if DEBUG
		// 设置日志打印级别为 debug 及以上
		SnowBallLog.setup(level: .debug)
		#else
		// 设置日志打印级别为 warning 及以上
		SnowBallLog.setup(level: .warning)
		#endif
		
		AppDelegate.log.v("Log is ready!")
		
		// FirebaseApp
		FirebaseApp.configure()
		
		// Tracker
		SnowBallTracker.shared.setup()
		SnowBallTracker.shared.logEvent("ExampleEvent",
										parameters: ["ExampleParameter" : "ExampleValue"])
		
		// Push
		SnowBallPush.shared.setup(delegate: self)
		
		// 注册通知和向用户请求权限，需自行实现
		UNUserNotificationCenter.current().delegate = self
		application.registerForRemoteNotifications()
		// 在必要时，向用户请求展示推送的权限
		/*
		let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
		UNUserNotificationCenter.current().requestAuthorization(options: authOptions,
																completionHandler: { success, error in
			if success {
				AppDelegate.log.d("request Notification Authorization success")
			} else if let error = error {
				AppDelegate.log.d("request Notification Authorization failed, error: \(error.localizedDescription)")
			}
		})
		 */
		
		// example for shown an ad from Applovin Max
		let info = SnowBallTracker.AdRevenueInfo(mediation: .applovingMax,
												 adsRevenueFrom: .applovingMax,
												 adNetworkName: "applovin_sdk",
												 adUnitId: "03c41....fe",
												 adType: "Fullscreen",
												 adImpressionId: "4ibWY...ZGwCg",
												 adCurrencyCode: "USD",
												 adValue: 0.000987204,
												 adPrecisionType: "precise",
												 scene: "OpenDetail")
		SnowBallTracker.shared.trackAdRevenue(info: info)
		
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
		AppDelegate.log.d(notification.request.description)
		
		SnowBallPush.shared.trackReceived(notification: notification.request.identifier)
		
		let options: UNNotificationPresentationOptions =  [.banner, .list, .sound]
		return options
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
		let request = response.notification.request
		AppDelegate.log.d(request.description)
		
		SnowBallPush.shared.trackReceived(notification: request.identifier)
	}
}

extension AppDelegate: SnowBallPushDelegate {
	
	func isProLicense() -> Bool? {
		// 如果有内购系统，用户是否是付费用户变动后，也可告诉SnowBall
		nil
	}
	
	func fcmTokenDidChange(to token: String?) {
		AppDelegate.log.i("fcmToken did changed to: \(token ?? "nil")")
		// fcmToken 为 Push 设备令牌
		// If necessary send token to application server.
		// Note: This callback is fired at each app startup and whenever a new token is generated.
	}
}

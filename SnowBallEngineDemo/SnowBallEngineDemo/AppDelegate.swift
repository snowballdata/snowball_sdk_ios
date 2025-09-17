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
		SnowBallTracker.shared.logEvent("ExampleEvent", parameters: ["ExampleParameter" : "ExampleValue"])
		
		// Push
		SnowBallPush.shared.setup(delegate: self)
		
		// 注册通知和向用户请求权限，需自行实现
		UNUserNotificationCenter.current().delegate = self
		// 在必要时，向用户请求展示推送的权限
		#if DEBUG
		let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
		UNUserNotificationCenter.current().requestAuthorization(options: authOptions,
																completionHandler: { success, error in
			if success {
				AppDelegate.log.d("request Notification Authorization success")
			} else if let error = error {
				AppDelegate.log.d("request Notification Authorization failed, error: \(error.localizedDescription)")
			}
		})
		#endif
		application.registerForRemoteNotifications()
		
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
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

extension AppDelegate: SnowBallPushDelegate {
	
	func isProLicense() -> Bool? {
		// 如果有内购系统，用户是否是付费用户变动后，也可告诉SnowBall
		nil
	}
	
	func fcmTokenDidChange(to token: String?) {
		AppDelegate.log.d("fcmToken did changed to: \(token ?? "nil")")
		// fcmToken 为 Push 设备令牌
		// If necessary send token to application server.
		// Note: This callback is fired at each app startup and whenever a new token is generated.
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
		let userInfo = notification.request.content.userInfo
		AppDelegate.log.d("\(userInfo)")
		
		SnowBallPush.shared.trackReceived(notification: notification.request.identifier)
		
		if #available(iOS 14.0, *) {
			return [.banner, .list, .sound]
		} else {
			return [.alert, .sound]
		}
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse) async {
		let userInfo = response.notification.request.content.userInfo
		AppDelegate.log.d("\(userInfo)")
		
		SnowBallPush.shared.trackReceived(notification: response.notification.request.identifier)
	}
}

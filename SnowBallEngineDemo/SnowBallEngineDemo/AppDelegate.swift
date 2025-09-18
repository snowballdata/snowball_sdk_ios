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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	

	private static let log = SnowBallLog(type: AppDelegate.self)

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		AppDelegate.log.v("Log is ready!")
		
		// FirebaseApp
		FirebaseApp.configure()
		
		// 初始化 SnowBall 的 Tracker 和 Push
		// pushDelegate 为 Firebase Messaging 的代理，需手动实现 SnowBallPushDelegate
		// adjustAppPurchaseToken 为上报内购事件的价值到Adjust对应的token
		SnowBall.setup(pushDelegate: self,
					   adjustAppPurchaseToken: "testToken")
		
		// Tracker 上报事件示例
		SnowBallTracker.shared.logEvent("ExampleEvent", parameters: ["ExampleParameter" : "ExampleValue"])
		
		// 注册通知和向用户请求权限，需自行实现
		requestAndRegisterRemotePush(application: application)
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

extension AppDelegate {
	
	func requestAndRegisterRemotePush(application: UIApplication) {
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
	}
	
	/*
	 当用户的会员信息改变后，需手动通知 Push 系统，以改变用户订阅的 topic 是否是 pro
	 例如：用户购买会员成功权限升级，或者会员到期后权限降级
	 */
	func licenseChanged() {
		SnowBallPush.shared.userLicenseChanged()
	}
}

// MARK: 实现 SnowBallPush 代理
extension AppDelegate: SnowBallPushDelegate {
	
	// 如果有内购系统，需要在这里实现返回用户是否是付费用户
	// SnowBall 会在订阅远程通知组时，主动拉取此处信息
	func isProLicense() -> Bool? {
		// TODO: 需自行实现
		nil
	}
	
	// 通知令牌变动后 SnowBall 会主动告诉 App，如有需要自行处理
	func fcmTokenDidChange(to token: String?) {
		AppDelegate.log.d("fcmToken did changed to: \(token ?? "nil")")
		// fcmToken 为 Push 设备令牌
		// If necessary send token to application server.
		// Note: This callback is fired at each app startup and whenever a new token is generated.
	}
}

// MARK: 实现通知代理
extension AppDelegate: UNUserNotificationCenterDelegate {
	
	// 前台时收到通知
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
		let userInfo = notification.request.content.userInfo
		AppDelegate.log.d("\(userInfo)")
		
		SnowBallPush.shared.trackReceived(notification: notification.request.identifier)
		
		return [.banner, .list, .sound]
	}
	
	// 后台时收到通知，用户点击打开
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse) async {
		let userInfo = response.notification.request.content.userInfo
		AppDelegate.log.d("\(userInfo)")
		
		SnowBallPush.shared.trackReceived(notification: response.notification.request.identifier)
	}
}

//
//  SnowBall.swift
//
//  Created by Liu Xudong on 2024/7/5.
//

import Foundation

public typealias SnowBallTracker = Tracker
public typealias SnowBallPush = Push
public typealias SnowBallLog = Log
public typealias SnowBallStore = StoreServer

public class SnowBall {
	
	private struct Constants {
		static let UserDefaultsSuitName = "SnowBallEngineUserDefaults"
	}
	
	static let Config = UserDefaults(suiteName: Constants.UserDefaultsSuitName) ?? UserDefaults.standard
	
	public static func setup(pushDelegate: SnowBallPushDelegate? = nil,
							 adjustAppPurchaseToken: String? = nil) {
		
		// 配置日志系统
		#if DEBUG
		// 设置日志打印级别为 debug 及以上
		Log.setup(level: .debug)
		#else
		// 设置日志打印级别为 warning 及以上
		Log.setup(level: .warning)
		#endif
		
		if let pushDelegate = pushDelegate {
			SnowBallPush.shared.setup(delegate: pushDelegate)
		}
		SnowBallTracker.shared.setup(adjustAppPurchaseToken: adjustAppPurchaseToken)
	}
}

//
//  SnowBall.swift
//
//  Created by Liu Xudong on 2024/7/5.
//

import Foundation

public typealias SnowBallTracker = Tracker

public typealias SnowBallPush = Push

public class SnowBall {
	
	private struct Constants {
		static let UserDefaultsSuitName = "SnowBallEngineUserDefaults"
	}
	
	
	static let Config = UserDefaults(suiteName: Constants.UserDefaultsSuitName) ?? UserDefaults.standard
}

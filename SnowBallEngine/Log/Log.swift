//
//  Log.swift
//
//  Created by LiuXudong on 12/05/24.
//  Copyright © 2024 Daocheng. All rights reserved.
//

import os

public class Log {
	
	public enum Level: Int {
		case verbose = 0
		case debug = 1
		case info = 2
		case warning = 3
		case error = 4
	}
	
	public static var level = Level.warning
	
	public let tag: String
	let logger: Logger
	
	public init(tag: String) {
		self.tag = tag
		
		logger = Logger(subsystem: "SnowBallEngine", category: "Log")
	}
	
	public convenience init<Subject>(type: Subject) {
		self.init(tag: String(describing: type))
	}
	
	public static func setup(level: Level = .warning) {
		Log.level = level
	}
	
	public func v(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.verbose.rawValue else {
			return
		}
		logger.debug("\(Date()) [V] (\(self.tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func d(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.debug.rawValue else {
			return
		}
		logger.debug("\(Date()) [D] (\(self.tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func i(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.info.rawValue else {
			return
		}
		logger.info("\(Date()) [I] (\(self.tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func w(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.warning.rawValue else {
			return
		}
		logger.warning("\(Date()) [W] (\(self.tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func e(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.error.rawValue else {
			return
		}
		logger.error("\(Date()) [E] (\(self.tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
}

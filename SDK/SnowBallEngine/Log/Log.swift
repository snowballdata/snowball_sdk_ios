//
//  Log.swift
//
//  Created by LiuXudong on 12/05/24.
//  Copyright © 2024 Daocheng. All rights reserved.
//

import CocoaLumberjack

public class Log {
	
	private class ClearLogFormatter: NSObject, DDLogFormatter {
		func format(message logMessage: DDLogMessage) -> String? {
			let dateformat = DateFormatter()
			dateformat.dateFormat = "HH:mm:ss.SSS"
			return dateformat.string(from: logMessage.timestamp) + " " + logMessage.message
		}
	}
	
	public enum Level: Int {
		case verbose = 0
		case debug = 1
		case info = 2
		case warning = 3
		case error = 4
	}
	
	public static var level = Level.warning
	
	public let tag: String
	
	public init(tag: String) {
		self.tag = tag
	}
	
	public convenience init<Subject>(type: Subject) {
		self.init(tag: String(describing: type))
	}
	
	public static func getFolderURL() -> URL {
		if #available(iOS 16.0, *) {
			FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(path: "Logs", directoryHint: URL.DirectoryHint.isDirectory)
		} else {
			FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs", isDirectory: true)
		}
	}
	
	public static func setup(level: Level = .warning) {
		DDOSLogger.sharedInstance.logFormatter = ClearLogFormatter()
		DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
		Log.level = level
		
		let urlForFolder = getFolderURL()
		let logFileManger = DDLogFileManagerDefault(logsDirectory: urlForFolder.relativePath)
		
		let fileLogger: DDFileLogger = DDFileLogger(logFileManager: logFileManger)
		fileLogger.rollingFrequency = TimeInterval(60 * 60 * 24)  // 24 hours
		fileLogger.logFileManager.maximumNumberOfLogFiles = 7
		DDLog.add(fileLogger)
	}
	
	public func v(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.verbose.rawValue else {
			return
		}
		
		DDLogVerbose("[V] (\(tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func d(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.debug.rawValue else {
			return
		}
		DDLogDebug("[D] (\(tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func i(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.info.rawValue else {
			return
		}
		DDLogInfo("[I] (\(tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func w(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.warning.rawValue else {
			return
		}
		DDLogWarn("[W] (\(tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
	
	public func e(_ msg: String?, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
		guard Log.level.rawValue <= Level.error.rawValue else {
			return
		}
		DDLogError("[E] (\(tag).\(function):\(line)) \(msg ?? "[No Message]")")
	}
}

public extension Log {
	
	static func getLogFileURLs() -> [URL] {
		let folderURL = getFolderURL()
		var isDir : ObjCBool = false
		
		guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir),
			  isDir.boolValue,
			  let fileNames = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)
		else {
			return []
		}
		var result = [URL]()
		for fileName in fileNames {
			let fileURL = folderURL.appendingPathComponent(fileName)
			var isDir : ObjCBool = false
			
			if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir),
			   isDir.boolValue == false,
			   fileName.hasSuffix(".log") {
				result.append(fileURL)
			}
		}
		return result
	}
}

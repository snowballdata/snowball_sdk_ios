//
//  Push.swift
//  SnowBallEngine
//
//  Created by Liu Xudong on 2024/5/3.
//  Copyright © 2024 thinkyeah. All rights reserved.
//

import FirebaseMessaging

public protocol SnowBallPushDelegate {
	
	func isProLicense() -> Bool?
	
	func fcmTokenDidChange(to token: String?)
}

public class Push: NSObject {
	
	static let log = Log(type: Push.self)
	
	public static let shared = Push()
	
	public var delegate: SnowBallPushDelegate?
	
	public func setup(delegate: SnowBallPushDelegate) {
		Messaging.messaging().delegate = Push.shared
		self.delegate = delegate
	}
	
	public var isPro: Bool? {
		delegate?.isProLicense()
	}
	
	public func trackReceived(notification id: String) {
		Tracker.logEvent(Events.DidReceiveNotification, parameters: ["push_id" : id])
	}
	
	public static func subscribe(topic: String) {
		Push.log.i("Subscribe notification topic \(topic)")
		Messaging.messaging().subscribe(toTopic: topic)
	}
	
	public static func unSubscribe(topic: String) {
		Push.log.i("Unsubscribe notification topic \(topic)")
		Messaging.messaging().unsubscribe(fromTopic: topic)
	}
	
	public func subscribe(topic: String) {
		Push.log.i("Subscribe notification topic \(topic)")
		Messaging.messaging().subscribe(toTopic: topic)
	}
	
	public func unSubscribe(topic: String) {
		Push.log.i("Unsubscribe notification topic \(topic)")
		Messaging.messaging().unsubscribe(fromTopic: topic)
	}
}

extension Push {
	
	private struct Constants {
		static let UserDefaultsKeySubscribedTopicRegion = "SubscribedTopicRegion"
		static let UserDefaultsKeySubscribedTopicLanguage = "SubscribedTopicLanguage"
		static let UserDefaultsKeySubscribedTopicLocaleId = "SubscribedTopicLocaleId"
		static let UserDefaultsKeySubscribedTopicLicense = "SubscribedTopicLicense"
		static let UserDefaultsKeySubscribedTopicTimezoneStr = "SubscribedTopicTimezoneStr"
		
		static let UserDefaultsKeyDidTrackPushToken = "DidTrackPushToken"
	}
	
	private struct Events {
		static let DidReceiveNotification = "push_custom_receive"
		static let NotificationTokenGetNew = "th_push_token_new"
		static let NotificationTokenUpdate = "th_push_token_update"
	}
	
	fileprivate static var didTrackPushToken: Bool {
		get {
			SnowBall.Config.bool(forKey: Constants.UserDefaultsKeyDidTrackPushToken)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeyDidTrackPushToken)
		}
	}
	
	fileprivate static var subscribedTopicRegion: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeySubscribedTopicRegion)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeySubscribedTopicRegion)
		}
	}
	
	fileprivate static var subscribedTopicLanguage: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeySubscribedTopicLanguage)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeySubscribedTopicLanguage)
		}
	}
	
	fileprivate static var subscribedTopicLocaleId: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeySubscribedTopicLocaleId)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeySubscribedTopicLocaleId)
		}
	}
	
	fileprivate static var subscribedTopicLicense: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeySubscribedTopicLicense)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeySubscribedTopicLicense)
		}
	}
	
	fileprivate static var subscribedTopicTimezoneStr: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeySubscribedTopicTimezoneStr)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeySubscribedTopicTimezoneStr)
		}
	}
	
}

extension Push: MessagingDelegate {
	
	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		
		Push.log.i("Firebase registration token: \(fcmToken ?? "nil")")
		
		self.delegate?.fcmTokenDidChange(to: fcmToken)
		
		// track token did change
		let isPro = {
			if let isPro = self.delegate?.isProLicense() {
				return isPro ? "true" : "false"
			} else {
				return "nil"
			}
		}
		Tracker.logEvent(Push.didTrackPushToken ? Events.NotificationTokenUpdate : Events.NotificationTokenGetNew,
						 parameters: ["data" : fcmToken ?? "nil",
									  "is_pro" : isPro])
		Push.didTrackPushToken =  true
		guard let _ = fcmToken else {
			Push.log.i("Firebase registration token failed")
			return
		}
		
		let misc = "misc"
		var region: String = {
			if let r = Locale.current.regionCode?.lowercased() {
				if ["in", "id", "iq", "pk", "kr", "us", "jp", "bd","br", "mx", "sa", "eg", "th","my", "ph", "vn", "ae","tw", "cn", "tr", "gb", "lk", "fr", "co", "de", "ru"].contains(r) {
					return r
				}
			}
			return misc
		}()
		var localId: String = "misc"
		var language: String = {
			if let l = Locale.current.languageCode?.lowercased(),
			   ["en", "ar", "de", "es", "fr", "in","it", "ja",  "ko", "ms", "pt", "ru", "th", "vi","tr", "hi", "zh"].contains(l) {
				if region != misc {
					localId = l + "_" + region.uppercased()
					if l == "zh" {
						return localId
					}
				}
				return l
			}
			return misc
		}()
		
		
		let license: String? = {
			if let isPro = Push.shared.isPro {
				return isPro ? "pro" : "free"
			}
			return nil
		}()
		var timeZone: String = {
			let secondsOneHour = 60 * 60
			let timeZone: Int = TimeZone.current.secondsFromGMT() / secondsOneHour
			return "\(timeZone > 0 ? "plus" : "minus")_\(timeZone > 0 ? timeZone : -timeZone)"
		}()
		
		Push.log.i("Ready to Subscribe: \(region)%\(language)%\(localId)%\(license ?? "")%\(timeZone)")
		
		region = "region_" + region
		if region != Push.subscribedTopicRegion {
			if let subscribedTopicRegion = Push.subscribedTopicRegion {
				Push.unSubscribe(topic: subscribedTopicRegion)
			}
			Push.subscribe(topic: region)
			Push.subscribedTopicRegion = region
		}
		
		language = "lang_" + language
		if language != Push.subscribedTopicLanguage {
			if let subscribedTopicLanguage = Push.subscribedTopicLanguage {
				Push.unSubscribe(topic: subscribedTopicLanguage)
			}
			Push.subscribe(topic: language)
			Push.subscribedTopicLanguage = language
		}
		
		localId = "locale_id_" + localId
		if localId != Push.subscribedTopicLocaleId {
			if let subscribedTopicLocaleId = Push.subscribedTopicLocaleId {
				Push.unSubscribe(topic: subscribedTopicLocaleId)
			}
			Push.subscribe(topic: localId)
			Push.subscribedTopicLocaleId = localId
		}
		
		if var license = license {
			license = "license_" + license
			if license != Push.subscribedTopicLicense {
				if let subscribedTopicLicense = Push.subscribedTopicLicense {
					Push.unSubscribe(topic: subscribedTopicLicense)
				}
				Push.subscribe(topic: license)
				Push.subscribedTopicLicense = license
			}
		}

		timeZone = "tz_gmt_" + timeZone
		if timeZone != Push.subscribedTopicTimezoneStr {
			if let subscribedTopicTimezoneStr = Push.subscribedTopicTimezoneStr {
				Push.unSubscribe(topic: subscribedTopicTimezoneStr)
			}
			Push.subscribe(topic: timeZone)
			Push.subscribedTopicTimezoneStr = timeZone
		}
	}
}

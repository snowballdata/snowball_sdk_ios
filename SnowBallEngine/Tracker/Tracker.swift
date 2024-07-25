//
//  Tracker.swift
//  SnowBallEngine
//
//  Created by Liu Xudong on 2024/5/3.
//  Copyright © 2024 thinkyeah. All rights reserved.
//

import AdServices

import FirebaseAnalytics

public class Tracker {
	
	private static let log = Log(type: Tracker.self)
	
	public static let shared = Tracker()
	
	public func setup() {
		Tracker.recallAttributionTokenIfNeed()
	}
	
	public func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
		Tracker.logEvent(eventName, parameters: parameters)
	}
	
	static func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
		guard eventName.count > 0 else { return }
		if eventName.count > 40 {
			self.log.e("❌ The maximum supported length is 40")
		}
		self.log.i("event: \(eventName), parameters: \(parameters == nil ? "nil" : String(describing: parameters!))")
		
		let step = 90
		if var parameters = parameters {
			for (key, value) in parameters {
				if let content = value as? String,
				   content.count > step {
					for i in stride(from: 0, to: content.count, by: step) {
						let start = content.index(content.startIndex, offsetBy: i)
						let end = {
							if i+step <= content.count {
								return content.index(content.startIndex, offsetBy: i+step)
							} else {
								return content.endIndex
							}
						}()
						let data = content[start..<end]
						parameters["\(key)_\((i+1)/step)"] = String(data)
					}
					parameters.removeValue(forKey: key)
				}
			}
			Analytics.logEvent(eventName, parameters: parameters)
		} else {
			Analytics.logEvent(eventName, parameters: parameters)
		}
	}
	
	/// mediation: 广告聚合平台 e.g. "max", "admob", "ironSource"
	/// adsRevenueFrom: 广告收入资料来源 e.g. "applovin_max_ilrd", "admob_pingback", "self" other
	/// adNetworkName: 广告的广告商名称 e.g. "adcolony", "facebook", "tapjoy", "admob_native", "applovin_sdk", "pangle", "unity", "ironsource",
	/// adUnitId: 广告类型 e.g. "app_open", "Fullscreen", "Native", "Rewarded Video", "Banner", "Medium Rectangle", "rewarded_inters" "vungle", "inmobi", "smaato", "fyber"
	/// adType: 广告在后台配置时的unitID
	/// adImpressionId: 单次展示的ID ad id
	/// adCurrencyCode: 广告价值货币 e.g. "USD"
	/// adValue: 广告价值 e.g. 0.00183 in USD
	/// adPrecisionType: 价格是准确的还是预估值 e.g. "estimated", "publisher_provided", "precise"
	/// scene: 自定义广告展示的场景
	public struct AdRevenueInfo {
		var mediation: Mediation
		var adsRevenueFrom: RevenueFrom // TODO: enum
		var adNetworkName: String
		var adUnitId: String?
		var adType: String
		var adImpressionId: String?
		var adCurrencyCode: String
		var adValue: Double
		var adPrecisionType: String?
		var scene: String?
		//		var userSegment: String
		//		var mediation_adapterCredentials: String
		
		public init(mediation: Mediation, adsRevenueFrom: RevenueFrom, adNetworkName: String, adUnitId: String?, adType: String, adImpressionId: String?, adCurrencyCode: String, adValue: Double, adPrecisionType: String?, scene: String?) {
			self.mediation = mediation
			self.adsRevenueFrom = adsRevenueFrom
			self.adNetworkName = adNetworkName
			self.adUnitId = adUnitId
			self.adType = adType
			self.adImpressionId = adImpressionId
			self.adCurrencyCode = adCurrencyCode
			self.adValue = adValue
			self.adPrecisionType = adPrecisionType
			self.scene = scene
		}
	}
	
	public func trackAdRevenue(info: AdRevenueInfo) {
		
		var parameters: [String: Any] = [
			"mediation": info.mediation.rawValue,
			"report_from": info.adsRevenueFrom.rawValue,
			"report_data_version": Constants.REPORT_DATA_VERSION,
			
			"app_version": Bundle.main.shortVersionString ?? "null",
			"country": Locale.current.regionCode ?? "null",
			
			"id": info.adImpressionId ?? UUID().uuidString,
			"adunit_format": info.adType,
			
			"currency": info.adCurrencyCode,
			"value": info.adValue,
			"publisher_revenue": info.adValue > 0 ? String(info.adValue) : "null",
			"network_name": info.adNetworkName,
			
			"precision": info.adPrecisionType ?? "unknown",
			
			"scene": info.scene ?? "unknown"
		]
		if let unitId = info.adUnitId {
			parameters["adunit_id"] = unitId
			parameters["adunit_name"] = unitId
			parameters["network_placement_id"] = unitId
		}
		// adgroup_id adgroup_name adgroup_type adgroup_priority
		Tracker.logEvent(Events.TH_AD_IMPRESSION, parameters: parameters)
		Tracker.logEvent(Events.AD_IMPRESSION, parameters: parameters)
		
		let total = Tracker.totalAdsRevenue + info.adValue
		Tracker.totalAdsRevenue = total
		// 记录total revenue
		if total > 0.01 {
			let param: [String : Any] = ["currency": info.adCurrencyCode,
										 "value": total]
			Tracker.logEvent(Events.THAdjustTotalAdsRevenue,
							 parameters: param)
			Tracker.totalAdsRevenue = 0
		}
	}
}


extension Tracker {
	
	public enum Mediation {
		case applovingMax
		case admob
		case ironSource
		case other(name: String)
		
		public var rawValue: String {
			switch self {
			case .applovingMax:
				return "max"
			case .admob:
				return "admob"
			case .ironSource:
				return "ironSource"
			case .other(name: let name):
				return "other: \(name)"
			}
		}
	}
	
	public enum RevenueFrom {
		case applovingMax
		case admobPingback
		case `self`
		case other(name: String)
		
		public var rawValue: String {
			switch self {
			case .applovingMax:
				return "applovin_max_ilrd"
			case .admobPingback:
				return "admob_pingback"
			case .self:
				return "self"
			case .other(name: let name):
				return "other: \(name)"
			}
		}
	}
	
	private struct Events {
		static let THInstallReferrer = "th_install_referrer"
		static let THInstallReferrerFailed = "th_install_referrer_failed"
		static let THAsaUserTrack = "th_asa_user_track"
		static let TH_AD_IMPRESSION = "th_ad_impression"
		static let AD_IMPRESSION = "ad_impression"
		static let THAdjustTotalAdsRevenue = "Total_Ads_Revenue_001"
		
		struct Keys {
			static let reason = "reason"
		}
	}
	
	private struct Constants {
		static let UserDefaultsKeyAttributionToken = "AttributionToken"
		static let UserDefaultsKeyShouldPostAttributionToken = "ShouldPostAttributionToken"
		static let UserDefaultsKeyTotalAdsRevenue = "TotalAdsRevenue"
		
		static let REPORT_DATA_VERSION = "1"
	}
	
	private static var attributionToken: String? {
		get {
			SnowBall.Config.string(forKey: Constants.UserDefaultsKeyAttributionToken)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeyAttributionToken)
		}
	}
	
	private static var shouldPostAttributionToken: Bool {
		get {
			SnowBall.Config.bool(forKey: Constants.UserDefaultsKeyShouldPostAttributionToken)
		}
		set {
			SnowBall.Config.setValue(newValue, forKey: Constants.UserDefaultsKeyShouldPostAttributionToken)
		}
	}
	
	private static var totalAdsRevenue: Double {
		get {
			return SnowBall.Config.double(forKey: Constants.UserDefaultsKeyTotalAdsRevenue)
		}
		set {
			SnowBall.Config.set(newValue, forKey: Constants.UserDefaultsKeyTotalAdsRevenue)
		}
	}
}

extension Tracker {
	
	static func recallAttributionTokenIfNeed() {
		self.attributionToken = nil
		self.shouldPostAttributionToken = true
		logAttributionTokenIfNeeded(count: 0)
	}
	
	private static func logAttributionTokenIfNeeded(count: Int = 0) {
		guard count < 3 else {
			self.attributionToken = ""
			return
		}
		guard self.attributionToken == nil else {
			self.postTokenIfNeeded()
			return
		}
		if #available(iOS 14.3, *) {
			do {
				let token = try AAAttribution.attributionToken()
				
				self.log.i("attributionToken = \(token)")
				let parameter: [String: Any] = [
					"token": token,
					"source": "apple_search_ads",
					"pending": true
				]
				self.logEvent(Events.THInstallReferrer, parameters: parameter)
				self.attributionToken = token
				// 自己去请求一下post 结果，然后log
				postTokenIfNeeded()
			} catch {
				self.log.e("attributionToken error = " + error.localizedDescription)
				self.logEvent(Events.THInstallReferrerFailed,
								 parameters: [Events.Keys.reason: error.localizedDescription])
				// 如果失败，需要重试
				DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
					self.logAttributionTokenIfNeeded(count: count + 1)
				}
			}
		} else {
			self.log.e("iOS version is below 14.3, attributionToken not supported")
			self.logEvent(Events.THInstallReferrerFailed,
							 parameters: [Events.Keys.reason: "iOS version is below 14.3, attributionToken not supported"])
			self.attributionToken = ""
			return
		}
		
	}
	
	private static func postTokenIfNeeded(count: Int = 0) {
		guard count < 3 else {
			self.shouldPostAttributionToken = false
			return
		}
		guard let loggedAttributionToken = self.attributionToken,
			  loggedAttributionToken.count > 0 else {
			self.shouldPostAttributionToken = false
			return
		}
		guard self.shouldPostAttributionToken else {
			return
		}
		guard let data = loggedAttributionToken.data(using: .utf8) else { return }
		
		struct TokenResponse: Decodable {
			var attribution: Bool
			var orgId: UInt64?
			var campaignId: UInt64?
			var adGroupId: UInt64?
			var keywordId: UInt64?
			var adId: UInt64?
			var conversionType: String?
			var countryOrRegion: String?
			var clickDate: String?
		}
		
		guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
			self.log.e("Invalid URL")
			return
		}
		
		// 创建请求对象
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
		request.httpBody = data
		// 创建URLSession
		let session = URLSession.shared
		
		func networkFailed() {
			DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
				self.postTokenIfNeeded(count: count + 1)
			}
		}
		// 发送请求
		let task = session.dataTask(with: request) { data, response, error in
			if let error = error {
				self.log.e("Error: \(error)")
				networkFailed()
				return
			}
			
			guard let data = data else {
				self.log.e("No data received")
				networkFailed()
				return
			}
			// 打印返回的数据，便于调试
			if let dataString = String(data: data, encoding: .utf8) {
				self.log.i("Response data: \(dataString)")
			}
			
			// 解码响应数据
			do {
				let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
				self.shouldPostAttributionToken = false
				if tokenResponse.attribution {
					var parameters = ["campaign_id": tokenResponse.campaignId ?? "",
									  "adgroup_id": tokenResponse.adGroupId ?? "",
									  "country": tokenResponse.countryOrRegion ?? ""]
					if let date = tokenResponse.clickDate {
						parameters["click_date"] = date
					}
					self.logEvent(Events.THAsaUserTrack, parameters: parameters)
				} else {
					self.shouldPostAttributionToken = false
				}
				return
			} catch {
				self.log.e("Error decoding data: \(error)")
				networkFailed()
				return
			}
		}
		task.resume()
	}
}

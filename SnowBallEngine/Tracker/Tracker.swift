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
    
    static let log = Log(type: Tracker.self)
    
    public static let shared = Tracker()
    
	var adjustAppPurchaseToken: String?
	var adjustAdRevenueToken: String?
	var adjustAdTotalRevenueToken: String?
	
	public func setup(adjustAppPurchaseToken: String?,
					  adjustAdRevenueToken: String?,
					  adjustAdTotalRevenueToken: String?) {
		self.adjustAppPurchaseToken = adjustAppPurchaseToken
		self.adjustAdRevenueToken = adjustAdRevenueToken
		self.adjustAdTotalRevenueToken = adjustAdTotalRevenueToken
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
}


extension Tracker {
    
    struct Events {
        static let SE_InstallReferrer = "se_install_referrer"
        static let SE_InstallReferrerFailed = "se_install_referrer_failed"
        static let SE_AsaUserTrack = "se_asa_user_track"
        static let SE_AD_IMPRESSION = "se_ad_impression"
        static let AD_IMPRESSION = "ad_impression"
        static let TotalAdsRevenue = "Total_Ads_Revenue_001"
        
        static let SE_InAppPurchase = "se_in_app_purchase"
        
        struct Keys {
            static let reason = "reason"
        }
    }
    
    public struct Constants {
        static let UserDefaultsKeyAttributionToken = "AttributionToken"
        static let UserDefaultsKeyShouldPostAttributionToken = "ShouldPostAttributionToken"
        static let UserDefaultsKeyTotalAdsRevenue = "TotalAdsRevenue"
        
        public static let REPORT_DATA_VERSION = "1"
    }
    
}

// MARK: Attribution
extension Tracker {
    
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
                self.logEvent(Events.SE_InstallReferrer, parameters: parameter)
                self.attributionToken = token
                // 自己去请求一下post 结果，然后log
                postTokenIfNeeded()
            } catch {
                self.log.e("attributionToken error = " + error.localizedDescription)
                self.logEvent(Events.SE_InstallReferrerFailed,
                              parameters: [Events.Keys.reason: error.localizedDescription])
                // 如果失败，需要重试
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.logAttributionTokenIfNeeded(count: count + 1)
                }
            }
        } else {
            self.log.e("iOS version is below 14.3, attributionToken not supported")
            self.logEvent(Events.SE_InstallReferrerFailed,
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
                    self.logEvent(Events.SE_AsaUserTrack, parameters: parameters)
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

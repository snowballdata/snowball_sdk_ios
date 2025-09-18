//
//  Tracker + Ads.swift
//  SnowBallEngine
//
//  Created by XuDong Liu on 2025/3/6.
//

import Foundation

// MARK: Ads
extension Tracker {
    
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
        var adsRevenueFrom: RevenueFrom
        var adNetworkName: String
        var adUnitId: String?
        var adType: String
        var adImpressionId: String?
        var adCurrencyCode: String
        var adValue: Double
        var adPrecisionType: String?
        var scene: String?
        
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
    
    public enum Mediation {
        case applovinMax
        case admob
        case ironSource
        case other(name: String)
        
        public var rawValue: String {
            switch self {
            case .applovinMax:
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
        case applovinMax
        case admobPingback
        case `self`
        case other(name: String)
        
        public var rawValue: String {
            switch self {
            case .applovinMax:
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
    
    
    public enum PrecisionType {
        
        case estimated
        case publisherProvided
        case precise
        case unknown
        
        public var rawValue: String {
            switch self {
            case .estimated:
                return "estimated"
            case .publisherProvided:
                return "publisherProvided"
            case .precise:
                return "precise"
            case .unknown:
                return "unknown"
            }
        }
    }
    
    public class NetworkName {
        
        public static let ADCOLONY = "adcolony";
        public static let FACEBOOK = "facebook";
        public static let TAPJOY = "tapjoy";
        public static let ADMOB = "admob_native";
        public static let APPLOVIN = "applovin_sdk";
        public static let PANGLE = "pangle";
        public static let UNITY = "unity";
        public static let IRONSOURCE = "ironsource";
        public static let VUNGLE = "vungle";
        public static let INMOBI = "inmobi";
        public static let SMAATO = "smaato";
        public static let FYBER = "fyber";
        
        public static func turnTo(name: String) -> String {
            let name = name.lowercased()
            if name.contains(ADCOLONY) {
                return ADCOLONY
            }
            else if name.contains(FACEBOOK) || name.contains("meta") {
                return FACEBOOK
            }
            else if name.contains(TAPJOY) {
                return TAPJOY
            }
            else if name.contains("admob") {
                return ADMOB
            }
            else if name.contains("applovin") {
                return APPLOVIN
            }
            else if name.contains(PANGLE) {
                return PANGLE
            }
            else if name.contains(UNITY) {
                return UNITY
            }
            else if name.contains(IRONSOURCE) {
                return IRONSOURCE
            }
            else if name.contains(VUNGLE) {
                return VUNGLE
            }
            else if name.contains(INMOBI) {
                return INMOBI
            }
            else if name.contains(SMAATO) {
                return SMAATO
            }
            else if name.contains(FYBER) {
                return FYBER
            }
            return name
        }
    }
    
    public class Format {
        public static let APP_OPEN = "app_open";
        public static let FULLSCREEN = "Fullscreen";
        public static let NATIVE = "Native";
        public static let REWARDED = "Rewarded Video";
        
        public static let BANNER = "Banner";
        public static let RECTANGLE = "Medium Rectangle";
        
        public static let REWARDED_INTERS = "rewarded_inters";
        
        public static func turnTo(format: String) -> String {
            var adFormat = format
            if adFormat.uppercased().contains("BANNER") {
                adFormat = Format.BANNER
            }
            else if adFormat.contains("INTE") {
                if adFormat.contains("REWARD") {
                    adFormat = Format.REWARDED
                } else {
                    adFormat = Format.FULLSCREEN
                }
            }
            else if adFormat.contains("REWARD") {
                adFormat = Format.REWARDED
            }
            else if adFormat.contains("NATIVE") {
                adFormat = Format.NATIVE
            }
            else if adFormat.contains("MREC") {
                adFormat = Format.RECTANGLE
            }
            else if adFormat.contains("RECTANGLE") {
                adFormat = Format.RECTANGLE
            }
            return adFormat
        }
    }
}

extension Tracker {
    
    private static var totalAdsRevenue: Double {
        get {
            return SnowBall.Config.double(forKey: Constants.UserDefaultsKeyTotalAdsRevenue)
        }
        set {
            SnowBall.Config.set(newValue, forKey: Constants.UserDefaultsKeyTotalAdsRevenue)
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
        Tracker.logEvent(Events.SE_AD_IMPRESSION, parameters: parameters)
        Tracker.logEvent(Events.AD_IMPRESSION, parameters: parameters)
        
        let total = Tracker.totalAdsRevenue + info.adValue
        Tracker.totalAdsRevenue = total
        // 记录total revenue
        if total > 0.01 {
            let param: [String : Any] = ["currency": info.adCurrencyCode,
                                         "value": total]
            Tracker.logEvent(Events.TotalAdsRevenue,
                             parameters: param)
            Tracker.totalAdsRevenue = 0
        }
    }
}

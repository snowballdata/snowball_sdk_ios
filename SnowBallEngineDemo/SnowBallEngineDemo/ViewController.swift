//
//  ViewController.swift
//  SnowBallEngineDemo
//
//  Created by Liu Xudong on 2024/7/4.
//

import UIKit

import SnowBallEngine

import GoogleMobileAds

class ViewController: UIViewController {
    
    private var interstitial: InterstitialAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    // DEMO: 上传内购事件价值
    private func recordPurchaseRevenue(unitId: String?) {
        SnowBallTracker.shared.trackInAppPurchaseRevenue(productId: "com.xxx.lifetime",
                                                         currency: "USD",
                                                         price: 59.0,
                                                         scene: "CustomScene")
        SnowBallTracker.shared.trackSubsPurchaseRevenue(productId: "com.xxx.weekly",
                                                        currency: "HKD",
                                                        price: 9.9,
                                                        isFreeTrial: true,
                                                        scene: "CustomScene")
//        SnowBallTracker.shared.trackPurchaseRevenue(transaction: Transaction,
//                                                    product: Product,
//                                                    scene: String?)
    }
    
    // 设置并加载插屏广告
    private func loadAdmobInterstitialAd() async {
        do {
            let testUnitId = "ca-app-pub-3940256099942544/4411468910"
            interstitial = try await InterstitialAd.load(with: testUnitId, request: Request())
            interstitial?.paidEventHandler = { [weak self] adValue in
                guard let self else {return}
                self.recordAdmobAdRevenue(unitId: self.interstitial?.adUnitID,
                                          id: self.interstitial?.responseInfo.responseIdentifier,
                                          format: Tracker.Format.FULLSCREEN,
                                          adValue: adValue,
                                          scene: "YourCustomSceneName")
            }
            interstitial?.fullScreenContentDelegate = self
            interstitial?.present(from: self)
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
    }
    
    // DEMO: 上传Admob广告事件价值
    private func recordAdmobAdRevenue(unitId: String?,
                                      id: String?,
                                      format: String,
                                      adValue: AdValue,
                                      scene: String?) {
        var precision = Tracker.PrecisionType.estimated
        switch adValue.precision {
        case .estimated:
            precision = .estimated
        case .precise:
            precision = .precise
        case .publisherProvided:
            precision = .publisherProvided
        default:
            precision = .unknown
        }
        // example for shown an ad from Applovin Max
        let info = SnowBallTracker.AdRevenueInfo(mediation: .admob,
                                                 adsRevenueFrom: .admobPingback,
                                                 adNetworkName: Tracker.NetworkName.ADMOB,
                                                 adUnitId: unitId,
                                                 adType: format,
                                                 adImpressionId: id ?? UUID().uuidString,
                                                 adCurrencyCode: adValue.currencyCode,
                                                 adValue: adValue.value.doubleValue,
                                                 adPrecisionType: precision.rawValue,
                                                 scene: scene ?? "unknown")
        SnowBallTracker.shared.trackAdRevenue(info: info)
    }
}

extension ViewController: FullScreenContentDelegate {
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("\(#function) called with error: \(error.localizedDescription)")
        // Clear the interstitial ad.
        interstitial = nil
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        // Clear the interstitial ad.
        interstitial = nil
    }
}

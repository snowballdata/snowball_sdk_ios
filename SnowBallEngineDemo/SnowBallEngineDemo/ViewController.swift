//
//  ViewController.swift
//  SnowBallEngineDemo
//
//  Created by Liu Xudong on 2024/7/4.
//

import UIKit
import StoreKit

import FirebaseAnalytics
import GoogleMobileAds
import SnowBallEngine

class ViewController: UIViewController {
	
	private var interstitial: InterstitialAd?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// TODO: 自行设置页面和逻辑
		// 模拟展示一个Admob广告
		loadAdmobInterstitialAd()
		// TODO: 模拟发起内购
	}
	
	// 设置并加载插屏广告
	private func loadAdmobInterstitialAd() {
		Task {
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
	}
}

// MARK: 模拟用户内购成功后
extension ViewController {
	
	private func purchaseSuccess(transaction: Transaction, scene: String?) {
		verifyPurchase(transaction: transaction, scene: scene)
		recordPurchaseRevenue(transaction: transaction, scene: scene)
	}
	
	// DEMO: 验证购买的订单
	private func verifyPurchase(transaction: Transaction, scene: String?) {
		Task {
			// TODO: App 安装后的第一次启动，设置设备的UUID，或使用其他已定义的设备ID
//			let uuid = UUID().uuidString.lowercased()
//			UserDefaults.standard.set(uuid, forKey: "deviceId")
			guard let bundleId = Bundle.main.bundleIdentifier,
				  let deviceId = UserDefaults.standard.value(forKey: "deviceId") as? String
			else {
				return
			}
			do {
				
				let dic = try await SnowBallStore.verify(bundleId: bundleId,
											   transationId: String(transaction.id),
											   productId: transaction.productID,
											   productType: transaction.productType,
											   deviceId: deviceId,
											   userInstanceId: Analytics.appInstanceID(),
											   scene: "custom_iap_scene")
				guard let dic = dic else {
					print("StoreServer.verify failed, wrong response")
					return
				}
				if let code = dic["code"] as? Int, code == 200,
				   let data = dic["data"] as? [String: Any]
				{
					print("StoreServer.verify, detail: \(data)")
				} else if let message = dic["message"] as? String {
					print("StoreServer.verify failed, message: \(message)")
				} else {
					print("StoreServer.verify failed, unknown reason")
				}
			} catch {
				print("StoreServer.verify failed," + error.localizedDescription)
			}
		}
	}
	
	// DEMO: 上传内购事件价值
	private func recordPurchaseRevenue(transaction: Transaction, scene: String?) {
		
		/*
		 方法1: 推荐使用订单信息上报
		 */
		Tracker.shared.trackPurchaseRevenue(transaction: transaction, scene: scene)
		/*
		 方法2: 根据订单信息自己解析后上报
		 */
		let currency: String? = {
			if #available(iOS 16.0, *) {
				return transaction.currency?.identifier
			} else {
				return transaction.currencyCode
			}
		}()
		
		guard let currency = currency,
			  let transactionPrice = transaction.price else {
			return
		}
		
		let isFreeTrial: Bool = {
			if #available(iOS 17.2, *) {
				return transaction.offer?.paymentMode == .freeTrial
			} else {
				return transaction.offerPaymentModeStringRepresentation == "freeTrial"
			}
		}()
		
		let productId = transaction.productID
		let transactionPriceInDouble = NSDecimalNumber(decimal: transactionPrice).doubleValue
		
		let isSubscription = transaction.productType == .autoRenewable || transaction.productType == .nonRenewable
		
		if isSubscription {
//			e.g.(productId: "com.xxx.weekly",currency: "HKD",price: 9.9,isFreeTrial: false, scene: "CustomScene")
			Tracker.shared.trackSubsPurchaseRevenue(productId: productId,
													currency: currency,
													price: transactionPriceInDouble,
													isFreeTrial: isFreeTrial,
													scene: scene)
		} else {
//			e.g.(productId: "com.xxx.lifetime", currency: "USD", price: 59.0, scene: "CustomScene")
			Tracker.shared.trackInAppPurchaseRevenue(productId: productId,
													 currency: currency,
													 price: transactionPriceInDouble,
													 scene: scene)
		}
	}
	
}

// MARK: 模拟用户加载展示广告后，回传价值
extension ViewController {
    
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

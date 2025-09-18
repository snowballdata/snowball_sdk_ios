//
//  Tracker + Purchase.swift
//  SnowBallEngine
//
//  Created by XuDong Liu on 2025/3/6.
//

import Foundation
import StoreKit
import Adjust

extension Tracker {
    
	/*
	 记录上传，刚刚购买成功的交易订单，或有效的交易订单
	 */
	public func trackPurchaseRevenue(transaction: Transaction,
                                     scene: String?) {
        
        let currency: String? = {
            if #available(iOS 16.0, *) {
				return transaction.currency?.identifier
            } else {
                return transaction.currencyCode
            }
        }()
		
        guard let currency = currency,
              let transactionPrice = transaction.price
        else {
            return
        }
		
		let isFreeTrial: Bool = {
			if #available(iOS 17.2, *) {
				return transaction.offer?.paymentMode == .freeTrial
			} else {
				return transaction.offerPaymentModeStringRepresentation == "freeTrial"
			}
		}()
		
		let isSubscription = transaction.productType == .autoRenewable || transaction.productType == .nonRenewable
		
		let transactionPriceDouble = NSDecimalNumber(decimal: transactionPrice).doubleValue
        let transactionPriceString = "\(transactionPrice)_\(transactionPrice.exponent)"
		let value = isFreeTrial ? 0 : transactionPriceDouble
        let parameters: [String : Any] = ["currency": currency,
                                          "value": value,
                                          "value_string": transactionPriceString,
                                          "product_id": transaction.productID,
                                          "subscription": isSubscription ? 1 : 0,
                                          "free_trial": isFreeTrial ? 1 : 0,
                                          "scene": scene ?? "Unknown"
        ]
        Tracker.logEvent(Events.SE_InAppPurchase, parameters: parameters)
		self.trackAdjust(currency: currency, price: value)
    }

	/*
	 记录非订阅类购买，例如消耗性商品或永久会员，ProductType 为 consumable 或 nonConsumable
	 */
    public func trackInAppPurchaseRevenue(productId: String,
                                          currency: String,
                                          price: Double,
                                          scene: String?) {
        let parameters: [String : Any] = ["currency": currency,
                                          "value":  price,
                                          "product_id": productId,
                                          "subscription": 0,
                                          "free_trial": 0,
                                          "scene": scene ?? "Unknown"
        ]
        Tracker.logEvent(Events.SE_InAppPurchase, parameters: parameters)
		self.trackAdjust(currency: currency, price: price)
    }
	
	/*
	 记录订阅类购买，例如自动或非自动续费型订阅，ProductType 为 autoRenewable 或 nonRenewable
	 */
    public func trackSubsPurchaseRevenue(productId: String,
                                         currency: String,
                                         price: Double,
                                         isFreeTrial: Bool,
                                         scene: String?) {
        let parameters: [String : Any] = ["currency": currency,
                                          "value":  isFreeTrial ? 0 : price,
                                          "product_id": productId,
                                          "subscription": 1,
                                          "free_trial": isFreeTrial ? 1 : 0,
                                          "scene": scene ?? "Unknown"
        ]
        Tracker.logEvent(Events.SE_InAppPurchase, parameters: parameters)
		self.trackAdjust(currency: currency, price: price)
    }
    
	private func trackAdjust(currency: String,
							 price: Double) {
		guard let token = self.adjustAppPurchaseToken,
			  token.count > 0,
			  let event = ADJEvent(eventToken: token)
		else { return }
		
		event.setRevenue(price, currency: currency)
		Adjust.trackEvent(event)
	}
}

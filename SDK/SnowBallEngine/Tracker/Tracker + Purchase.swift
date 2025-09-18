//
//  Tracker + Purchase.swift
//  SnowBallEngine
//
//  Created by XuDong Liu on 2025/3/6.
//

import Foundation
import StoreKit

extension Tracker {
    
    @available(iOS 15.0, *)
    public func trackPurchaseRevenue(transaction: Transaction,
                                     product: Product,
                                     scene: String?) {
        let productId = transaction.productID
        guard productId == product.id else {
            Tracker.log.e("The product in transation (\(productId)) is not equal to the product id(\(product.id))")
            return
        }
        let isFreeTrial: Bool = {
            if #available(iOS 17.2, *) {
                transaction.offer?.type == .introductory
            } else {
                transaction.offerType == .introductory
            }
        }()
        
        let isSubscription = transaction.productType == .autoRenewable || transaction.productType == .nonRenewable
        
        let productPriceInDouble: Double = NSDecimalNumber(decimal: product.price).doubleValue
        let currency: String? = {
            if #available(iOS 16.0, *) {
                //                transaction.currency?.identifier
                return product.priceFormatStyle.locale.currency?.identifier
            } else {
                //                transaction.currencyCode
                return product.priceFormatStyle.locale.currencyCode
            }
        }()
        guard let currency = currency,
              let transactionPrice = transaction.price
        else {
            return
        }
        let transactionPriceString = "\(transactionPrice)_\(transactionPrice.exponent)"
        let parameters: [String : Any] = ["currency": currency,
                                          "value":  isFreeTrial ? 0 : productPriceInDouble,
                                          "value_string": transactionPriceString,
                                          "product_id": productId,
                                          "subscription": isSubscription ? 1 : 0,
                                          "free_trial": isFreeTrial ? 1 : 0,
                                          "scene": scene ?? "Unknown"
        ]
        Tracker.logEvent(Events.THInAppPurchase, parameters: parameters)
    }
    
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
        Tracker.logEvent(Events.THInAppPurchase, parameters: parameters)
    }
    
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
        Tracker.logEvent(Events.THInAppPurchase, parameters: parameters)
    }
    
}

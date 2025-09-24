//
//  Server.swift
//  ThLibIAP
//
//  Created by Liu Xudong on 2023/12/12.
//

import Foundation
import StoreKit

public class StoreServer {
	
	private static let log = Log(type: StoreServer.self)
	
	private static var baseServerUrl: String {
#if DEBUG
		"https://account-test.thinkyeah.com/api"
#else
		"https://account.thinkyeah.com/api"
#endif
	}
	
	private static var verifyUrl: String {
		baseServerUrl + "/purchase/verify"
	}
	
	/*
	 deviceId: 一次App安装周期内唯一且不变。一般的生成方式为 UUID().uuidString.lowercased(), 存到本地后继续使用；
	 userInstanceId: 生成方式为 Analytics.appInstanceID()；
	 */
	public static func verify(bundleId: String,
							  transationId: String,
							  productId: String,
							  productType: Product.ProductType,
							  deviceId: String,
							  userInstanceId: String?,
							  scene: String?) async throws -> [String: Any]? {
		
		guard let requestUrl = URL(string: verifyUrl) else {
			StoreServer.log.e("Invalid URL: \(verifyUrl)")
			return nil
		}
		var pa = [
			"platform": "ios",
			"market": "appstore",
			"type": (productType == .autoRenewable || productType == .nonRenewable) ? "subs" : "iap",
			"package_name": bundleId,
			"purchase_token": transationId,
			"sku_id": productId,
			"adid": deviceId,
			"dcid": deviceId
		]
		if let scene = scene {
			pa["scene"] = scene
		}
		if let userInstanceId = userInstanceId {
			pa["firebase_user_id"] = userInstanceId
		}
		StoreServer.log.i("url: \(requestUrl), params: \(pa)")

		var request = URLRequest(url: requestUrl)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let jsonData = try JSONSerialization.data(withJSONObject: pa, options: [])
		request.httpBody = jsonData

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			StoreServer.log.e("Invalid response type")
			return nil
		}

		guard httpResponse.statusCode == 200 else {
			StoreServer.log.e("HTTP error: \(httpResponse.statusCode)")
			return nil
		}

		let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

		StoreServer.log.d("get JSON: \(jsonObject, default: "nil")")
		return jsonObject
	}
}

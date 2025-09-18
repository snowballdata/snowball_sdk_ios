//
//  LocalEx.swift
//  SnowBallEngine
//
//  Created by Liu Xudong on 2023/12/5.
//

import Foundation

public extension Locale {
	
	func language(withRegion: Bool = true) -> String {
		let identifier = self.identifier // maybe en, en_US, zh-Hans_US
		if identifier.lowercased().starts(with: "zh-hant") {
			return "zh_TW"
		}
		
		if identifier.lowercased().starts(with: "zh-hans") {
			return "zh_CN"
		}
		
		let parts = identifier.split(separator: "_")
		guard parts.count >= 1 else {
			return "en"
		}

		var lang = String(parts[0])
		var region: String? = nil
		if parts.count >= 2 {
			region = String(parts[1])
		}
		
		let langParts = lang.split(separator: "-")
		guard langParts.count >= 1 else {
			return "en"
		}
		
		if langParts.count > 1 {
			lang = String(langParts[0])
		}
		
		if withRegion && region != nil {
			return "\(lang)_\(region!)"
		}
		return lang
	}
}

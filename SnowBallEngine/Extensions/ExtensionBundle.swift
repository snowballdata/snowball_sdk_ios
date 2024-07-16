import UIKit

extension Bundle {
	
	public var displayName: String? {
		return self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
	}
	
	public var bundleName: String? {
		return self.object(forInfoDictionaryKey: "CFBundleName") as? String
	}
	
	public var version: Int {
		Int(self.infoDictionary?["CFBundleVersion"] as? String ?? "") ?? 0
	}
	
	public var shortVersionString: String? {
		self.infoDictionary?["CFBundleShortVersionString"] as? String
	}
	
	public var buildDate: Date? {
		if let infoPath = self.path(forResource: "Info", ofType: "plist"),
			let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
			let infoDate = infoAttr[.modificationDate] as? Date {
			return infoDate
		}
		return nil
	}
}


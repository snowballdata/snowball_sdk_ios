Pod::Spec.new do |spec|

  spec.name         = "SnowBallEngine"
  spec.version      = "0.1"
  spec.summary      = "SnowBall SDK 提供了事件打点、远程推送、买量安装归因和广告价值上报功能。
  SDK 事件发送基于 Firebase Analytics，远程推送功能基于 Firebase Messaging 库。
  归因回传和广告价值上报基于 Firebase 事件上报到 Firebase BigQuery 事件集。
  SnowBall 平台系统基于 BigQuery 查询事件数据，进行各部分业务处理。 "

  spec.description  = <<-DESC 
1. SnowBallTracker
2. SnowBallPush
                   DESC

  spec.homepage     = "https://thinkyeah.com"
  spec.license      = { :type => "MIT", :file => "LICENSE.txt" }
  spec.author       = { "SnowBall BI" => "sdk@snowballbi.com" }
  spec.ios.deployment_target = "15.0"
  spec.source       = { :git => "https://github.com/snowballdata/snowball_sdk_ios.git", :tag => "#{spec.version}" }
  spec.source_files = [
    "SnowBallEngine/Extensions/*.{swift}",
    "SnowBallEngine/Log/*.{swift}",
		"SnowBallEngine/*.{swift}",
		"SnowBallEngine/Tracker/*.{swift}"
  ]

  spec.static_framework = true
  spec.dependency "CocoaLumberjack/Swift"
	spec.dependency "Firebase/Analytics"
  spec.swift_versions = ["5"]

  # Push
  spec.subspec 'Push' do |ss|
    ss.source_files   = ["SnowBallEngine/Push/*.{swift}"]
    ss.dependency "Firebase/Messaging"
  end
end

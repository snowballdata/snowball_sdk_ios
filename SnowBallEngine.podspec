Pod::Spec.new do |spec|

  spec.name         = "SnowBallEngine"
  spec.version      = "1.0"
  spec.homepage     = "https://thinkyeah.com"
  spec.license      = { :type => "MIT", :file => "LICENSE.txt" }
  spec.author       = { "Snowball BI" => "snowballbi@thinkyeah.com" }
  spec.summary      = "SnowBall SDK 包含 SnowBallTracker 和 SnowBallPush"
  spec.description  = <<-DESC 
  SnowBall SDK 提供了事件打点、远程推送、买量安装归因和广告价值上报功能。
  SDK 事件发送基于 Firebase Analytics，远程推送功能基于 Firebase Messaging。
  归因回传和广告价值上报基于 Firebase 事件上报到 Firebase BigQuery 事件集。
  SnowBall 平台系统基于 BigQuery 查询事件数据，进行各部分业务处理。
                   DESC

  spec.ios.deployment_target = "15.6"
  spec.source       = { :git => "https://github.com/snowballdata/snowball_sdk_ios.git", :tag => "#{spec.version}" }
  spec.source_files = [
    "SnowBallEngine/Extensions/*.{swift}",
    "SnowBallEngine/Log/*.{swift}",
    "SnowBallEngine/*.{swift}",
    "SnowBallEngine/Tracker/*.{swift}",
    "SnowBallEngine/Push/*.{swift}"
  ]

  spec.static_framework = true
  spec.dependency "CocoaLumberjack/Swift", '>= 3.8.5'
  spec.dependency "Firebase/Analytics", '>= 12.1.0'
  spec.dependency "Firebase/Messaging", '>= 12.1.0'
	spec.dependency 'Adjust', '~> 4.36.0'
  spec.swift_versions = ["5"]
end

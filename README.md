# SnowBallEngine

一个强大的 iOS 分析和推送 SDK,支持 Firebase Analytics、Firebase Messaging 和 Adjust 集成。

**🔒 二进制分发 - 源码完全不暴露**

## 特性

- 📊 **事件追踪** - Firebase Analytics 集成
- 📱 **推送通知** - Firebase Cloud Messaging
- 💰 **广告归因** - Adjust SDK 集成
- 🛍️ **应用内购买追踪** - 完整的购买验证支持
- 🔐 **源码保护** - 编译为二进制 XCFramework

## 快速开始

### 安装

#### 使用 Swift Package Manager

在 Xcode 中:

1. File → Add Package Dependencies
2. 输入仓库 URL: `https://github.com/YOUR_ORG/snowball_sdk_ios.git`
3. 选择版本
4. 添加 `SnowBallEngine` 产品

或在 `Package.swift` 中:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_ORG/snowball_sdk_ios.git", from: "1.2.0")
]
```

### 使用

```swift
import SnowBallEngine

// 初始化
SnowBall.setup(
    adjustAppPurchaseToken: "YOUR_TOKEN",
    adjustAdRevenueToken: "YOUR_TOKEN",
    adjustAdTotalRevenueToken: "YOUR_TOKEN"
)

// 日志等级设置
Log.setup(level: .debug)

// 事件追踪
Tracker.shared.logEvent("user_signup", parameters: [
    "method": "email",
    "user_id": "12345"
])

// 推送通知
Push.shared.requestAuthorization()
```

## 要求

- iOS 15.6+
- Xcode 16.0+
- Swift 5.9+

## 依赖

SDK 自动包含以下依赖(无需手动添加):

- Firebase Analytics (12.1.0+)
- Firebase Messaging (12.1.0+)
- Adjust SDK (4.36.0+)

## 文档

- [📖 快速开始指南](QUICK_START.md) - 5分钟上手
- [🔨 本地分发指南](LOCAL_XCFRAMEWORK_GUIDE.md) - 本地 XCFramework 配置
- [🚀 远程分发指南](BINARY_DISTRIBUTION.md) - GitHub Release 配置

## API 概览

### SnowBall

```swift
// 初始化配置
SnowBall.setup(
    adjustAppPurchaseToken: String?,
    adjustAdRevenueToken: String?,
    adjustAdTotalRevenueToken: String?
)
```

### Tracker

```swift
// 事件追踪
Tracker.shared.logEvent(_ eventName: String, parameters: [String: Any]? = nil)

// 设置 Adjust token
Tracker.shared.setup(
    adjustAppPurchaseToken: String?,
    adjustAdRevenueToken: String?,
    adjustAdTotalRevenueToken: String?
)
```

### Push

```swift
// 请求推送权限
Push.shared.requestAuthorization()

// 获取 FCM token
Push.shared.getFCMToken()
```

### Log

```swift
// 设置日志等级
Log.setup(level: .debug) // .verbose, .debug, .info, .warning, .error

// 使用
let log = Log(type: YourClass.self)
log.d("Debug message")
log.i("Info message")
log.w("Warning message")
log.e("Error message")
```

## 版本历史

### 1.2.0 (2024-10-11)
- ✅ 二进制 XCFramework 分发
- ✅ Firebase 12.1.0 支持
- ✅ Adjust 4.36.0 支持
- ✅ 完整的应用内购买验证

## 开发

### 构建 XCFramework

```bash
# 1. 克隆仓库
git clone https://github.com/YOUR_ORG/snowball_sdk_ios.git

# 2. 运行构建脚本
./build_binary_framework.sh

# 3. XCFramework 会生成在 build/ 目录
```

### 项目结构

```
snowball_sdk_ios/
├── Package.swift                    # SPM 配置
├── SnowBallEngine.xcframework/      # 二进制产物
├── Sources/
│   └── SnowBallEngineWrapper/       # 依赖包装
├── SnowBallEngine/                  # 源码(私有)
│   ├── SnowBallEngine.xcodeproj
│   └── SnowBallEngine/
│       ├── SnowBall.swift
│       ├── Tracker/
│       ├── Push/
│       ├── Log/
│       └── Store/
└── build_binary_framework.sh        # 构建脚本
```

## 许可证

MIT License - 详见 [LICENSE.txt](LICENSE.txt)

## 支持

- 🐛 Issues: [GitHub Issues](https://github.com/YOUR_ORG/snowball_sdk_ios/issues)

---

**Made with ❤️ by Your Team**

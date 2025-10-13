# TestSDK Swift Package Manager 使用指南

## 📦 项目结构说明

```
TestSDK/
├── Package.swift                    # SPM 配置文件
├── TestSDK.xcframework/             # 预编译的二进制框架
│   ├── Info.plist
│   ├── ios-arm64/                   # 真机架构
│   └── ios-arm64_x86_64-simulator/  # 模拟器架构
└── Sources/
    └── TestSDKWrapper/              # 依赖包装层
        └── TestSDKWrapper.swift     # 占位符文件
```

## ⚠️ 重要说明:为什么需要在 Package.swift 中声明 Firebase 依赖?

**必须声明!** 因为:

1. **编译时链接**: 你的 TestSDK.xcframework 在编译时链接了 FirebaseAnalytics 和 FirebaseMessaging
2. **符号依赖**: XCFramework 包含对 Firebase 符号的引用
3. **运行时需要**: 如果不声明依赖,使用者的 App 会因为找不到 Firebase 符号而崩溃

### Package.swift 配置说明

```swift
// 1️⃣ 声明 Firebase 依赖
dependencies: [
    .package(
        url: "https://github.com/firebase/firebase-ios-sdk.git",
        from: "12.1.0"  // 必须匹配你编译 XCFramework 时使用的版本
    )
]

// 2️⃣ 二进制 Target - 你的 XCFramework
.binaryTarget(
    name: "TestSDK",
    path: "TestSDK.xcframework"  // 本地路径
)

// 3️⃣ Wrapper Target - 连接二进制和依赖
.target(
    name: "TestSDKWrapper",
    dependencies: [
        "TestSDK",  // 你的二进制框架
        .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
    ]
)
```

## 🚀 发布到 Git

### 1. 提交代码

```bash
# 添加所有文件
git add Package.swift
git add TestSDK.xcframework
git add Sources/TestSDKWrapper/

# 提交
git commit -m "feat: Add SPM support with Firebase dependencies"

# 推送到远程仓库
git push origin main
```

### 2. 创建版本标签

```bash
# 创建标签
git tag 1.0.0

# 推送标签
git push origin 1.0.0
```

## 👥 使用者如何集成

### 方式 1: 在 Xcode 中添加

1. 打开项目
2. **File → Add Package Dependencies...**
3. 输入你的仓库 URL: `https://github.com/YOUR_USERNAME/TestSDK.git`
4. 选择版本: `1.0.0` 或 `Up to Next Major Version`
5. 点击 **Add Package**
6. 选择 **TestSDK** 产品

### 方式 2: 在 Package.swift 中添加

```swift
let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/YOUR_USERNAME/TestSDK.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["TestSDK"]
        )
    ]
)
```

## 📱 使用示例

```swift
import TestSDK
import FirebaseCore  // 使用者需要在 AppDelegate 中配置 Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 1. 初始化 Firebase (必须!)
        FirebaseApp.configure()

        // 2. 使用 TestSDK
        // ... 你的 SDK 初始化代码 ...

        return true
    }
}
```

## 🔍 依赖版本说明

| 依赖库 | 版本要求 | 说明 |
|--------|---------|------|
| FirebaseAnalytics | 12.1.0+ | 必须依赖,用于事件追踪 |
| FirebaseMessaging | 12.1.0+ | 必须依赖,用于推送通知 |
| iOS | 15.0+ | 最低系统要求 |
| Swift | 5.9+ | 最低编译器版本 |

## ⚡️ 远程 XCFramework 托管 (可选)

如果你的 XCFramework 太大,可以托管在 GitHub Release 上:

```swift
.binaryTarget(
    name: "TestSDK",
    url: "https://github.com/YOUR_USERNAME/TestSDK/releases/download/1.0.0/TestSDK.xcframework.zip",
    checksum: "计算的 checksum"
)
```

计算 checksum:
```bash
swift package compute-checksum TestSDK.xcframework.zip
```

## ❓ 常见问题

### Q1: 使用者是否需要手动添加 Firebase?
**不需要!** SPM 会自动下载 Firebase 依赖。

### Q2: 如果我的 XCFramework 还依赖其他库怎么办?
在 `dependencies` 数组中添加,并在 `TestSDKWrapper` target 的 `dependencies` 中声明。

### Q3: 为什么需要 TestSDKWrapper?
因为 `.binaryTarget` 不能直接声明依赖,需要一个 wrapper target 来桥接。

### Q4: 可以不使用 Wrapper 吗?
不可以。这是 SPM 对二进制框架的限制。

## 📚 参考资料

- [Swift Package Manager 官方文档](https://swift.org/package-manager/)
- [Firebase iOS SDK SPM 集成](https://github.com/firebase/firebase-ios-sdk)
- [Apple: Distributing Binary Frameworks](https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages)

## 🎉 完成!

你的 TestSDK 现在已经可以通过 SPM 分发了!使用者只需要添加你的 Package,SPM 会自动处理所有依赖。

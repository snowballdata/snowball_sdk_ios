#!/bin/bash

# SnowBallEngine 二进制 Framework 构建脚本
# 此脚本将源码编译为二进制 XCFramework,不暴露源码

set -e

# 配置参数
FRAMEWORK_NAME="SnowBallEngine"
PROJECT_NAME="SnowBallEngine"
PROJECT_DIR="$(pwd)"
PROJECT_PATH="${PROJECT_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.xcodeproj"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVES_DIR="${BUILD_DIR}/archives"
XCFRAMEWORK_OUTPUT="${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"
ZIP_OUTPUT="${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework.zip"

# 清理之前的构建
echo "🧹 清理之前的构建..."
rm -rf "${BUILD_DIR}"
mkdir -p "${ARCHIVES_DIR}"

# 检查项目文件是否存在
if [ ! -d "${PROJECT_PATH}" ]; then
    echo "❌ 错误: 找不到项目文件 ${PROJECT_PATH}"
    exit 1
fi

echo "⚙️  此脚本需要你先在 Xcode 中添加 Firebase 和 Adjust 依赖"
echo "📝 打开 ${PROJECT_PATH} 并添加以下 SPM 依赖:"
echo "   - https://github.com/firebase/firebase-ios-sdk.git"
echo "   - https://github.com/adjust/ios_sdk.git"
echo ""
read -p "是否已添加依赖? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 请先添加依赖后再运行此脚本"
    exit 1
fi

# 确保 Scheme 是共享的
SHARED_SCHEMES_DIR="${PROJECT_PATH}/xcshareddata/xcschemes"
if [ ! -d "${SHARED_SCHEMES_DIR}" ]; then
    echo "⚠️  Scheme 未共享,正在创建共享 Scheme..."
    mkdir -p "${SHARED_SCHEMES_DIR}"
    USER_SCHEME_PATH=$(find "${PROJECT_PATH}/xcuserdata" -name "SnowBallEngine.xcscheme" | head -1)
    if [ -n "${USER_SCHEME_PATH}" ]; then
        cp "${USER_SCHEME_PATH}" "${SHARED_SCHEMES_DIR}/"
        echo "✅ Scheme 已共享"
    else
        echo "⚠️  未找到用户 Scheme,将尝试继续构建..."
    fi
fi

# iOS 设备架构
echo "📱 构建 iOS 设备版本..."
xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "SnowBallEngine" \
    -destination "generic/platform=iOS" \
    -archivePath "${ARCHIVES_DIR}/ios.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=staticlib

# iOS 模拟器架构
echo "🖥️ 构建 iOS 模拟器版本..."
xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "SnowBallEngine" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${ARCHIVES_DIR}/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=staticlib

# 验证 archive 是否成功创建
echo "🔍 验证 archive..."
IOS_FRAMEWORK_PATH="${ARCHIVES_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
SIMULATOR_FRAMEWORK_PATH="${ARCHIVES_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"

if [ ! -d "${IOS_FRAMEWORK_PATH}" ]; then
    echo "❌ 错误: iOS framework 未找到于 ${IOS_FRAMEWORK_PATH}"
    echo "尝试查找实际路径..."
    find "${ARCHIVES_DIR}/ios.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d
    exit 1
fi

if [ ! -d "${SIMULATOR_FRAMEWORK_PATH}" ]; then
    echo "❌ 错误: 模拟器 framework 未找到于 ${SIMULATOR_FRAMEWORK_PATH}"
    echo "尝试查找实际路径..."
    find "${ARCHIVES_DIR}/ios-simulator.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d
    exit 1
fi

echo "✅ Archive 验证成功"

# 创建 XCFramework
echo "🔨 创建 XCFramework..."
xcodebuild -create-xcframework \
    -framework "${IOS_FRAMEWORK_PATH}" \
    -framework "${SIMULATOR_FRAMEWORK_PATH}" \
    -output "${XCFRAMEWORK_OUTPUT}"

if [ $? -ne 0 ]; then
    echo "❌ XCFramework 创建失败"
    exit 1
fi

echo "✅ XCFramework 创建成功"

# 创建 zip 包
echo "📦 创建 zip 包..."
cd "${BUILD_DIR}"
zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
cd "${PROJECT_DIR}"

# 计算校验和
echo "🔍 计算校验和..."
cd "${BUILD_DIR}"
shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" | cut -d ' ' -f 1 > "${FRAMEWORK_NAME}.xcframework.zip.sha256.txt"
CHECKSUM=$(cat "${FRAMEWORK_NAME}.xcframework.zip.sha256.txt")
cd "${PROJECT_DIR}"

echo ""
echo "✅ 构建完成！"
echo "📍 XCFramework 位置: ${XCFRAMEWORK_OUTPUT}"
echo "📍 ZIP 包位置: ${ZIP_OUTPUT}"
echo "📍 SHA256: ${CHECKSUM}"
echo ""
echo "📊 文件信息:"
du -h "${XCFRAMEWORK_OUTPUT}"
du -h "${ZIP_OUTPUT}"
echo ""

# 询问是否复制到项目根目录
read -p "是否将 XCFramework 复制到项目根目录用于本地分发? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📋 复制 XCFramework 到项目根目录..."
    rm -rf "${PROJECT_DIR}/${FRAMEWORK_NAME}.xcframework"
    cp -R "${XCFRAMEWORK_OUTPUT}" "${PROJECT_DIR}/"
    echo "✅ 已复制到: ${PROJECT_DIR}/${FRAMEWORK_NAME}.xcframework"
    echo ""
    echo "📝 本地分发配置 (Package.swift):"
    echo ""
    echo ".binaryTarget("
    echo "    name: \"${FRAMEWORK_NAME}\","
    echo "    path: \"${FRAMEWORK_NAME}.xcframework\""
    echo ")"
    echo ""
    echo "💡 提示: 使用 Package_Local.swift.template 作为模板"
else
    echo ""
    echo "📝 远程分发步骤:"
    echo "1. 将 ${FRAMEWORK_NAME}.xcframework.zip 上传到 GitHub Release"
    echo "2. 使用以下 Package.swift 配置:"
    echo ""
    echo ".binaryTarget("
    echo "    name: \"${FRAMEWORK_NAME}\","
    echo "    url: \"https://github.com/YOUR_ORG/YOUR_REPO/releases/download/VERSION/${FRAMEWORK_NAME}.xcframework.zip\","
    echo "    checksum: \"${CHECKSUM}\""
    echo ")"
fi

echo ""
echo "⚠️  注意: 用户需要同时添加 Firebase 和 Adjust 依赖"

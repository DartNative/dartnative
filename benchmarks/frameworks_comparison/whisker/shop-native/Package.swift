// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "shop-native",
    platforms: [.iOS(.v13), .macOS(.v13)],
    products: [
        .library(name: "ShopNative", targets: ["ShopNative"]),
    ],
    dependencies: [
        .package(url: "https://github.com/whiskerrs/whisker.git", exact: "0.1.20"),
    ],
    targets: [
        .target(
            name: "ShopNative",
            dependencies: [
                .product(name: "WhiskerModule", package: "whisker"),
            ],
            path: "ios/Sources/ShopNative",
            plugins: [
                .plugin(name: "WhiskerModuleCodegenPlugin", package: "whisker"),
            ]
        ),
    ]
)

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OurMoney",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "OurMoney",
            targets: ["OurMoney"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "OurMoney",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "OurMoney"
        ),
        .testTarget(
            name: "OurMoneyTests",
            dependencies: ["OurMoney"],
            path: "OurMoneyTests"
        )
    ]
)

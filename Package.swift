// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Bolhoed",
  platforms: [
    .macOS(.v14),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "3.8.1"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaUtils", from: "1.0.2"),
    .package(url: "https://github.com/loopwerk/SagaImageReader", from: "1.4.0"),
    .package(url: "https://github.com/loopwerk/Bonsai", from: "1.1.0"),
    .package(url: "https://github.com/loopwerk/SwiftTailwind", from: "1.0.0"),
    .package(url: "https://github.com/swiftcsv/SwiftCSV", from: "0.8.0"),
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.0.0")
  ],
  targets: [
    .executableTarget(
      name: "Bolhoed",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "SagaUtils",
        "SagaImageReader",
        "Bonsai",
        "SwiftTailwind",
        "SwiftCSV",
        .product(name: "SwiftDotenv", package: "swift-dotenv"),
      ],
      exclude: ["csv"]
    ),
  ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClassGodHelper",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClassGodHelper",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "ClassGodHelperTests"
        )
    ]
)

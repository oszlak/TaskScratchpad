// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskScratchpad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TaskScratchpad", targets: ["TaskScratchpad"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TaskScratchpad",
            path: "Sources/TaskScratchpad"
        ),
        .target(
            name: "TaskScratchpadCore",
            path: "Sources/TaskScratchpadCore"
        ),
        .testTarget(
            name: "TaskScratchpadTests",
            dependencies: ["TaskScratchpadCore"],
            path: "Tests/TaskScratchpadTests"
        )
    ]
)

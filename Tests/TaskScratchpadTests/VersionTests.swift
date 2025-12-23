import Testing
@testable import TaskScratchpadCore

@Suite("Version")
struct VersionTests {

    @Test("Version is semantic versioning format")
    func versionFormat() {
        let version = AppVersion.version
        let components = version.split(separator: ".")

        #expect(components.count == 3, "Version should have 3 components (major.minor.patch)")

        for component in components {
            #expect(Int(component) != nil, "Each version component should be a number")
        }
    }

    @Test("Build number is valid")
    func buildNumber() {
        let build = AppVersion.build
        #expect(Int(build) != nil, "Build should be a number")
        #expect(Int(build)! >= 1, "Build should be at least 1")
    }

    @Test("Bundle identifier is valid format")
    func bundleIdentifier() {
        let bundleId = AppVersion.bundleIdentifier
        let components = bundleId.split(separator: ".")

        #expect(components.count >= 2, "Bundle ID should have at least 2 components")
        #expect(!bundleId.hasPrefix("."), "Bundle ID should not start with a dot")
        #expect(!bundleId.hasSuffix("."), "Bundle ID should not end with a dot")
    }

    @Test("Current version is 0.0.2")
    func currentVersion() {
        #expect(AppVersion.version == "0.0.2")
    }
}


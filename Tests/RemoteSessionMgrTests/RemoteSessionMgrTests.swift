import XCTest
@testable import RemoteSessionMgr

final class RemoteSessionMgrTests: XCTestCase {
    func testSampleDataContainsExpectedProtocols() {
        let library = SampleData.makeLibrary()
        let root = library.rootFolder

        let allProtocols = root.folders
            .flatMap(\.sessions)
            .map(\.protocolType)

        XCTAssertTrue(allProtocols.contains(.ssh))
        XCTAssertTrue(allProtocols.contains(.rdp))
    }

    func testSettingsDefaultsMatchExpectedLaunchers() {
        XCTAssertEqual(AppSettings.default.defaultSSHLauncher, .terminal)
        XCTAssertTrue(AppSettings.default.rdpCommandTemplate.contains("{host}"))
    }
}

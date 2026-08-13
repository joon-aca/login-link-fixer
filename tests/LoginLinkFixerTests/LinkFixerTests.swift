import XCTest
@testable import LoginLinkFixerCore

final class LinkFixerTests: XCTestCase {
    private let url = "https://claude.com/cai/oauth/authorize?code=true&client_id=abc&scope=user%3Aprofile+user%3Ainference&state=xyz"

    func testCleanURLPassesThrough() throws {
        XCTAssertEqual(try LinkFixer.clean(url).absoluteString, url)
    }

    func testRemovesLineBreaksAndSpaces() throws {
        let broken = "https://claude.com/cai/oauth/authorize?code=true&client_id=abc\n&scope=user%3Aprofile+\n user%3Ainference&state=xyz"
        XCTAssertEqual(try LinkFixer.clean(broken).absoluteString, url)
    }

    func testExtractsMarkdownTarget() throws {
        let markdown = "[broken visible link](\(url))"
        XCTAssertEqual(try LinkFixer.clean(markdown).absoluteString, url)
    }

    func testDecodesEscapedAmpersands() throws {
        XCTAssertEqual(
            try LinkFixer.clean("https://example.com/?a=1&amp;b=2").absoluteString,
            "https://example.com/?a=1&b=2"
        )
    }

    func testRejectsNonWebInput() {
        XCTAssertThrowsError(try LinkFixer.clean("not a link"))
    }
}

//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@testable import SignalUI

final class CallLinkTest: XCTestCase {
    private func parse(_ urlString: String) -> CallLink? {
        return CallLink(url: URL(string: urlString)!)
    }

    func testUrlString() {
        XCTAssertNil(parse("https://link.baxs.com/call/#key=bcdf-ghkm-npqr-stxz-bcdf-ghkm-npqr-stx"))
        XCTAssertNil(parse("http://link.baxs.com/call/#key=bcdf-ghkm-npqr-stxz-bcdf-ghkm-npqr-stxz"))
        XCTAssertNil(parse("https://sticker.baxs.com/call/#key=bcdf-ghkm-npqr-stxz-bcdf-ghkm-npqr-stxz"))
        XCTAssertNil(parse("https://link.baxs.com/c/#key=bcdf-ghkm-npqr-stxz-bcdf-ghkm-npqr-stxz"))
    }

    func testRoundtrip() throws {
        let urlString = "https://link.baxs.com/call/#key=bcdf-ghkm-npqr-stxz-bcdf-ghkm-npqr-stxz"
        let callLink = try XCTUnwrap(parse(urlString))
        XCTAssertEqual(callLink.url().absoluteString, urlString)
    }

    func testGenerate() {
        let url1 = CallLink.generate().url()
        let url2 = CallLink.generate().url()
        XCTAssertNotEqual(url1, url2)
    }
}

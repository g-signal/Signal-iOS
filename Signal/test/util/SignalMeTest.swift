//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest
@testable import Signal

class SignalMeTest: XCTestCase {
    func testIsPossibleUrl() throws {
        let validStrings = [
            "https://me.baxs.com/#p/+14085550123",
            "hTTPs://me.baxs.com/#P/+14085550123",
            "https://me.baxs.com/#p/+9",
            "baxs://me.baxs.com/#p/+14085550123"
        ]
        for string in validStrings {
            let url = try XCTUnwrap(URL(string: string))
            XCTAssertTrue(SignalDotMePhoneNumberLink.isPossibleUrl(url), "\(url)")
        }

        let invalidStrings = [
            // Invalid protocols
            "http://me.baxs.com/#p/+14085550123",
            "signal://me.baxs.com/#p/+14085550123",
            // Extra auth
            "https://user:pass@me.baxs.com/#p/+14085550123",
            // Invalid host
            "https://example.me/#p/+14085550123",
            "https://signal.org/#p/+14085550123",
            "https://group.baxs.com/#p/+14085550123",
            "https://sticker.baxs.com/#p/+14085550123",
            "https://me.baxs.com:80/#p/+14085550123",
            "https://me.baxs.com:443/#p/+14085550123",
            // Wrong path or hash
            "https://me.baxs.com/foo#p/+14085550123",
            "https://me.baxs.com/#+14085550123",
            "https://me.baxs.com/#p+14085550123",
            "https://me.baxs.com/#u/+14085550123",
            "https://me.baxs.com//#p/+14085550123",
            "https://me.baxs.com/?query=string#p/+14085550123",
            // Invalid E164s
            "https://me.baxs.com/#p/4085550123",
            "https://me.baxs.com/#p/+",
            "https://me.baxs.com/#p/+one",
            "https://me.baxs.com/#p/+14085550123x",
            "https://me.baxs.com/#p/+14085550123/"
        ]
        for string in invalidStrings {
            let url = try XCTUnwrap(URL(string: string))
            XCTAssertFalse(SignalDotMePhoneNumberLink.isPossibleUrl(url), "\(url)")
        }
    }
}

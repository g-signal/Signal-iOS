//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import LibSignalClient
import XCTest
@testable import Signal

class DeviceProvisioningURLTest: XCTestCase {
    func testValid() {
        func isValid(_ provisioningURL: String) -> Bool {
            DeviceProvisioningURL(urlString: provisioningURL) != nil
        }

        XCTAssertFalse(isValid(""))
        XCTAssertFalse(isValid("baxs://linkdevice?uuid=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))
        XCTAssertFalse(isValid("baxs://linkdevice?pub_key=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))
        XCTAssertFalse(isValid("baxs://linkdevice/uuid=asd&pub_key=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))

        XCTAssertTrue(isValid("baxs://linkdevice?uuid=asd&pub_key=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))
    }

    func testPublicKey() throws {
        let url = try XCTUnwrap(DeviceProvisioningURL(urlString: "baxs://linkdevice?uuid=asd&pub_key=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))

        XCTAssertEqual(url.publicKey, try PublicKey(keyData: Data(repeating: 0, count: 32)))
    }

    func testEphemeralDeviceId() throws {
        let url = try XCTUnwrap(DeviceProvisioningURL(urlString: "baxs://linkdevice?uuid=asd&pub_key=BQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))

        XCTAssertEqual(url.ephemeralDeviceId, "asd")
    }
}

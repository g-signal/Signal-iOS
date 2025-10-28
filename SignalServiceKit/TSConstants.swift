//
// Copyright 2019 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

// MARK: -

import Foundation
public import LibSignalClient

public class TSConstants {

    private enum Environment {
        case production, staging
    }
    private static let environment: Environment = {
        // You can set "USE_STAGING=1" in your Xcode Scheme. This allows you to
        // prepare a series of commits without accidentally committing the change
        // to the environment.
        #if DEBUG
        if ProcessInfo.processInfo.environment["USE_STAGING"] == "1" {
            return .staging
        }
        #endif

        // If you do want to make a build that will always connect to staging,
        // change this value. (Scheme environment variables are only set when
        // launching via Xcode, so this approach is still quite useful.)
        return .production
    }()

    public static var isUsingProductionService: Bool {
        return environment == .production
    }

    // Never instantiate this class.
    private init() {}

    public static var legalTermsUrl: URL {
        URL(string: "\(textSecureCDN0ServerURL)/legal/index.html")!
    }
    public static let donateUrl = URL(string: "https://signal.org/donate/")!
    public static let appStoreUrl = URL(string: "https://itunes.apple.com/us/app/b-a/id6754267880?mt=8")!

    public static var mainServiceIdentifiedURL: String { shared.mainServiceIdentifiedURL }
    public static var mainServiceUnidentifiedURL: String { shared.mainServiceUnidentifiedURL }

    public static var textSecureCDN0ServerURL: String { shared.textSecureCDN0ServerURL }
    public static var textSecureCDN2ServerURL: String { shared.textSecureCDN2ServerURL }
    public static var textSecureCDN3ServerURL: String { shared.textSecureCDN3ServerURL }
    public static var storageServiceURL: String { shared.storageServiceURL }
    public static var sfuURL: String { shared.sfuURL }
    public static var sfuTestURL: String { shared.sfuTestURL }
    public static var svr2URL: String { shared.svr2URL }
    public static var registrationCaptchaURL: String { shared.registrationCaptchaURL }
    public static var challengeCaptchaURL: String { shared.challengeCaptchaURL }
    public static var kUDTrustRoot: String { shared.kUDTrustRoot }
    public static var updatesURL: String { shared.updatesURL }
    public static var updates2URL: String { shared.updates2URL }

    public static var censorshipFReflectorHost: String { shared.censorshipFReflectorHost }
    public static var censorshipGReflectorHost: String { shared.censorshipGReflectorHost }

    public static var serviceCensorshipPrefix: String { shared.serviceCensorshipPrefix }
    public static var cdn0CensorshipPrefix: String { shared.cdn0CensorshipPrefix }
    public static var cdn2CensorshipPrefix: String { shared.cdn2CensorshipPrefix }
    public static var cdn3CensorshipPrefix: String { shared.cdn3CensorshipPrefix }
    public static var storageServiceCensorshipPrefix: String { shared.storageServiceCensorshipPrefix }
    public static var svr2CensorshipPrefix: String { shared.svr2CensorshipPrefix }

    static var svr2Enclave: MrEnclave { shared.svr2Enclave }
    static var svr2PreviousEnclaves: [MrEnclave] { shared.svr2PreviousEnclaves }

    public static var applicationGroup: String { shared.applicationGroup }

    public static var serverPublicParams: Data { shared.serverPublicParams }
    public static var callLinkPublicParams: Data { shared.callLinkPublicParams }
    public static var backupServerPublicParams: Data { shared.backupServerPublicParams }

    public static let shared: TSConstantsProtocol = {
        switch environment {
        case .production:
            return TSConstantsProduction()
        case .staging:
            return TSConstantsStaging()
        }
    }()

    public static let libSignalEnv: Net.Environment = {
        switch environment {
        case .production:
            return .production
        case .staging:
            return .staging
        }
    }()
}

// MARK: -

public protocol TSConstantsProtocol: AnyObject {
    var mainServiceIdentifiedURL: String { get }
    var mainServiceUnidentifiedURL: String { get }
    var textSecureCDN0ServerURL: String { get }
    var textSecureCDN2ServerURL: String { get }
    var textSecureCDN3ServerURL: String { get }
    var storageServiceURL: String { get }
    var sfuURL: String { get }
    var sfuTestURL: String { get }
    var svr2URL: String { get }
    var registrationCaptchaURL: String { get }
    var challengeCaptchaURL: String { get }
    var kUDTrustRoot: String { get }
    var updatesURL: String { get }
    var updates2URL: String { get }

    var censorshipFReflectorHost: String { get }
    var censorshipGReflectorHost: String { get }

    var serviceCensorshipPrefix: String { get }
    var cdn0CensorshipPrefix: String { get }
    var cdn2CensorshipPrefix: String { get }
    var cdn3CensorshipPrefix: String { get }
    var storageServiceCensorshipPrefix: String { get }
    var svr2CensorshipPrefix: String { get }

    var svr2Enclave: MrEnclave { get }
    var svr2PreviousEnclaves: [MrEnclave] { get }

    var applicationGroup: String { get }

    var serverPublicParams: Data { get }
    var callLinkPublicParams: Data { get }
    var backupServerPublicParams: Data { get }
}

public struct MrEnclave: Equatable {
    public let dataValue: Data
    public let stringValue: String

    init(_ stringValue: StaticString) {
        self.stringValue = String(describing: stringValue)
        // This is a constant -- it should never fail to parse.
        self.dataValue = Data.data(fromHex: self.stringValue)!
        // All of our MrEnclave values are currently 32 bytes.
        owsPrecondition(self.dataValue.count == 32)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.dataValue == rhs.dataValue
    }
}

// MARK: - Production

public class TSConstantsProduction: TSConstantsProtocol {

    public init() {}

    public let mainServiceIdentifiedURL = "https://chat.ba-chat.com"
    public let mainServiceUnidentifiedURL = "https://chat.ba-chat.com"
    public let textSecureCDN0ServerURL = "https://cdn.ba-chat.com"
    public let textSecureCDN2ServerURL = "https://cdn2.ba-chat.com"
    public let textSecureCDN3ServerURL = "https://cdn3.ba-chat.com"
    public let storageServiceURL = "https://storage.ba-chat.com"
    public let sfuURL = "https://sfu.ba-chat.com"
    public let sfuTestURL = "https://sfu.ba-chat.com"
    public let svr2URL = "wss://svr2.ba-chat.com"
    public let registrationCaptchaURL = "https://captcha.ba-chat.com/registration/generate.html"
    public let challengeCaptchaURL = "https://captcha.ba-chat.com/challenge/generate.html"
    public let kUDTrustRoot = "Bd8hujwt+PY1jMqO5xC/8pmIuxwzwuX7ZjHKoJ2BVL4g"
    public let updatesURL = "https://updates2.ba-chat.com/static/badges"
    public let updates2URL = "https://updates2.ba-chat.com/static/badges"

    public let censorshipFReflectorHost = "reflector-signal.global.ssl.fastly.net"
    public let censorshipGReflectorHost = "reflector-nrgwuv7kwq-uc.a.run.app"

    public let serviceCensorshipPrefix = "service"
    public let cdn0CensorshipPrefix = "cdn"
    public let cdn2CensorshipPrefix = "cdn2"
    public let cdn3CensorshipPrefix = "cdn3"
    public let storageServiceCensorshipPrefix = "storage"
    public let svr2CensorshipPrefix = "svr2"

    public let svr2Enclave = MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f")

    // An array of previously used enclaves that we should try and restore
    // key material from during registration. These must be ordered from
    // newest to oldest, so we check the latest enclaves for backups before
    // checking earlier enclaves.
    public let svr2PreviousEnclaves: [MrEnclave] = [
        MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f"),
        MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f"),
    ]

    public let applicationGroup = "group." + Bundle.main.bundleIdPrefix + ".group"

    /// We *might* need to clear credentials (or perform some other migration)
    /// when this value changes, depending on how it's changing. If you do need
    /// to perform a migration, check out `ZkParamsMigrator`.
    public let serverPublicParams = Data(base64Encoded: "AOSwc07bu3ImyxbdBax3eJsIIsjzyXELmZpQj3IUp1wbcGL/eeUU2b3LuYJnA+jbXA5z/VYyAm3shM1Fd6NIkhVMzsF4vkKTvBAEjDpXuYR8cFz5YzNdYum1sOwMVVKedIzQAT9YRr+qHwVZ3bFJM69AifuC8MrbhzvWwHWEZ1dU0LRos1YtWCtXtW3w/KZuEqJWJvf9rA6y708DMt0swBE27QeWRdOJKhRnxhMj7R+6bEh92/jXjtZfY9awQo1mX+wSu4qvXDopKGubupTLBa+DDgs9VG7xCewJPzh/cM5jhN7AS8BN0nwXNwjh9UOR1twZDp0RZ+B6yDBxJbTVN1Wo8szJewewkZ6riE7dGEp3ypTnZ+8/JZoB8xKAvzMEYzaEc6CGGqqtx7O5Wty7GpnumYtBxotao2WHgqbYiB44ENPEFWwPg8XSqM6ZJW5cyi5XAD31ubQ49hQs1asJUUsoWHcru8VIBX9UvN128yoDQcNouTXzeVrK+c9VMtzkLtRNVVGtEzCcmGsSpCg0oMqvXAgZTXCT6KdEnO0CMGIJ5kINHo6yC/1AMu8E9pvDBlfLyt1PQh9up5UxDXgRZUTQDkrnv8eoRWb/wx8perlTQGZV7QmWNN7f3W2B9bKOL26Le/0MfTFue3VDqUN4uGqlzzm4bVwV2nKf4Z5gwlFK9gOn9k6UiZ9aN5/Fm7zXL9btLT79Ly2K3s52ZfiZKnoe5bPAULcJ1MRawuS8XFSPo9soklHqaAhDwqjsHs0RfaxOKAkAIV/4ZQP1Ty5BGRg7XP1ZuaHMNEzQFjBdHdcW5qGR6AJtUOKVJn7+SVErGnw1Tu5KbZ6V+sLc0QTrLzqecKgrb0q77eXCv6r7THP79imh/Turlk1rgRHyqgRiPQ==")!

    public let callLinkPublicParams = Data(base64Encoded: "ACoSrbFfXNCwT2TOgSXKl+mqxApYYxFvA+fqP9TnhDZlMpxZfzVHKNaYn44P6lJWTT6YIzNHB1S1XeoxG8vT7iVU+AhVsESiC/wAxel3mz8QLsYYUu1WwhGdS9SiCrZbA1hdvWdPR9aevqDckr0reXY2b80Yvx2MXwanJZxty6MyTJhyzeQE62+clBZwPY4sTd/hwn+ye7V0h6yrZ2JXPSSGXKDJsozGVnOmi/JFtAyh0AK6ItRG94omkTid8zhxWSYN5bct4svdQOWhWOZoQT5/1NJOfTGUM5WfX4i+TvtL")!

    public let backupServerPublicParams = Data(base64Encoded: "ALy0PQXREe4drGk4xClPewbfE3pnFLALZ4mJ7TUFj0lvLAVpI4yQChBt20gxD7PfYZvVK8sGzYQ4G8UhM7sJY3Gw2aNwg3IjheOzY5web/1nVmnxVdt2gIco3+fVBG8jfRotXjJ2IGP/x9ayTqCBeQEc0xGtQZioKZo2PtFIy3oUQgn02z4gpnIXcT5VJu2G9YYC3cfiycEMEd+AZyB22w3qb3YWr2LfDA/aXDcQE/pio4jju5JQQIA2W1QBKNNqDrrlG765zfVBQDFEr8ruAn+gE3QvVKi2k+pH6jl6vdYv")!
}

// MARK: - Staging

public class TSConstantsStaging: TSConstantsProtocol {

    public init() {}

    public let mainServiceIdentifiedURL = "https://chat.imba-test.com"
    public let mainServiceUnidentifiedURL = "https://chat.imba-test.com"
    public let textSecureCDN0ServerURL = "http://cdn.imba-test.com"
    public let textSecureCDN2ServerURL = "https://cdn2.imba-test.com"
    public let textSecureCDN3ServerURL = "https://cdn3.imba-test.com"
    public let storageServiceURL = "https://storage.imba-test.com"
    public let sfuURL = "https://sfu.imba-test.com"
    public let sfuTestURL = "https://sfu.imba-test.com"
    public let svr2URL = "wss://svr2.imba-test.com"
    public let registrationCaptchaURL = "http://captcha.imba-test.com/registration/generate.html"
    public let challengeCaptchaURL = "http://captcha.imba-test.com/challenge/generate.html"
    // There's no separate test SFU for staging.
    public let kUDTrustRoot = "BX4nQt7OxWnkqgcYeYyIA1XX43ZfPTEfusNoYTV5NJlj"
    // There's no separate updates endpoint for staging.
    public let updatesURL = "http://updates2.imba-test.com"
    public let updates2URL = "http://updates2.imba-test.com"

    public let censorshipFReflectorHost = "reflector-staging-signal.global.ssl.fastly.net"
    public let censorshipGReflectorHost = "reflector-nrgwuv7kwq-uc.a.run.app"

    public let serviceCensorshipPrefix = "service-staging"
    public let cdn0CensorshipPrefix = "cdn-staging"
    public let cdn2CensorshipPrefix = "cdn2-staging"
    public let cdn3CensorshipPrefix = "cdn3-staging"
    public let storageServiceCensorshipPrefix = "storage-staging"
    public let svr2CensorshipPrefix = "svr2-staging"

    public let svr2Enclave = MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f")

    // An array of previously used enclaves that we should try and restore
    // key material from during registration. These must be ordered from
    // newest to oldest, so we check the latest enclaves for backups before
    // checking earlier enclaves.
    public let svr2PreviousEnclaves: [MrEnclave] = [
        MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f"),
        MrEnclave("b49a2d7aa6a92623713541be3342cc2432cbb4052a9ab83b50aef3375651e68f"),
    ]

    public let applicationGroup = "group." + Bundle.main.bundleIdPrefix + ".group.staging"

    /// We *might* need to clear credentials (or perform some other migration)
    /// when this value changes, depending on how it's changing. If you do need
    /// to perform a migration, check out `ZkParamsMigrator`.
    public let serverPublicParams = Data(base64Encoded: "AHbJ9KmFfwzDoqJhN6Vouyqdv5B9jqpZZBC1Nj4CRPdRur1cvdvE38qtK+a7fMy/m3SR0oK3PJ5UozxVvuUE6zQcQ50e8e/1dVceVfh80g1WPRpQu5c6MJnrKDkTPifMQ7wd87L7PmgijxKaDD+zz3k9IRLtdrTjCoimFtvt7uoZpNB2ufr6vr2b7VgOEvD9BqPtPErEw9LejE6sHFDhfy/anH9IU7s/Sc4veQBbYgJlaGY7wewt1xSC5k3uxnyQVSYjSh0aYbaSas9LquAFb0fLezOkLZLoFTvj/CbQ6to0dikNvCwVwCQOBQ5sfc8sPwT0Sik59lej6g8NU54DI3XeTjFXOSPpH0XGIVG5jHrIEKCjkc74RqsLaG846m3/cqQm3nHhVffEMAVx6yXAQU9sYiDZpYBJS2R1XiqGWtl2HNfBJwaKvvJ96SOIYOhMNMYm0SU023g2M4/RVhL8WQqyPlzyoZfTk2OvFCRcweQ14GlTzzBJLdYXUEh7Gi/KFdbjaA9Lg8bxlA8OzeyarzAenNU/CrIHCqLNU5re8l08+t7CXF8KftkwdcWjkKIfKDKHrZTNNBRxz1cRcPKhQzgC5I9YW2WsTaeCkMExzOxMA8HvzQv9mZDuNDS7Re8lZ3rGkzyQpKC8QBh7vlVd/qy6JZVCeAJxWO/HRTtj9GsbGt90ioDy4n3byEBg9QXksAyCYTdQvIv3nzzVcpcrZwLsz+z83QBpsdmqPfgwb9BYdZqPt4bSheUZZRU87r/IL+xG2N6QZPFS8vAknjJ+XUk8NvhXU53oT02Omq9EOrtc6LVNgG9BfT/c/lo+WTJfE5WUdGE7Xp13Qnss9Ej8PTiqzabyS+fu98QPcqoNxIyKv6bvcw3Uggofe0tNaumuFg==")!

    public let callLinkPublicParams = Data(base64Encoded: "ADKN7E6cEU87eJMvv69wLvPBwFKJq3JZkAKxWahgwd4jAiHjn31mbvn3eUhAKN2W5ub2C+wj6L6EIr2XZNvoIwO47X5IEjEnCpRrMofYfriKQIDIbFFSyft7PaUT50GbHHJ+Fw+NMVCz1VxNb8HBjIgtqqqj2+OUbUBERqL52mok7qajiPtrwMeTA0iCXDAxUPyGYFfWoa+yrfWJdUJ+byd4lIwfIQnFuF07Fo5VIkK17+QTPMUeyMNB+BZRlCs9asAsM+eOv3H4YOXomc2/Dm0YpwcoThQ5MOo2gJI+tcU/")!

    public let backupServerPublicParams = Data(base64Encoded: "AIIe881NQpY7o8wTPlTiIlMjUX8gvzqp4MVQb63dvX4JTLDLty9gz3EirUPkgSecfSjwY/eNZwDIcTc5gYzMBSj46Roe1r5wRp6Qemvkade9mXY/VMi4bNZgBX/+k11OU+JbPl5ADt2FCLI0L6MRyFr3ZLesYdEEaztCkxkISChj8g8BhFaRTjb+g4CHrm/d3DWuyyOMJ3VNtt2/qeWsqn/SpVpiHC0QM8sS83b5U4IAe7MiwZ+2nCPdAMqwrZwZcO6l+IRes7Za3SyYEABV+0GhmlmpQtHdcCEiWFb4FvtK")!

}

#if TESTABLE_BUILD

public class TSConstantsMock: TSConstantsProtocol {

    public init() {}

    private let defaultValues = TSConstantsProduction()

    public lazy var mainServiceIdentifiedURL = defaultValues.mainServiceIdentifiedURL

    public lazy var mainServiceUnidentifiedURL = defaultValues.mainServiceUnidentifiedURL

    public lazy var textSecureCDN0ServerURL = defaultValues.textSecureCDN0ServerURL

    public lazy var textSecureCDN2ServerURL = defaultValues.textSecureCDN2ServerURL

    public lazy var textSecureCDN3ServerURL = defaultValues.textSecureCDN3ServerURL

    public lazy var storageServiceURL = defaultValues.storageServiceURL

    public lazy var sfuURL = defaultValues.sfuURL

    public lazy var sfuTestURL = defaultValues.sfuTestURL

    public lazy var svr2URL = defaultValues.svr2URL

    public lazy var registrationCaptchaURL = defaultValues.registrationCaptchaURL

    public lazy var challengeCaptchaURL = defaultValues.challengeCaptchaURL

    public lazy var kUDTrustRoot = defaultValues.kUDTrustRoot

    public lazy var updatesURL = defaultValues.updatesURL

    public lazy var updates2URL = defaultValues.updates2URL

    public lazy var censorshipFReflectorHost = defaultValues.censorshipFReflectorHost
    public lazy var censorshipGReflectorHost = defaultValues.censorshipGReflectorHost

    public lazy var serviceCensorshipPrefix = defaultValues.serviceCensorshipPrefix

    public lazy var cdn0CensorshipPrefix = defaultValues.cdn0CensorshipPrefix

    public lazy var cdn2CensorshipPrefix = defaultValues.cdn2CensorshipPrefix

    public lazy var cdn3CensorshipPrefix = defaultValues.cdn3CensorshipPrefix

    public lazy var storageServiceCensorshipPrefix = defaultValues.storageServiceCensorshipPrefix

    public lazy var svr2CensorshipPrefix = defaultValues.svr2CensorshipPrefix

    public lazy var svr2Enclave = defaultValues.svr2Enclave

    public lazy var svr2PreviousEnclaves = defaultValues.svr2PreviousEnclaves

    public lazy var applicationGroup = defaultValues.applicationGroup

    public lazy var serverPublicParams = defaultValues.serverPublicParams

    public lazy var callLinkPublicParams = defaultValues.callLinkPublicParams

    public lazy var backupServerPublicParams = defaultValues.backupServerPublicParams
}

#endif

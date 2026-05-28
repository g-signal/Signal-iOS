//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import LocalAuthentication
import SignalServiceKit
import SignalUI
import UIKit

/// 绑定BAXS账号的入口页面
/// - 已绑定：展示已绑定的操作员信息
/// - 未绑定：展示扫码绑定入口
class LinkBAPlatformViewController: OWSTableViewController2 {

    private var linkedInfo: LinkedBaUserInfo?
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = OWSLocalizedString(
            "LINK_BA_PLATFORM_ACCOUNT_TITLE",
            comment: "Menu item for linking BAXS account"
        )
        updateTableContents(loading: true)
        Task { await loadLinkedInfo() }
    }

    // MARK: - Load

    private func loadLinkedInfo() async {
        do {
            let info = try await LinkBaPayService.shared.getLinkedBaUserInfo()
            await MainActor.run {
                self.linkedInfo = info
                self.updateTableContents(loading: false)
            }
        } catch {
            Logger.warn("Failed to load linked BA info: \(error)")
            await MainActor.run {
                self.updateTableContents(loading: false)
            }
        }
    }

    // MARK: - Table Contents

    private func updateTableContents(loading: Bool) {
        let contents = OWSTableContents()

        if loading {
            let section = OWSTableSection()
            section.add(.init(customCellBlock: {
                let cell = UITableViewCell()
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                spinner.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(spinner)
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    cell.contentView.heightAnchor.constraint(equalToConstant: 60)
                ])
                return cell
            }))
            self.contents = contents
            contents.add(section)
            return
        }

        if let info = linkedInfo, info.isLinked {
            buildLinkedSection(into: contents, info: info)
        } else {
            buildUnlinkedSection(into: contents)
        }

        self.contents = contents
    }

    // MARK: - Already Linked UI

    private func buildLinkedSection(into contents: OWSTableContents, info: LinkedBaUserInfo) {
        let section = OWSTableSection()
        section.headerTitle = OWSLocalizedString(
            "LINK_BA_PLATFORM_LINKED_SECTION_TITLE",
            comment: "Section header when BAXS account is linked"
        )

        if let optId = info.linkbaxsOptId {
            section.add(.label(
                withText: OWSLocalizedString(
                    "LINK_BA_PLATFORM_USER_ID",
                    comment: "Label for BAXS user ID"
                ),
                accessoryText: optId,
                accessoryType: .none
            ))
        }

        if let name = info.linkbaxsOptName {
            section.add(.label(
                withText: OWSLocalizedString(
                    "LINK_BA_PLATFORM_USER_NAME",
                    comment: "Label for BAXS user name"
                ),
                accessoryText: name,
                accessoryType: .none
            ))
        }

        if let email = info.linkbaxsOptEmail {
            section.add(.label(
                withText: OWSLocalizedString(
                    "LINK_BA_PLATFORM_OPERATOR_EMAIL",
                    comment: "Label for BA operator email"
                ),
                accessoryText: email,
                accessoryType: .none
            ))
        }

        if let mobile = info.linkbaxsOptMobile {
            section.add(.label(
                withText: OWSLocalizedString(
                    "LINK_BA_PLATFORM_OPERATOR_MOBILE",
                    comment: "Label for BA operator mobile"
                ),
                accessoryText: mobile,
                accessoryType: .none
            ))
        }

        contents.add(section)
    }

    // MARK: - Not Linked UI

    private func buildUnlinkedSection(into contents: OWSTableContents) {
        let section = OWSTableSection()
        section.headerTitle = OWSLocalizedString(
            "LINK_BA_PLATFORM_UNLINKED_SECTION_TITLE",
            comment: "Section header when BAXS account is not linked"
        )
        section.footerTitle = OWSLocalizedString(
            "LINK_BA_PLATFORM_SCAN_FOOTER",
            comment: "Footer text explaining how to link BAXS account"
        )
        section.add(.disclosureItem(
            icon: .settingsLinkBAPlatform,
            withText: OWSLocalizedString(
                "LINK_BA_PLATFORM_SCAN_QR_CODE",
                comment: "Button to scan QR code to link BAXS account"
            ),
            actionBlock: { [weak self] in
                self?.startScanFlow()
            }
        ))
        contents.add(section)
    }

    // MARK: - Scan Flow

    private func startScanFlow() {
        let localDeviceAuth = LocalDeviceAuthentication()
        let localDeviceAuthAttemptToken: LocalDeviceAuthentication.AttemptToken

        switch localDeviceAuth.checkCanAttempt() {
        case .success(let attemptToken):
            localDeviceAuthAttemptToken = attemptToken
        case .failure(.notRequired):
            presentScanAfterCameraPermission()
            return
        case .failure(.canceled):
            return
        case .failure(.genericError(let localizedErrorMessage)):
            OWSActionSheets.showActionSheet(
                title: DeviceAuthenticationErrorMessage.errorSheetTitle,
                message: localizedErrorMessage,
                fromViewController: self
            )
            return
        }

        let sheet = HeroSheetViewController(
            hero: .image(UIImage(named: "phone-lock")!),
            title: OWSLocalizedString(
                "LINK_NEW_DEVICE_AUTHENTICATION_INFO_SHEET_TITLE",
                comment: "Title for a sheet when a user tries to link a device informing them that they will need to authenticate their device"
            ),
            body: OWSLocalizedString(
                "LINK_NEW_DEVICE_AUTHENTICATION_INFO_SHEET_BODY",
                comment: "Body text for a sheet when a user tries to link a device informing them that they will need to authenticate their device"
            ),
            primaryButton: .init(title: CommonStrings.continueButton) { [weak self] _ in
                self?.dismiss(animated: true)
                Task {
                    await self?.authenticateThenScan(
                        localDeviceAuth: localDeviceAuth,
                        localDeviceAuthAttemptToken: localDeviceAuthAttemptToken
                    )
                }
            }
        )
        present(sheet, animated: true)
    }

    private func authenticateThenScan(
        localDeviceAuth: LocalDeviceAuthentication,
        localDeviceAuthAttemptToken: LocalDeviceAuthentication.AttemptToken
    ) async {
        switch await localDeviceAuth.attempt(token: localDeviceAuthAttemptToken) {
        case .success, .failure(.notRequired):
            await MainActor.run { presentScanAfterCameraPermission() }
        case .failure(.canceled):
            break
        case .failure(.genericError(let localizedErrorMessage)):
            await MainActor.run {
                OWSActionSheets.showActionSheet(
                    title: DeviceAuthenticationErrorMessage.errorSheetTitle,
                    message: localizedErrorMessage,
                    fromViewController: self
                )
            }
        }
    }

    private func presentScanAfterCameraPermission() {
        ows_askForCameraPermissions { [weak self] granted in
            guard granted else { return }
            let scanVC = ScanBaQRCodeViewController()
            scanVC.delegate = self
            self?.navigationController?.pushViewController(scanVC, animated: true)
        }
    }
}

// MARK: - ScanBaQRCodeViewControllerDelegate

extension LinkBAPlatformViewController: ScanBaQRCodeViewControllerDelegate {
    func didCompleteLinking() {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.presentToast(text: OWSLocalizedString(
                "LINK_BA_PLATFORM_SUCCESS_TOAST",
                comment: "Toast shown when BAXS account is successfully linked"
            ))
        }
        navigationController?.popViewController(animated: true)
        CATransaction.commit()
        Task { await loadLinkedInfo() }
    }
}

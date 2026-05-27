//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

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

        if !info.baxsAppUserId.isEmpty {
            section.add(.label(
                withText: OWSLocalizedString(
                    "LINK_BA_PLATFORM_USER_ID",
                    comment: "Label for BAXS user ID"
                ),
                accessoryText: info.baxsAppUserId,
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
        // 绑定成功后刷新页面
        Task { await loadLinkedInfo() }
        navigationController?.popViewController(animated: true)
    }
}

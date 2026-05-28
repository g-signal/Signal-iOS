//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import SignalServiceKit
import SignalUI
import UIKit

protocol ScanBaQRCodeViewControllerDelegate: AnyObject {
    func didCompleteLinking()
}

/// 扫描BAXS二维码，完成绑定流程
class ScanBaQRCodeViewController: OWSViewController {

    weak var delegate: ScanBaQRCodeViewControllerDelegate?

    private lazy var qrCodeScanViewController = QRCodeScanViewController(appearance: .framed)

    // 轮询相关
    private var pollingTask: Task<Void, Never>?
    private let pollIntervalSeconds: UInt64 = 3
    private let pollTimeoutSeconds: TimeInterval = 60

    /// 从相机直接扫到二维码时，传入 urlString 跳过扫码步骤
    private let preScannedURLString: String?
    private var didHandlePreScannedURL = false

    init(preScannedURLString: String? = nil) {
        self.preScannedURLString = preScannedURLString
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.scanQRCodeTitle

        qrCodeScanViewController.delegate = self
        addChild(qrCodeScanViewController)
        view.addSubview(qrCodeScanViewController.view)
        qrCodeScanViewController.view.autoPinEdgesToSuperviewEdges()
        qrCodeScanViewController.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let urlString = preScannedURLString, !didHandlePreScannedURL {
            didHandlePreScannedURL = true
            handleScannedURL(urlString)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.isIPad ? .all : .portrait
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pollingTask?.cancel()
    }

    private func handleScannedURL(_ urlString: String) {
        guard
            let url = URL(string: urlString),
            url.scheme == "baxs",
            url.host == "linkba",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let linkId = components.queryItems?.first(where: { $0.name == "linkId" })?.value
        else {
            showInvalidQRCodeAlert()
            return
        }

        Task { await fetchBaUserInfoAndConfirm(linkId: linkId) }
    }

    // MARK: - Step 1: Fetch BA user info and show confirmation

    private func fetchBaUserInfoAndConfirm(linkId: String) async {
        do {
            let info = try await ModalActivityIndicatorViewController.presentAndPropagateResult(
                from: self
            ) {
                try await LinkBaPayService.shared.getBaUserInfo(linkId: linkId)
            }
            if info.canRequestLink {
                showConfirmationAlert(info: info)
                return
            }
            // SCANNED: already submitted by another device, go straight to polling
            if let status = LinkStatus(rawValue: info.linkStatus), status == .scanned {
                startPolling(linkId: linkId)
                return
            }
            showCannotLinkAlert(reason: info.failReason)
        } catch {
            showErrorAlert(error: error)
        }
    }

    // MARK: - Step 2: Confirmation dialog

    private func showConfirmationAlert(info: BaUserInfo) {
        let titleFormat = OWSLocalizedString(
            "LINK_BA_PLATFORM_CONFIRM_TITLE",
            comment: "Title for BAXS binding confirmation dialog"
        )
        let messageFormat = OWSLocalizedString(
            "LINK_BA_PLATFORM_CONFIRM_MESSAGE_FORMAT",
            comment: "Message for BAXS binding confirmation dialog. Placeholder is merchant/operator name."
        )
        let message = String(format: messageFormat, info.optName)

        let actionSheet = ActionSheetController(title: titleFormat, message: message)
        actionSheet.addAction(ActionSheetAction(
            title: CommonStrings.okayButton,
            style: .default,
            handler: { [weak self] _ in
                Task { await self?.submitLinkRequest(linkId: info.linkId, confirmResult: true) }
            }
        ))
        actionSheet.addAction(ActionSheetAction(
            title: CommonStrings.cancelButton,
            style: .cancel,
            handler: { [weak self] _ in
                Task { await self?.submitLinkRequest(linkId: info.linkId, confirmResult: false) }
            }
        ))
        present(actionSheet, animated: true)
    }

    // MARK: - Step 3: Submit link request

    private func submitLinkRequest(linkId: String, confirmResult: Bool) async {
        let userName: String = SSKEnvironment.shared.databaseStorageRef.read { tx in
            let profile = SSKEnvironment.shared.profileManagerRef.localUserProfile(tx: tx)
            let given = profile?.givenName ?? ""
            let family = profile?.familyName ?? ""
            return "\(given) \(family)".trimmingCharacters(in: .whitespaces)
        }
        do {
            _ = try await ModalActivityIndicatorViewController.presentAndPropagateResult(
                from: self
            ) {
                try await LinkBaPayService.shared.requestLink(linkId: linkId, userName: userName, confirmResult: confirmResult)
            }
            if confirmResult {
                startPolling(linkId: linkId)
            }
        } catch {
            showErrorAlert(error: error)
        }
    }

    // MARK: - Step 4: Poll for result

    private func startPolling(linkId: String) {
        pollingTask?.cancel()

        let deadline = Date().addingTimeInterval(pollTimeoutSeconds)
        let intervalNs = pollIntervalSeconds * NSEC_PER_SEC

        ModalActivityIndicatorViewController.present(
            fromViewController: self,
            canCancel: true,
            asyncBlock: { [weak self] modal in
                guard let self else { return }

                self.pollingTask = Task {
                    while !Task.isCancelled && !modal.wasCancelled {
                        if Date() > deadline {
                            modal.dismiss()
                            self.showTimeoutAlert()
                            return
                        }

                        do {
                            let result = try await LinkBaPayService.shared.getLinkResult(linkId: linkId)
                            guard let status = LinkStatus(rawValue: result.linkStatus) else {
                                try? await Task.sleep(nanoseconds: intervalNs)
                                continue
                            }

                            if status.isTerminal {
                                modal.dismiss()
                                switch status {
                                case .linked:
                                    self.handleLinkSuccess()
                                case .failed:
                                    self.showFailedAlert(reason: result.failReason)
                                case .timeout:
                                    self.showTimeoutAlert()
                                default:
                                    break
                                }
                                return
                            }
                        } catch {
                            Logger.warn("Polling getLinkResult error: \(error)")
                        }

                        try? await Task.sleep(nanoseconds: intervalNs)
                    }
                }

                await pollingTask?.value
            }
        )
    }

    // MARK: - Success

    private func handleLinkSuccess() {
        delegate?.didCompleteLinking()
    }

    // MARK: - Error Alerts

    private func showInvalidQRCodeAlert() {
        let actionSheet = ActionSheetController(
            title: OWSLocalizedString("LINK_BA_PLATFORM_INVALID_QR_TITLE", comment: "Invalid QR code alert title"),
            message: OWSLocalizedString("LINK_BA_PLATFORM_INVALID_QR_MESSAGE", comment: "Invalid QR code alert message")
        )
        actionSheet.addAction(ActionSheetAction(
            title: OWSLocalizedString("LINK_BA_PLATFORM_SCAN_AGAIN", comment: "Button to scan QR code again"),
            style: .default,
            handler: { [weak self] _ in self?.qrCodeScanViewController.resetAndStartScanning() }
        ))
        actionSheet.addAction(ActionSheetAction(title: CommonStrings.cancelButton, style: .cancel))
        present(actionSheet, animated: true)
    }

    private func showCannotLinkAlert(reason: String?) {
        let message = reason ?? OWSLocalizedString(
            "LINK_BA_PLATFORM_CANNOT_LINK_DEFAULT_REASON",
            comment: "Default message when BAXS linking is not allowed"
        )
        let actionSheet = ActionSheetController(
            title: OWSLocalizedString("LINK_BA_PLATFORM_CANNOT_LINK_TITLE", comment: "Cannot link alert title"),
            message: message
        )
        actionSheet.addAction(ActionSheetAction(title: CommonStrings.okButton, style: .cancel))
        present(actionSheet, animated: true)
    }

    private func showFailedAlert(reason: String?) {
        let message = reason ?? OWSLocalizedString(
            "LINK_BA_PLATFORM_FAILED_DEFAULT_REASON",
            comment: "Default message when BAXS linking fails"
        )
        let actionSheet = ActionSheetController(
            title: OWSLocalizedString("LINK_BA_PLATFORM_FAILED_TITLE", comment: "Linking failed alert title"),
            message: message
        )
        actionSheet.addAction(ActionSheetAction(
            title: OWSLocalizedString("LINK_BA_PLATFORM_SCAN_AGAIN", comment: "Button to scan QR code again"),
            style: .default,
            handler: { [weak self] _ in self?.qrCodeScanViewController.resetAndStartScanning() }
        ))
        actionSheet.addAction(ActionSheetAction(title: CommonStrings.cancelButton, style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }

    private func showTimeoutAlert() {
        let actionSheet = ActionSheetController(
            title: OWSLocalizedString("LINK_BA_PLATFORM_TIMEOUT_TITLE", comment: "Linking timeout alert title"),
            message: OWSLocalizedString("LINK_BA_PLATFORM_TIMEOUT_MESSAGE", comment: "Linking timeout alert message")
        )
        actionSheet.addAction(ActionSheetAction(
            title: OWSLocalizedString("LINK_BA_PLATFORM_SCAN_AGAIN", comment: "Button to scan QR code again"),
            style: .default,
            handler: { [weak self] _ in self?.qrCodeScanViewController.resetAndStartScanning() }
        ))
        actionSheet.addAction(ActionSheetAction(title: CommonStrings.cancelButton, style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }

    private func showErrorAlert(error: Error) {
        let actionSheet = ActionSheetController(
            title: OWSLocalizedString("LINK_BA_PLATFORM_ERROR_TITLE", comment: "Generic error alert title"),
            message: error.userErrorDescription
        )
        actionSheet.addAction(ActionSheetAction(
            title: CommonStrings.retryButton,
            style: .default,
            handler: { [weak self] _ in self?.qrCodeScanViewController.resetAndStartScanning() }
        ))
        actionSheet.addAction(ActionSheetAction(title: CommonStrings.cancelButton, style: .cancel))
        present(actionSheet, animated: true)
    }
}

// MARK: - QRCodeScanDelegate

extension ScanBaQRCodeViewController: QRCodeScanDelegate {
    @discardableResult
    func qrCodeScanViewScanned(
        qrCodeData: Data?,
        qrCodeString: String?
    ) -> QRCodeScanOutcome {
        AssertIsOnMainThread()
        guard let qrCodeString else { return .continueScanning }
        handleScannedURL(qrCodeString)
        return .stopScanning
    }

    func qrCodeScanViewDismiss(_ qrCodeScanViewController: QRCodeScanViewController) {
        navigationController?.popViewController(animated: true)
    }
}

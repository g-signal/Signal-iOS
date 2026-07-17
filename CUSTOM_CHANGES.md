# 自定义改动记录

每次合并上游 tag 时，用以下命令确认所有自定义内容没有被覆盖：

```bash
git diff <new-tag> HEAD --name-only
git diff <new-tag> HEAD -- \
  SignalServiceKit/Environment/TSConstants.swift \
  SignalServiceKit/Network/OWSSignalService.swift \
  SignalServiceKit/Network/OWSSignalServiceProtocol.swift \
  SignalServiceKit/Network/OWSUrlSession.swift \
  SignalServiceKit/Network/ChatConnectionManager.swift \
  SignalServiceKit/Network/OutageDetection.swift \
  SignalServiceKit/Network/SignalProxy/SignalProxy.swift \
  Signal/URLs/UrlOpener.swift \
  Signal/Provisioning/DeviceProvisioningURL.swift \
  Signal/util/SignalDotMePhoneNumberLink.swift \
  SignalServiceKit/Messages/Stickers/StickerPackInfo.swift \
  SignalServiceKit/Messages/Stickers/DefaultStickers.swift \
  SignalServiceKit/Usernames/Usernames+UsernameLink.swift \
  SignalServiceKit/Network/API/Requests/OWSRequestFactory.swift \
  SignalServiceKit/Network/API/SignalServiceProfile.swift \
  SignalServiceKit/Resources/schema.sql \
  SignalServiceKit/Storage/Database/GRDBSchemaMigrator.swift \
  SignalServiceKit/Profiles/ProfileFetcherJob.swift \
  SignalServiceKit/Groups/GroupV2UpdatesImpl.swift \
  SignalServiceKit/Groups/GroupManager.swift \
  Signal/ConversationView/ConversationHeaderView.swift \
  Signal/ConversationView/ConversationInputToolbar.swift \
  Signal/src/ViewControllers/ThreadSettings/ConversationSettingsViewController+Contents.swift \
  Signal/src/ViewControllers/AppSettings/AppSettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/HelpViewController.swift \
  Signal/src/ViewControllers/AppSettings/ContactSupportViewController.swift \
  Signal/Notifications/PushRegistrationManager.swift \
  Signal/util/SyncPushTokensJob.swift \
  Signal/AppLaunch/AppDelegate.swift \
  Signal/Signal-Info.plist \
  Signal/Signal.entitlements \
  Signal/Signal-AppStore.entitlements \
  Signal/Calls/CallKitCallManager.swift \
  SignalUI/Appearance/Theme+Icons.swift \
  SignalUI/Payments/MobileCoinAPI.swift \
  SignalUI/Payments/Payments.swift \
  SignalUI/Payments/PaymentsImpl.swift \
  Signal/src/ViewControllers/AppSettings/Privacy/AdvancedPrivacySettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/Privacy/ProxySettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/Account/AccountSettingsViewController.swift \
  Signal/translations/ \
  Signal/Registration/RegistrationCoordinatorImpl.swift \
  Signal/Backups/BackupSettingsViewController.swift \
  Signal/Backups/ChooseBackupPlanViewController.swift \
  Signal/ConversationView/ConversationViewController+MessageRequest.swift \
  Signal/ConversationView/MessageRequestView.swift \
  Signal/ConversationView/ConversationViewController+Calls.swift \
  Signal/ConversationView/ConversationViewController+CVComponentDelegate.swift \
  Signal/ConversationView/ConversationViewController+Delegates.swift \
  Signal/ConversationView/ConversationViewController+ConversationInputToolbarDelegate.swift \
  Signal/ConversationView/ConversationViewController+GiftBadges.swift \
  Signal/ConversationView/ConversationViewController+MessageActionsDelegate.swift \
  Signal/ConversationView/ConversationViewController+OWS.swift \
  Signal/ConversationView/ConversationViewController+UI.swift \
  Signal/ConversationView/Components/CVComponentArchivedPayment.swift \
  Signal/ConversationView/Components/CVComponentMessage.swift \
  Signal/ConversationView/Components/CVComponentPaymentAttachment.swift \
  Signal/ConversationView/Components/CVComponentState.swift \
  Signal/ConversationView/Components/CVComponentThreadDetails.swift \
  Signal/ConversationView/Loading/CVItemViewState.swift \
  Signal/Calls/UserInterface/CallsListViewController.swift \
  Signal/Calls/UserInterface/CallsListViewController+ViewModelLoader.swift \
  Signal/Megaphones/ExperienceUpgradeManager.swift \
  Signal/Megaphones/UserInterface/BackupEnablementMegaphone.swift \
  Signal/Megaphones/UserInterface/InactivePrimaryDeviceReminderMegaphone.swift \
  Signal/Megaphones/UserInterface/RecoveryKeyReminderMegaphone.swift \
  Signal/Megaphones/UserInterface/RemoteMegaphone.swift \
  Signal/Provisioning/UserInterface/LinkAndSyncProvisioningProgressViewController.swift \
  Signal/Provisioning/UserInterface/ProvisioningQRCodeViewController.swift \
  Signal/Provisioning/UserInterface/ProvisioningTransferChoiceViewController.swift \
  Signal/QRCodes/QRCodeView.swift \
  Signal/Registration/RegistrationCoordinatorBackupErrorPresenter.swift \
  "Signal/Registration/UserInterface/RegistrationChooseRestoreMethodViewController.swift" \
  "Signal/Registration/UserInterface/RegistrationEnterAccountEntropyPoolViewController.swift" \
  Signal/Registration/UserInterface/RegistrationPhoneNumberViewController.swift \
  "Signal/Registration/UserInterface/RegistrationPinAttemptsExhaustedAndMustCreateNewPinViewController.swift" \
  Signal/Registration/UserInterface/RegistrationPinViewController.swift \
  Signal/Registration/UserInterface/RegistrationProfileViewController.swift \
  Signal/Registration/UserInterface/RegistrationReglockTimeoutViewController.swift \
  Signal/Registration/UserInterface/RegistrationVerificationCodeView.swift \
  "Signal/src/ViewControllers/AppSettings/Account/AdvancedPinSettingsTableViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Account/DeleteAccountConfirmationViewController.swift" \
  Signal/src/ViewControllers/AppSettings/Account/RequestAccountDataReportViewController.swift \
  Signal/src/ViewControllers/AppSettings/Appearance/AppIconSettingsTableViewController.swift \
  Signal/src/ViewControllers/AppSettings/Donations/DonationSettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/Internal/InternalSettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/Internal/TestingViewController.swift \
  "Signal/src/ViewControllers/AppSettings/Linked Devices/LinkedDevicesView.swift" \
  "Signal/src/ViewControllers/AppSettings/Linked Devices/LinkedDevicesEducationSheet.swift" \
  Signal/src/ViewControllers/AppSettings/Privacy/PrivacySettingsViewController.swift \
  Signal/src/ViewControllers/AppSettings/Profile/ProfileSettingsViewController.swift \
  "Signal/src/ViewControllers/Attachment Keyboard/AttachmentFormatPickerView.swift" \
  "Signal/src/ViewControllers/Attachment Keyboard/AttachmentKeyboard.swift" \
  Signal/src/ViewControllers/DebugUI/DebugUIMisc.swift \
  Signal/src/ViewControllers/Donations/BadgeDetailsSheet.swift \
  Signal/src/ViewControllers/Donations/DonationViewsUtil.swift \
  "Signal/src/ViewControllers/Donations/DonationViewsUtil+IDEAL.swift" \
  Signal/src/ViewControllers/GetStartedBannerViewController.swift \
  "Signal/src/ViewControllers/HomeView/Chat List/ChatListCell.swift" \
  "Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController.swift" \
  "Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController+Loading.swift" \
  "Signal/src/ViewControllers/HomeView/Chat List/CLVTableDataSource.swift" \
  Signal/src/ViewControllers/HomeView/HomeTabBarController.swift \
  Signal/src/ViewControllers/HomeView/HomeTabViewController.swift \
  Signal/src/ViewControllers/NameEducationSheet.swift \
  Signal/src/ViewControllers/NewGroupView/NewGroupConfirmViewController.swift \
  Signal/src/ViewControllers/OWSPinSetupViewController.swift \
  Signal/src/ViewControllers/Payments/SendPaymentCompletionActionSheet.swift \
  Signal/src/ViewControllers/Payments/SendPaymentHelper.swift \
  Signal/src/ViewControllers/Payments/SendPaymentMemoViewController.swift \
  Signal/src/ViewControllers/Payments/SendPaymentViewController.swift \
  Signal/src/ViewControllers/Photos/PhotoCaptureViewController.swift \
  Signal/src/ViewControllers/ThreadSettings/ConversationHeaderBuilder.swift \
  Signal/src/ViewControllers/ThreadSettings/ConversationSettingsViewController.swift \
  Signal/src/ViewControllers/ThreadSettings/DisappearingMessagesTimerSettingsViewController.swift \
  Signal/src/views/ExpirationNagView.swift \
  Signal/src/views/GetStartedBannerCell.swift \
  Signal/Usernames/Selection/UsernameSelectionViewController.swift \
  SignalServiceKit/Attachments/SignalAttachment.swift \
  "SignalServiceKit/Messages/Attachments/V2/Playback/AVAsset+Attachment.swift" \
  SignalServiceKit/Calls/CallHTTPClient.swift \
  SignalServiceKit/Groups/TSGroupModel.swift \
  "SignalServiceKit/Messages/Interactions/LinkPreview/Manager/LinkPreviewHelper.swift" \
  "SignalServiceKit/Messages/Interactions/TSInfoMessage+GroupUpdates+DisplayableGroupUpdateItem.swift" \
  SignalServiceKit/Network/API/Requests/Registration/RegistrationRequestFactory.swift \
  SignalServiceKit/Profiles/BadgeAssets.swift \
  SignalServiceKit/Profiles/BadgeStore.swift \
  SignalServiceKit/Storage/Database/SDSDatabaseStorage/SDSDatabaseStorage.swift \
  SignalServiceKit/Subscriptions/Donations/Paypal+WebAuthentication.swift \
  SignalServiceKit/Subscriptions/Donations/Stripe.swift \
  "SignalServiceKit/Subscriptions/Donations/Stripe+3DSecure.swift" \
  SignalServiceKit/Util/OWSPaymentsLock.swift \
  SignalServiceKit/Util/Preferences.swift \
  SignalNSE/NotificationService.swift \
  SignalNSE/NSECallMessageHandler.swift \
  SignalNSE/SignalNSE.entitlements \
  SignalNSE/SignalNSE-AppStore.entitlements \
  SignalShareExtension/Info.plist \
  SignalShareExtension/SAEFailedViewController.swift \
  SignalShareExtension/SignalShareExtension.entitlements \
  SignalShareExtension/SignalShareExtension-AppStore.entitlements \
  SignalUI/AppLaunch/SUIEnvironment.swift \
  SignalUI/Calls/CallLink.swift \
  SignalUI/Payments/DebugLogger+Payments.swift \
  SignalUI/Payments/MobileCoinAPI+Configuration.swift \
  SignalUI/Payments/MobileCoinHelperSDK.swift \
  SignalUI/Payments/PaymentsFormat+MobileCoin.swift \
  SignalUI/Payments/PaymentsProcessor.swift \
  SignalUI/Payments/PaymentsReconciliation.swift \
  SignalUI/RecipientPickers/ContactsViewHelper.swift \
  SignalUI/RecipientPickers/InviteFlow.swift \
  SignalUI/RecipientPickers/RecipientPickerViewController.swift \
  SignalUI/SafetyNumbers/FingerprintViewController.swift \
  SignalUI/Sending/DraftQuotedReplyModel+Payments.swift \
  SignalUI/Stories/ConnectionsEducationSheetViewController.swift \
  SignalUI/Utils/GroupViewUtils.swift \
  SignalUI/ViewControllers/OWSTableViewController2.swift \
  SignalUI/ViewControllers/ScanQRCodeViewController.swift \
  "Signal/src/ViewControllers/AppSettings/Payments/ArchivedPaymentHistoryItem.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentModelCell.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsBiometryLockPromptViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsDeactivateViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsDetailViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsHistory.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsHistoryViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsQRScanViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletCompleteViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletPasteboardViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletSplashViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletWordViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsSendRecipientViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsSettingsViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsTransferInViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsTransferOutViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseConfirmViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseGridViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseSplashViewController.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewUtils.swift" \
  "Signal/src/ViewControllers/AppSettings/Payments/TSPaymentModelHistoryItem.swift" \
  Signal/Images.xcassets/signal-logo-40.imageset/Contents.json \
  Signal/Images.xcassets/signal-logo-128-launch-screen.imageset/Contents.json \
  "Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController+BackupDownloadProgressView.swift"
```

---

## 新增文件清单（共 12 个）

```
SignalServiceKit/GExt/GExtRobot.swift
SignalServiceKit/GExt/GExtTag.swift
SignalServiceKit/GExt/GExtTagRecord.swift
SignalServiceKit/GExt/GExtTagStore.swift
SignalServiceKit/GExt/GGroupGExtTagRecord.swift
SignalServiceKit/GExt/GExtGroupProfileFetcher.swift
SignalServiceKit/GExt/LinkBaPayService.swift
SignalServiceKit/Network/API/NetworkRequestLogger.swift
SignalUI/Views/GExt/GExtTagView.swift
SignalUI/Views/GExt/GExtTagsStackView.swift
Signal/src/ViewControllers/AppSettings/Linked Devices/LinkBAPlatformViewController.swift
Signal/src/ViewControllers/AppSettings/Linked Devices/ScanBaQRCodeViewController.swift
```

---

## 1. `SignalServiceKit/Environment/TSConstants.swift`

| 字段 | 原始（Signal 官方） | 自定义（B&A） |
|------|-------------------|--------------|
| `mainServiceIdentifiedURL` | `https://chat.signal.org` | `https://chat.ba-chat.com` |
| `mainServiceUnidentifiedURL` | `https://ud-chat.signal.org` | `https://chat.ba-chat.com` |
| `textSecureCDN0ServerURL` | `https://cdn.signal.org` | `https://cdn.ba-chat.com` |
| `textSecureCDN2ServerURL` | `https://cdn2.signal.org` | `https://cdn2.ba-chat.com` |
| `textSecureCDN3ServerURL` | `https://cdn3.signal.org` | `https://cdn3.ba-chat.com` |
| `storageServiceURL` | `https://storage.signal.org` | `https://storage.ba-chat.com` |
| `sfuURL` | `https://sfu.voip.signal.org` | `https://sfu.ba-chat.com` |
| `sfuTestURL` | `https://sfu.test.voip.signal.org` | `https://sfu.ba-chat.com` |
| `svr2URL` | `wss://svr2.signal.org` | `wss://svr2.ba-chat.com` |
| `legalTermsUrl` | `https://signal.org/legal/` | `"\(textSecureCDN0ServerURL)/legal/index.html"` |
| `appStoreUrl` | `id874139669` | `id6754267880` |
| `updatesURL` | `https://updates.signal.org` | `https://updates2.ba-chat.com/static/badges` |
| `updates2URL` | `https://updates2.signal.org` | `https://updates2.ba-chat.com/static/badges` |
| `registrationCaptchaURL` | `https://signalcaptchas.org/registration/generate.html` | `https://captcha.ba-chat.com/registration/generate.html` |
| `challengeCaptchaURL` | `https://signalcaptchas.org/challenge/generate.html` | `https://captcha.ba-chat.com/challenge/generate.html` |
| `kUDTrustRoots` | Signal 官方信任根证书 | `["Bd8hujwt+PY1jMqO5xC/8pmIuxwzwuX7ZjHKoJ2BVL4g"]` |
| `serverPublicParams` | Signal 官方 base64 值 | BA 自定义 base64 值 |
| `callLinkPublicParams` | Signal 官方 base64 值 | BA 自定义 base64 值 |
| `backupServerPublicParams` | Signal 官方 base64 值 | BA 自定义 base64 值 |

`TSConstantsStaging` 中所有 URL 指向 `imba-test.com` 域名。

---

## 2. `SignalServiceKit/Network/OWSSignalServiceProtocol.swift`

所有 `SignalServiceInfo` 初始化的 `shouldUseSignalCertificate` 参数由 `true` 改为 `false`（共 6 处）：
- `mainSignalServiceIdentified`
- `mainSignalServiceUnidentified`
- `storageService`
- `updates`
- `updates2`
- `svr2`

---

## 3. `SignalServiceKit/Network/OWSUrlSession.swift`

新增网络请求/响应日志记录：

```swift
NetworkRequestLogger.shared.logRequest(logRequest)
NetworkRequestLogger.shared.logResponse(response, for: rawRequest)
```

---

## 4. `SignalServiceKit/Network/ChatConnectionManager.swift`

WebSocket 请求/响应/错误增加日志记录：

```swift
NetworkRequestLogger.shared.logRequest(request)
NetworkRequestLogger.shared.logResponse(response, for: request)
NetworkRequestLogger.shared.logError(error, for: request)
```

---

## 5. `SignalServiceKit/Network/OutageDetection.swift`

`checkForOutageSync()` 函数体内的 DNS 解析代码全部注释掉（`uptime.signal.org`、`CFHostCreateWithName` / `CFHostStartInfoResolution`，约 45 行），函数直接返回 `false`。

---

## 6. `SignalServiceKit/Network/SignalProxy/SignalProxy.swift`

```swift
// 原：scheme.caseInsensitiveCompare("sgnl") == .orderedSame
// 改为：
scheme.caseInsensitiveCompare("baxs") == .orderedSame
```

---

## 7. `Signal/URLs/UrlOpener.swift`

- `sgnlPrefix` 常量：`"sgnl"` → `"baxs"`
- 新增 URL case `linkBaPay(linkId: String)`，对应 `baxs://linkba?linkId=xxx`
- 新增 `parseLinkBaPayUrl()` 私有方法
- 处理逻辑：弹出 ActionSheet 引导用户进入 Settings → LinkBAPlatformViewController

---

## 8. `Signal/Provisioning/DeviceProvisioningURL.swift`

```swift
// 原：private static let sgnlPrefix = "sgnl"
// 改为：
private static let sgnlPrefix = "baxs"
```

---

## 9. `Signal/util/SignalDotMePhoneNumberLink.swift`

正则表达式 host：`signal.me` → `me.baxs.com`

---

## 10. `SignalServiceKit/Messages/Stickers/StickerPackInfo.swift`

- sticker 链接域名：`signal.art/addstickers` → `sticker.baxs.com/addstickers`
- scheme 校验新增 `baxs://`

---

## 11. `SignalServiceKit/Messages/Stickers/DefaultStickers.swift`

注释掉 production service 检查 guard 语句。

---

## 12. `SignalServiceKit/Usernames/Usernames+UsernameLink.swift`

| 字段 | 原始 | 自定义 |
|------|------|--------|
| scheme | `sgnl` | `baxs` |
| host | `signal.me` | `me.baxs.com` |

---

## 13. `SignalServiceKit/Network/API/Requests/OWSRequestFactory.swift`

新增 4 组 API 端点：

```swift
// VoIP Push
public static func registerForVoipPushRequest(voipToken: String) -> TSRequest
public static func unregisterFromVoipPushRequest() -> TSRequest

// 群组 ExtTag：GET v1/gext/group/profile/{groupId}
static func getGroupExtTagsRequest(groupId: String) -> TSRequest

// LinkBaPay
static func linkBaPayGetBaUserInfoRequest(linkId: String) -> TSRequest
static func linkBaPayRequestLinkRequest(linkId: String, userName: String, confirmResult: Bool) -> TSRequest
static func linkBaPayGetLinkResultRequest(linkId: String) -> TSRequest
static func linkBaPayGetLinkedBaUserInfoRequest() -> TSRequest
```

---

## 14. `SignalServiceKit/Network/API/SignalServiceProfile.swift`

新增两个字段：

```swift
public let gextTags: [GExtTag]?
public let gextRobot: GExtRobot?
```

---

## 15. `SignalServiceKit/Resources/schema.sql`

新增两个自定义表：

```sql
CREATE TABLE IF NOT EXISTS "gext_recipient" (
    "_id" INTEGER PRIMARY KEY,
    "aci" VARCHAR(32) NOT NULL,
    "tags" BLOB NOT NULL,
    "last_updated" INTEGER NOT NULL,
    "robot" BLOB DEFAULT NULL,
    UNIQUE("aci")
);

CREATE TABLE IF NOT EXISTS "gext_groups" (
    "_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "group_id" VARCHAR(64) NOT NULL,
    "tags" BLOB NOT NULL,
    "last_updated" INTEGER NOT NULL,
    UNIQUE("group_id")
);
```

---

## 16. `SignalServiceKit/Storage/Database/GRDBSchemaMigrator.swift`

在末尾追加 3 个自定义迁移：

```swift
case createGExtTagTables         // 创建 gext_recipient 表
case createGExtGroupTagTables    // 创建 gext_groups 表
case addGExtRecipientRobotColumn // gext_recipient 表增加 robot 列
```

---

## 17. `SignalServiceKit/Profiles/ProfileFetcherJob.swift`

拉取个人 profile 成功后：
- `gextTags` 非 nil 时调用 `GExtTagStore.shared.setUserExtTags`
- `gextRobot` 非 nil 时调用 `GExtTagStore.shared.setUserRobot`
- 字段缺失时保留本地现有数据（不清空）

---

## 18. `SignalServiceKit/Groups/GroupV2UpdatesImpl.swift`

群组信息更新后调用：
```swift
GExtGroupProfileFetcher.shared.fetchAndStoreGroupExtTags(groupId: ...)
```

---

## 19. `SignalServiceKit/Groups/GroupManager.swift`

群组信息更新后调用：
```swift
GExtGroupProfileFetcher.shared.fetchAndStoreGroupExtTags(groupId: ...)
```

---

## 20. `Signal/ConversationView/ConversationHeaderView.swift`

会话顶部标题旁新增 `GExtTagsStackView`：
- 联系人会话：显示该联系人的 GExtTag
- 群组会话：显示该群组的 GExtTag
- Note to Self / 无 ACI 时隐藏

---

## 21. `Signal/ConversationView/ConversationInputToolbar.swift`

新增 `msgButtonVisible: GExtRobot.MsgButtonVisible?` 参数，机器人配置隐藏输入栏按钮：

| `msgButtonVisible` 字段 | 为 `false` 时隐藏 |
|------------------------|-----------------|
| `camera` | 相机按钮 |
| `microphone` | 麦克风/语音按钮 |
| `sticker` | 贴纸按钮 |

---

## 22. `Signal/src/ViewControllers/ThreadSettings/ConversationSettingsViewController+Contents.swift`

机器人会话（`gextRobot.robot == true`）隐藏以下入口：
- 昵称（Nickname）
- 安全码（Safety Number）
- 声音与通知（Sound & Notifications）
- 系统联系人（System Contact）
- 添加到群组（Add to Group）

---

## 23. `Signal/src/ViewControllers/AppSettings/AppSettingsViewController.swift`

- 删除 Donate 入口（整块移除）
- 删除 Backups 入口（整块移除）
- 新增 Link BA Platform 入口（`LinkBAPlatformViewController`）

---

## 24. `Signal/src/ViewControllers/AppSettings/HelpViewController.swift`

新增 `SupportConstants` 类：

```swift
class SupportConstants: NSObject {
    static let supportURL = URL(string: "about:blank")!
    static let debugLogsInfoURL = URL(string: "about:blank")!
    static let supportEmail = "support@baxs.com"
    static let subscriptionFAQURL = URL(string: "about:blank")!
    static let donorFAQURL = URL(string: "about:blank")!
    static let badgeExpirationLearnMoreURL = URL(string: "about:blank")!
    static let donationPendingLearnMoreURL = URL(string: "about:blank")!
}
```

Debug Log 上传入口已禁用。

---

## 25. `Signal/src/ViewControllers/AppSettings/ContactSupportViewController.swift`

- 注释掉 payments / donationsAndBadges 支持分类
- Debug log info button（`?` 图标）隐藏：`cell.contentView.addSubview(infoButton)` 及布局约束注释掉
- Debug Log 上传禁用

---

## 26. `Signal/Notifications/PushRegistrationManager.swift`

重写 VoIP Push token 注册逻辑：
- 新增 `voipTokenPromise` / `voipTokenFuture` / `voipTokenPromiseCreationTime` 字段
- `registerForRemotePushToken()` 同时等待 VoIP token，合并为 `ApnRegistrationId(apnsToken:voipToken:)` 上报
- `PKPushRegistryDelegate.pushRegistry(_:didUpdate:for:)` 收到 token 后 resolve promise

---

## 27. `Signal/util/SyncPushTokensJob.swift`

- `updatePushTokens` / `recordPushTokensLocally` 增加 `voipToken` 参数
- VoIP token 变化时触发上传（`reason = "voip_changed"`）
- 增加详细日志

---

## 28. `Signal/AppLaunch/AppDelegate.swift`

```swift
// DebugLogger.configureSwiftLogging()  // 注释掉
paymentsEvents: PaymentsEventsNoop()        // 原 PaymentsEventsMainApp()
mobileCoinHelper: MobileCoinHelperMinimal() // 原 MobileCoinHelperSDK()
```

---

## 29. `Signal/Signal-Info.plist`

| 字段 | 原始 | 自定义 |
|------|------|--------|
| `CFBundleDisplayName` | `Signal` | `B&A` |
| `CFBundleIdentifier` | `org.whispersystems.signal` | `com.baxs.ba` |
| `CFBundleURLSchemes` | `["sgnl"]` | `["baxs"]` |
| NS*UsageDescription 字段 | `Signal uses...` | `BA Chat uses...` |

---

## 30. `Signal/Signal.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:group.baxs.com</string>
    <string>applinks:sticker.baxs.com</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.$(SIGNAL_BUNDLEID_PREFIX).group</string>
    <string>group.$(SIGNAL_BUNDLEID_PREFIX).group.staging</string>
</array>
```

---

## 31. `Signal/Signal-AppStore.entitlements`

与 `Signal.entitlements` 相同修改（associated-domains + application-groups）。

---

## 32. `Signal/Calls/CallKitCallManager.swift`

| 原始 | 自定义 |
|------|--------|
| `"Signal:"` | `"B&A:"` |
| `"SignalGroup:"` | `"B&AGroup:"` |
| `"SignalCall:"` | `"B&ACall:"` |

---

## 33. `SignalUI/Appearance/Theme+Icons.swift`

新增图标映射：

```swift
case .settingsLinkBAPlatform:
    return "link_ba"
```

---

## 34. `SignalUI/Payments/MobileCoinAPI.swift`

整个文件注释掉（约 776 行）。

---

## 35. `SignalUI/Payments/Payments.swift`

- `shouldShowPaymentsUI` 返回 `false`
- 核心支付方法注释掉

---

## 36. `SignalUI/Payments/PaymentsImpl.swift`

整个文件注释掉。

---

## 37. `Signal/src/ViewControllers/AppSettings/Privacy/AdvancedPrivacySettingsViewController.swift`

Support URL 链接指向 `about:blank`。

---

## 38. `Signal/src/ViewControllers/AppSettings/Privacy/ProxySettingsViewController.swift`

Support URL 链接指向 `about:blank`。

---

## 39. `Signal/src/ViewControllers/AppSettings/Account/AccountSettingsViewController.swift`

Support URL 链接指向 `about:blank`。

---

## 40. `Signal/translations/`（45 个语言，每语言 3 个文件）

**Localizable.strings**：品牌词替换

| 原始 | 替换为 |
|------|--------|
| `Signal`（品牌名） | `B&A` |
| `signal.org` | `baxs.com` / `ba-chat.com` |
| `support@signal.org` | `support@baxs.com` |
| `Signal Call` | `B&A Call` |
| `Invite to Signal` | `Invite to B&A` |
| `Signal Backups` | `B&A Backups` |

注意：非品牌词（法语 `Signaler`/`signaler`、瑞典语 `ringsignal`、丹麦语 `Nulstil signal`、"cellular signal" 手机信号强度等）保持不变。

**PluralAware.stringsdict**：所有复数形式字符串中的品牌词替换，规则同上。涉及词条：`Signal groups`、`Signal will ring`、`open Signal on that device`、`All Signal Connections` 等（各语言语法形式不同，如日语 `Signalグループ`、韩语 `Signal은` 等）。

**InfoPlist.strings**：所有 NS*UsageDescription 中的 `Signal` 替换为 `B&A`（共 9 个权限字段，适用于所有 45 个语言）。

---

## 41. `.gitignore`

新增：
```
CUSTOM_CHANGES.md
```

---

## 42. `Signal/Registration/RegistrationCoordinatorImpl.swift`（7.79 新增改动）

注册流程中完全禁用备份恢复入口：

- `setHasOldDevice(_:)` — 无论用户是否有旧设备，始终使用 `manualRestore`，不进入 Quick Restore 备份路径
- 三处 `if deps.featureFlags.backupSupported` 改为 `if false`，始终走设备转移分支而非备份恢复分支
- `shouldRestoreFromMessageBackup()` 直接返回 `false`，注册完成后不触发从备份恢复消息的流程

---

## 43. `SignalUI/Utils/URL+Support.swift`（7.79 新增文件，不修改）

7.79 新增的 support URL 集中管理文件。所有通过 `URL.Support.*` 触发的 support.signal.org 链接在各调用入口处直接隐藏按钮（见下方各文件），本文件保持不改动。

---

## 44. `Signal/Backups/BackupSettingsViewController.swift`

Action sheet 中"了解更多"ActionSheetAction 整块注释掉（入口隐藏，不跳转 support.signal.org/backups）。

---

## 45. `Signal/Backups/ChooseBackupPlanViewController.swift`

SwiftUI Text `.appendLink(learnMore)` 整块注释掉（入口链接隐藏，不显示"了解更多"，不跳转 support.signal.org/backups）。

---

## 46. `Signal/ConversationView/ConversationViewController+MessageRequest.swift`

`messageRequestViewDidTapLearnMore()` 函数体注释掉，按钮点击后不跳转 support.signal.org。

---

## 47. `Signal/ConversationView/MessageRequestView.swift`

隐藏"了解更多"链接（2 处注释掉 `appendLearnMoreLink = true`），防止跳转到 signal.org 支持页面。

---

## 48. `Signal/ConversationView/ConversationViewController+Calls.swift`

机器人账户不允许发起通话（`GExtTagStore.shared.getUserRobot(...).robot == true` 时直接 return）。

---

## 49. `Signal/ConversationView/ConversationViewController+CVComponentDelegate.swift`

注释掉支付历史记录导航（MobileCoin 移除）。

---

## 50. `Signal/ConversationView/ConversationViewController+Delegates.swift`

机器人账户点击标题不跳转会话设置（robot 账户屏蔽 `titleTapped` 导航）。

---

## 51. `Signal/ConversationView/ConversationViewController+ConversationInputToolbarDelegate.swift`

注释掉支付按钮处理逻辑（MobileCoin 移除）。

---

## 52. `Signal/ConversationView/ConversationViewController+GiftBadges.swift`

禁用捐赠/徽章相关感谢弹窗逻辑。

---

## 53. `Signal/ConversationView/ConversationViewController+MessageActionsDelegate.swift`

注释掉支付详情导航（MobileCoin 移除）。

---

## 54. `Signal/ConversationView/ConversationViewController+OWS.swift`

- 注释掉 `SendPaymentViewDelegate` 相关实现（MobileCoin 移除）
- 未知线程警告 action sheet 中的"了解更多"ActionSheetAction 注释掉
- 消息投递问题警告 action sheet 中的"了解更多"ActionSheetAction 注释掉

---

## 55. `Signal/ConversationView/ConversationViewController+UI.swift`

集成 `GExtRobot.msgButtonVisible`，根据机器人配置控制输入栏按钮可见性。

---

## 56. `Signal/ConversationView/Components/CVComponentArchivedPayment.swift`

注释掉支付金额格式化逻辑（MobileCoin 移除）。

---

## 57. `Signal/ConversationView/Components/CVComponentMessage.swift`

注释掉 payment attachment 相关逻辑（MobileCoin 移除）。

---

## 58. `Signal/ConversationView/Components/CVComponentPaymentAttachment.swift`

注释掉支付格式化逻辑（MobileCoin 移除）。

---

## 59. `Signal/ConversationView/Components/CVComponentState.swift`

- 注释掉 MobileCoin import
- 新增 `isRobotThread` 字段

---

## 60. `Signal/ConversationView/Components/CVComponentThreadDetails.swift`

添加 `isRobotThread` 标志，robot 账户禁用标题点击跳转。

---

## 61. `Signal/ConversationView/Loading/CVItemViewState.swift`

新增 GExt tag 渲染逻辑，在消息发送者名旁显示 GExtTagsStackView。

---

## 62. `Signal/Calls/UserInterface/CallsListViewController.swift`

- 禁用 Call Links 获取
- 隐藏"创建通话链接"入口

---

## 63. `Signal/Calls/UserInterface/CallsListViewController+ViewModelLoader.swift`

清除 upcoming call link 引用（Call Links 功能禁用）。

---

## 64. `Signal/Megaphones/ExperienceUpgradeManager.swift`

禁用备份相关提示横幅（`backupKeyReminder`、`enableBackupsReminder`、`haveEnabledBackupsNotification` 返回 nil）。

---

## 65. `Signal/Megaphones/UserInterface/BackupEnablementMegaphone.swift`

禁用备份引导流程：直接 dismiss，不启动备份流程。

---

## 66. `Signal/Megaphones/UserInterface/InactivePrimaryDeviceReminderMegaphone.swift`

禁用"了解更多"按钮，防止跳转 support URL。

---

## 67. `Signal/Megaphones/UserInterface/RecoveryKeyReminderMegaphone.swift`

禁用恢复密钥提醒：移除 BackupsReminderCoordinator 逻辑，直接 dismiss。

---

## 68. `Signal/Megaphones/UserInterface/RemoteMegaphone.swift`

`donate` / `donateFriend` megaphone 动作替换为 `break`（禁用捐赠横幅）。

---

## 69. `Signal/Provisioning/UserInterface/LinkAndSyncProvisioningProgressViewController.swift`

"了解更多" support URL 链接指向 `about:blank`。

---

## 70. `Signal/Provisioning/UserInterface/ProvisioningQRCodeViewController.swift`

Support URL 链接禁用。

---

## 71. `Signal/Provisioning/UserInterface/ProvisioningTransferChoiceViewController.swift`

"了解更多" support URL 链接指向 `about:blank`。

---

## 72. `Signal/QRCodes/QRCodeView.swift`

QR 码预览 URL 调整（与 support URL 替换相关）。

---

## 73. `Signal/Registration/RegistrationCoordinatorBackupErrorPresenter.swift`

Support URL 全部替换为 `about:blank`。

---

## 74. `Signal/Registration/UserInterface/RegistrationChooseRestoreMethodViewController.swift`

从备份恢复按钮禁用/注释掉。

---

## 75. `Signal/Registration/UserInterface/RegistrationEnterAccountEntropyPoolViewController.swift`

"了解更多" support 链接指向 `about:blank`。

---

## 76. `Signal/Registration/UserInterface/RegistrationPhoneNumberViewController.swift`

代理设置入口禁用。

---

## 77. `Signal/Registration/UserInterface/RegistrationPinAttemptsExhaustedAndMustCreateNewPinViewController.swift`

learnMoreButton 从 stackView 注释掉（入口隐藏），`didTapLearnMoreButton()` 函数体也注释掉。

---

## 78. `Signal/Registration/UserInterface/RegistrationPinViewController.swift`

Support URL 链接禁用。

---

## 79. `Signal/Registration/UserInterface/RegistrationProfileViewController.swift`

Profile FAQ support 链接禁用。

---

## 80. `Signal/Registration/UserInterface/RegistrationReglockTimeoutViewController.swift`

learnMoreButton 从 stackView 注释掉（入口隐藏），`didTapLearnMoreButton()` 函数体也注释掉。

---

## 81. `Signal/Registration/UserInterface/RegistrationVerificationCodeView.swift`

自动填充逻辑调整。

---

## 82. `Signal/src/ViewControllers/AppSettings/Account/AdvancedPinSettingsTableViewController.swift`

MobileCoin 支付相关代码禁用/注释掉。

---

## 83. `Signal/src/ViewControllers/AppSettings/Account/DeleteAccountConfirmationViewController.swift`

转移支付禁用（MobileCoin 移除）。

---

## 84. `Signal/src/ViewControllers/AppSettings/Account/RequestAccountDataReportViewController.swift`

Support URL 指向 `about:blank`。

---

## 85. `Signal/src/ViewControllers/AppSettings/Appearance/AppIconSettingsTableViewController.swift`

App 图标设置 footer 中的 support URL 链接指向 `about:blank`。

---

## 86. `Signal/src/ViewControllers/AppSettings/Donations/DonationSettingsViewController.swift`

捐赠按钮和 gift 功能禁用。

---

## 87. `Signal/src/ViewControllers/AppSettings/Internal/InternalSettingsViewController.swift`

- Backups section 禁用
- MobileCoin 环境配置禁用

---

## 88. `Signal/src/ViewControllers/AppSettings/Internal/TestingViewController.swift`

MobileCoin import 注释掉。

---

## 89. `Signal/src/ViewControllers/AppSettings/Linked Devices/LinkedDevicesView.swift`

禁用"了解更多"链接，防止跳转 support URL。

---

## 90. `Signal/src/ViewControllers/AppSettings/Linked Devices/LinkedDevicesEducationSheet.swift`

下载链接：`signal.org` → `ba-chat.com`。

---

## 91. `Signal/src/ViewControllers/AppSettings/Privacy/PrivacySettingsViewController.swift`

- 禁用 MobileCoin 支付设置入口
- 禁用高级隐私设置中的部分 support 链接

---

## 92. `Signal/src/ViewControllers/AppSettings/Profile/ProfileSettingsViewController.swift`

Badge 配置 section 禁用。

---

## 93. `Signal/src/ViewControllers/Attachment Keyboard/AttachmentFormatPickerView.swift`

新增 `msgButtonVisible: GExtRobot.MsgButtonVisible?` 参数，通过 `isVisible(_:)` 方法按机器人配置过滤附件格式按钮：

| `msgButtonVisible` 字段 | 为 `false` 时过滤 |
|------------------------|-----------------|
| `photos` | .photo |
| `gif` | .gif |
| `file` | .file |
| `contact` | .contact |
| `location` | .location |

---

## 94. `Signal/src/ViewControllers/Attachment Keyboard/AttachmentKeyboard.swift`

集成 `GExtRobot.msgButtonVisible`，根据机器人配置隐藏附件键盘中的按钮。

---

## 95. `Signal/src/ViewControllers/DebugUI/DebugUIMisc.swift`

MobileCoin import 注释掉。

---

## 96. `Signal/src/ViewControllers/Donations/BadgeDetailsSheet.swift`

捐赠按钮和捐赠流程禁用。

---

## 97. `Signal/src/ViewControllers/Donations/DonationViewsUtil.swift`

support 联系过滤器禁用。

---

## 98. `Signal/src/ViewControllers/Donations/DonationViewsUtil+IDEAL.swift`

IDEAL 捐赠流程禁用。

---

## 99. `Signal/src/ViewControllers/GetStartedBannerViewController.swift`

禁用 `inviteFriends` case。

---

## 100. `Signal/src/ViewControllers/HomeView/Chat List/ChatListCell.swift`

会话列表单元格新增 GExt tags 显示支持。

---

## 101. `Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController.swift`

- 新增 LinkBAPlatform 导航 case
- 禁用 MobileCoin 支付设置导航
- iOS 26 标签栏兼容处理

---

## 102. `Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController+BackupDownloadProgressView.swift`

Action sheet 中"了解更多"ActionSheetAction 整块注释掉（入口隐藏）。

---

## 103. `Signal/src/ViewControllers/HomeView/Chat List/CLVTableDataSource.swift`

会话列表单元格中，联系人和群组名称旁显示 GExtTagsStackView。

---

## 104. `Signal/src/ViewControllers/HomeView/HomeTabBarController.swift`

保存/恢复 tab bar 帧逻辑，修复 iOS 26 浮动 tab bar 在显示/隐藏时的帧漂移问题：
- 新增 `_savedTabBarFrame: CGRect?` 字段
- 隐藏前保存帧，恢复时使用保存的帧而非重新计算

---

## 105. `Signal/src/ViewControllers/HomeView/HomeTabViewController.swift`

禁用支付未读角标（MobileCoin 移除）。

---

## 106. `Signal/src/ViewControllers/NameEducationSheet.swift`

将 BonMot 样式替换为手动 attributed string 构建。

---

## 107. `Signal/src/ViewControllers/NewGroupView/NewGroupConfirmViewController.swift`

禁用"了解更多"按钮和 support URL 导航。

---

## 108. `Signal/src/ViewControllers/OWSPinSetupViewController.swift`

- `moreButton` 从视图层级注释掉（`view.addSubview(moreButton)` 及布局约束注释掉）
- Action sheet 中"了解更多"ActionSheetAction 注释掉

---

## 109. `Signal/src/ViewControllers/Payments/SendPaymentCompletionActionSheet.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 110. `Signal/src/ViewControllers/Payments/SendPaymentHelper.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 111. `Signal/src/ViewControllers/Payments/SendPaymentMemoViewController.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 112. `Signal/src/ViewControllers/Payments/SendPaymentViewController.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 113. `Signal/src/ViewControllers/Photos/PhotoCaptureViewController.swift`

新增 `baxs://` 协议处理，支持 LinkBaPay 扫码入口。

---

## 114. `Signal/src/ViewControllers/ThreadSettings/ConversationHeaderBuilder.swift`

- 机器人账户检测
- 显示 GExtTagsStackView
- 新增"复制群组 ID"行
- 机器人账户禁用通话按钮

---

## 115. `Signal/src/ViewControllers/ThreadSettings/ConversationSettingsViewController.swift`

新增 `isRobotThread` 属性，通过 `GExtTagStore` 判断当前会话是否为机器人账户。

---

## 116. `Signal/src/ViewControllers/ThreadSettings/DisappearingMessagesTimerSettingsViewController.swift`

新增 `@preconcurrency` import（并发兼容）。

---

## 117. `Signal/src/views/ExpirationNagView.swift`

Support URL 导航指向 `about:blank`。

---

## 118. `Signal/src/views/GetStartedBannerCell.swift`

禁用 `inviteFriends` case。

---

## 119. `Signal/Usernames/Selection/UsernameSelectionViewController.swift`

URL scheme：`sgnl://` → `baxs://`。

---

## 120. `SignalServiceKit/Attachments/SignalAttachment.swift`

默认附件名称：`"signal"` → `"ba"`。

---

## 121. `SignalServiceKit/Messages/Attachments/V2/Playback/AVAsset+Attachment.swift`

```swift
// 原：private static let customScheme = "signal"
// 改为：
private static let customScheme = "ba"
```

---

## 122. `SignalServiceKit/Calls/CallHTTPClient.swift`

安全策略改为系统默认（禁用 Signal 自定义证书验证）。

---

## 123. `SignalServiceKit/Groups/TSGroupModel.swift`

群组分享 URL：`signal.group` → `group.baxs.com`。

---

## 124. `SignalServiceKit/Messages/Interactions/LinkPreview/Manager/LinkPreviewHelper.swift`

群组链接域名：`signal.org` → `baxs.com`。

---

## 125. `SignalServiceKit/Messages/Interactions/TSInfoMessage+GroupUpdates+DisplayableGroupUpdateItem.swift`

禁用群组链接推广更新提示。

---

## 126. `SignalServiceKit/Network/API/Requests/Registration/RegistrationRequestFactory.swift`

`ApnRegistrationId` 结构新增 `voipToken` 参数。

---

## 127. `SignalServiceKit/Profiles/BadgeAssets.swift`

禁用 badge sprite 下载。

---

## 128. `SignalServiceKit/Profiles/BadgeStore.swift`

Badge URL：`signal.org` → `ba-chat.com`。

---

## 129. `SignalServiceKit/Storage/Database/SDSDatabaseStorage/SDSDatabaseStorage.swift`

弱引用处理从原生 Swift `weak` 改为自定义 `Weak()` 包装类型。

---

## 130. `SignalServiceKit/Subscriptions/Donations/Paypal+WebAuthentication.swift`

URL scheme：`sgnl://` → `baxs://`。

---

## 131. `SignalServiceKit/Subscriptions/Donations/Stripe.swift`

URL scheme：`sgnl://` → `baxs://`。

---

## 132. `SignalServiceKit/Subscriptions/Donations/Stripe+3DSecure.swift`

支付 scheme：`sgnlpay` → `baxspay`。

---

## 133. `SignalServiceKit/Util/OWSPaymentsLock.swift`

支付锁错误处理调整（与 MobileCoin 移除相关的兼容改动）。

---

## 134. `SignalServiceKit/Util/Preferences.swift`

新增 `voipToken` 存储字段。

---

## 135. `SignalNSE/NotificationService.swift`

- `bestAttemptContent` 角标赋值
- 统一复用 `bestAttemptContent` 而不是每次创建新对象

---

## 136. `SignalNSE/NSECallMessageHandler.swift`

- VoIP token 处理逻辑调整
- 禁用 CXProvider
- 新增服务器端 VoIP push 支持

---

## 137. `SignalNSE/SignalNSE.entitlements`

App Groups bundle 前缀改为 `$(SIGNAL_BUNDLEID_PREFIX)`（与主 app 一致）。

---

## 138. `SignalNSE/SignalNSE-AppStore.entitlements`

同 `SignalNSE.entitlements`。

---

## 139. `SignalShareExtension/Info.plist`

域名：`signal.org` → `baxs.com`。

---

## 140. `SignalShareExtension/SAEFailedViewController.swift`

错误页面标题：`"Signal"` → `"B&A"`。

---

## 141. `SignalShareExtension/SignalShareExtension.entitlements`

App Groups bundle 前缀改为 `$(SIGNAL_BUNDLEID_PREFIX)`。

---

## 142. `SignalShareExtension/SignalShareExtension-AppStore.entitlements`

同 `SignalShareExtension.entitlements`。

---

## 143. `SignalUI/AppLaunch/SUIEnvironment.swift`

`PaymentsImpl` 替换为 `MockPayments`（MobileCoin 移除）。

---

## 144. `SignalUI/Calls/CallLink.swift`

- 通话链接域名：`signal.link` → `link.baxs.com`
- URL scheme：`sgnl://` → `baxs://`

---

## 145. `SignalUI/Payments/DebugLogger+Payments.swift`

整个 section 注释掉（MobileCoin 移除）。

---

## 146. `SignalUI/Payments/MobileCoinAPI+Configuration.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 147. `SignalUI/Payments/MobileCoinHelperSDK.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 148. `SignalUI/Payments/PaymentsFormat+MobileCoin.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 149. `SignalUI/Payments/PaymentsProcessor.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 150. `SignalUI/Payments/PaymentsReconciliation.swift`

整个文件注释掉（MobileCoin 移除）。

---

## 151. `SignalUI/RecipientPickers/ContactsViewHelper.swift`

`presentContactAccessNotAllowedAlert()` 中"了解更多"ActionSheetAction 整块注释掉（入口按钮隐藏），`presentContactAccessNotAllowedLearnMore()` 函数体也注释掉。

---

## 152. `SignalUI/RecipientPickers/InviteFlow.swift`

邀请链接 URL：`signal.org` → `ba-chat.com`。

---

## 153. `SignalUI/RecipientPickers/RecipientPickerViewController.swift`

禁用"邀请联系人"入口（invite contacts section 隐藏）。

---

## 154. `SignalUI/SafetyNumbers/FingerprintViewController.swift`

- Action sheet 中"了解更多"ActionSheetAction 整块注释掉（入口隐藏）
- `learnMoreString` 设为空字符串，instructions 文字中不渲染链接
- `showLearnMoreUrl()` 函数体注释掉

---

## 155. `SignalUI/Sending/DraftQuotedReplyModel+Payments.swift`

`PaymentsFormat` 调用注释掉（MobileCoin 移除）。

---

## 156. `SignalUI/Stories/ConnectionsEducationSheetViewController.swift`

将 BonMot 样式替换为手动 attributed string 构建。

---

## 157. `SignalUI/Utils/GroupViewUtils.swift`

`showInvalidGroupMemberAlert()` 中"了解更多"ActionSheetAction 整块注释掉（入口按钮隐藏），`showCantAddMemberView()` 函数体也注释掉（不跳转 support.signal.org/groups）。

---

## 158. `SignalUI/ViewControllers/OWSTableViewController2.swift`

新增 iOS 19 兼容性检查。

---

## 159. `SignalUI/ViewControllers/ScanQRCodeViewController.swift`

QR 码解析新增 ECI 模式支持；新增 `resetAndStartScanning` 方法。

---

## MobileCoin 支付 UI 文件（整体注释掉）

以下文件全部整体注释掉（MobileCoin 移除）：

```
Signal/src/ViewControllers/AppSettings/Payments/ArchivedPaymentHistoryItem.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentModelCell.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsBiometryLockPromptViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsDeactivateViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsDetailViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsHistory.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsHistoryViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsQRScanViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletCompleteViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletPasteboardViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletSplashViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsRestoreWalletWordViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsSendRecipientViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsSettingsViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsTransferInViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsTransferOutViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseConfirmViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseGridViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewPassphraseSplashViewController.swift
Signal/src/ViewControllers/AppSettings/Payments/PaymentsViewUtils.swift
Signal/src/ViewControllers/AppSettings/Payments/TSPaymentModelHistoryItem.swift
```

---

## 160. `Signal/Images.xcassets/signal-logo-40.imageset/Contents.json`

图标内容配置更新，引用 `BA-app-no-padding.svg` 替换原 Signal logo。

---

## 161. `Signal/Images.xcassets/signal-logo-128-launch-screen.imageset/Contents.json`

启动画面 logo 资源配置更新：原 `signal-logo-ultramarine.pdf` / `signal-logo-white.pdf` 替换为 `icon_64x64@2x.png` / `icon_64x64@2x 1.png`。

## 162. `Signal/src/ViewControllers/HomeView/Chat List/ChatListViewController+Loading.swift`

修复 iOS 26 Release 构建下聊天列表 cell 滑动操作（静音、置顶、归档等）必崩的 bug。

`applyRowChanges` 中的本地闭包 `checkAndSetTableUpdates` 原本用 `[weak self]` 捕获，在 iOS 26 Release 优化下弱引用被污染为 tagged pointer 值（`0xf000000000000024`），导致 `objc_loadWeakRetained` 绕过 nil 检查并返回无效指针，访问 `self.viewState` 时触发 `EXC_BAD_ACCESS`。

由于该闭包不逃逸（仅在同一函数体内同步调用），`[weak self]` 完全多余，移除后改为隐式强引用即可。


## 163. `SignalServiceKit/Network/OWSSignalService.swift`

修复图片、视频发送失败及收到后无法打开的问题。

CDN session 原本使用 `shouldUseSignalCertificate: true`，即用 `signal-messenger.cer`（`CN=*.imba-test.com` / RapidSSL 签发）做证书 pinning。但 BA CDN 服务器（`cdn.ba-chat.com`、`cdn2.ba-chat.com`）实际使用 Amazon / Google 公信 CA 签发的证书，导致所有 TLS handshake 失败，附件上传下载全部被拒。

改为 `shouldUseSignalCertificate: false`，使用系统信任链验证即可，与主服务、Storage Service、SVR2 等其他 session 保持一致。

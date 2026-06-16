# 自定义改动记录

每次合并上游 tag 时，用以下命令确认所有自定义内容没有被覆盖：

```bash
git diff <new-tag> HEAD --name-only
git diff <new-tag> HEAD -- \
  SignalServiceKit/Environment/TSConstants.swift \
  SignalServiceKit/Network/API/Requests/OWSRequestFactory.swift \
  SignalServiceKit/Network/API/SignalServiceProfile.swift \
  SignalServiceKit/Network/OutageDetection.swift \
  SignalServiceKit/Network/OWSSignalServiceProtocol.swift \
  SignalServiceKit/Network/SignalProxy/SignalProxy.swift \
  SignalServiceKit/Network/OWSUrlSession.swift \
  SignalServiceKit/Network/ChatConnectionManager.swift \
  SignalServiceKit/Resources/schema.sql \
  SignalServiceKit/Storage/Database/GRDBSchemaMigrator.swift \
  Signal/Signal-Info.plist Signal/Signal.entitlements \
  Signal/translations/
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

## 1. 服务器 / 网络配置

### `SignalServiceKit/Environment/TSConstants.swift`

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
| `legalTermsUrl` | `https://signal.org/legal/` | `\(textSecureCDN0ServerURL)/legal/index.html`（动态拼接）|
| `appStoreUrl` | `id874139669`（Signal） | `id6754267880`（B&A） |
| `updatesURL` | `https://updates.signal.org` | 已移除 |
| `updates2URL` | `https://updates2.signal.org` | 已移除 |
| `registrationCaptchaURL` | `https://signalcaptchas.org/registration/generate.html` | 已移除 |
| `challengeCaptchaURL` | `https://signalcaptchas.org/challenge/generate.html` | 已移除 |
| `kUDTrustRoots` | Signal 信任根 | 已移除 |

**注释：**
- 所有服务器端点指向 `ba-chat.com` 域名
- 隐私政策链接从独立域名改为 CDN 路径
- 移除了 captcha、updates、trust roots 等 Signal 官方服务相关配置

---

## 2. SSL 证书验证

### `SignalServiceKit/Network/OWSSignalServiceProtocol.swift`

```swift
// 所有 OWSHTTPSecurityPolicy 的 shouldUseSignalCertificate 参数改为 false
shouldUseSignalCertificate: false
```

**5 处修改**：禁用 Signal 官方证书固定，允许使用自定义 TLS 证书（ba-chat.com）

### `SignalServiceKit/Network/OWSUrlSession.swift`

新增网络请求/响应日志记录：
```swift
NetworkRequestLogger.shared.logRequest(logRequest)
NetworkRequestLogger.shared.logResponse(response, for: rawRequest)
```

### `SignalServiceKit/Network/ChatConnectionManager.swift`

WebSocket 请求/响应增加日志记录：
```swift
NetworkRequestLogger.shared.logRequest(request)
NetworkRequestLogger.shared.logResponse(response, for: request)
NetworkRequestLogger.shared.logError(error, for: request)
```

---

## 3. 停机检测

### `SignalServiceKit/Network/OutageDetection.swift`

**移除 Signal 官方停机检测逻辑**：
- 删除 `uptime.signal.org` DNS 解析代码（`CFHostCreateWithName` / `CFHostStartInfoResolution`）
- 相关代码块完整移除（约 30 行）

---

## 4. 深度链接协议

### `SignalServiceKit/Network/SignalProxy/SignalProxy.swift`

```swift
// 原：scheme.caseInsensitiveCompare("sgnl") == .orderedSame
scheme.caseInsensitiveCompare("baxs") == .orderedSame
```

**影响**：`sgnl://` 协议改为 `baxs://`

---

## 5. API 端点扩展

### `SignalServiceKit/Network/API/Requests/OWSRequestFactory.swift`

新增 **4 个自定义 API 端点**：

1. **VoIP Push 注册**
   ```swift
   public static func registerForVoipPushRequest() -> TSRequest
   ```

2. **VoIP Push 注销**
   ```swift
   public static func unregisterFromVoipPushRequest() -> TSRequest
   ```

3. **群组 ExtTag 获取**
   ```swift
   public static func getGroupExtTagsRequest(groupId: Data) -> TSRequest
   // 路由: GET /v1/gext/group/profile/{base64UrlGroupId}
   ```

4. **LinkBaPay API 集合**
   ```swift
   // 获取 BA 用户信息
   public static func linkBaPayGetBaUserInfoRequest() -> TSRequest

   // 请求关联
   public static func linkBaPayRequestLinkRequest(baAppUserId: String, qrCode: String) -> TSRequest

   // 获取关联结果
   public static func linkBaPayGetLinkResultRequest(requestId: String) -> TSRequest

   // 获取已关联用户信息
   public static func linkBaPayGetLinkedBaUserInfoRequest() -> TSRequest
   ```

---

## 6. Profile 数据扩展

### `SignalServiceKit/Network/API/SignalServiceProfile.swift`

```swift
public let gextTags: [GExtTag]?
public let gextRobot: GExtRobot?
```

Profile 响应增加 GExt 标签和机器人信息字段

---

## 7. 数据库 Schema

### `SignalServiceKit/Resources/schema.sql`

新增 **2 个自定义表**：

#### `gext_recipient` - 用户 ExtTag 表
```sql
CREATE TABLE gext_recipient (
    _id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    aci TEXT UNIQUE NOT NULL,
    tags BLOB NOT NULL,
    last_updated INTEGER NOT NULL,
    robot BLOB
);
```

#### `gext_groups` - 群组 ExtTag 表
```sql
CREATE TABLE gext_groups (
    _id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    group_id TEXT UNIQUE NOT NULL,
    tags BLOB NOT NULL,
    last_updated INTEGER NOT NULL
);
```

### `SignalServiceKit/Storage/Database/GRDBSchemaMigrator.swift`

注册 **3 个自定义迁移**：
```swift
case createGExtTagTables        // 创建 gext_recipient 表
case createGExtGroupTagTables   // 创建 gext_groups 表
case addGExtRecipientRobotColumn // gext_recipient 表增加 robot 列
```

---

## 8. GExt 功能（标签 & 机器人）

### 核心类型定义

**`SignalServiceKit/GExt/GExtTag.swift`** — ExtTag 类型定义
```swift
public struct GExtTag: Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let backgroundColor: String
    public let textColor: String
}
```

**`SignalServiceKit/GExt/GExtRobot.swift`** — 机器人信息定义
```swift
public struct GExtRobot: Codable, Equatable {
    public struct Button: Codable, Equatable {
        public let label: String
        public let value: String
    }
    public let buttons: [Button]
    public let hideMessageRequestActions: Bool
}
```

### 数据存储

**`SignalServiceKit/GExt/GExtTagRecord.swift`** — GRDB Record 封装（用户标签）

**`SignalServiceKit/GExt/GGroupGExtTagRecord.swift`** — GRDB Record 封装（群组标签）

**`SignalServiceKit/GExt/GExtTagStore.swift`** — 统一数据访问层
```swift
public func getRecipientExtTags(aci: Aci, tx: DBReadTransaction) -> [GExtTag]?
public func setRecipientExtTags(aci: Aci, tags: [GExtTag], robot: GExtRobot?, tx: DBWriteTransaction)
public func getGroupExtTags(groupId: Data, tx: DBReadTransaction) -> [GExtTag]?
public func setGroupExtTags(groupId: Data, tags: [GExtTag], tx: DBWriteTransaction)
```

### 网络同步

**`SignalServiceKit/GExt/GExtGroupProfileFetcher.swift`** — 群组标签获取器
- Actor-based 并发模型
- 去重逻辑防止重复请求
- 从服务器拉取群组 ExtTag 并存储到本地数据库

**`SignalServiceKit/GExt/LinkBaPayService.swift`** — LinkBaPay 服务封装（预留）

---

## 9. UI 组件

### `SignalUI/Views/GExt/GExtTagView.swift`

单个 ExtTag 徽章 UI 组件：
- 圆角胶囊样式
- 支持自定义背景色、文字色
- 自动计算尺寸

### `SignalUI/Views/GExt/GExtTagsStackView.swift`

ExtTag 列表布局组件：
- 水平排列，自动换行
- 支持设置最大行数
- 支持 Dark Mode

---

## 10. 关联设备 UI

### `Signal/src/ViewControllers/AppSettings/Linked Devices/LinkBAPlatformViewController.swift`

关联 BA 平台账号的 ViewController（新增功能入口）

### `Signal/src/ViewControllers/AppSettings/Linked Devices/ScanBaQRCodeViewController.swift`

扫描 BA 平台二维码的 ViewController

---

## 11. 应用标识

### `Signal/Signal-Info.plist`

| 字段 | 原始 | 自定义 |
|------|------|--------|
| `CFBundleDisplayName` | Signal | B&A |
| `CFBundleIdentifier` | `org.whispersystems.signal` | `com.baxs.ba` |
| `CFBundleShortVersionString` | 7.79（继承） | 7.79 |
| `CFBundleURLSchemes` | `["sgnl"]` | `["baxs"]` |

### Entitlements（所有目标）

**Signal/Signal.entitlements** / **Signal-AppStore.entitlements**:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:baxs.com</string>
    <string>applinks:group.baxs.com</string>
    <string>applinks:sticker.baxs.com</string>
</array>

<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.baxs.ba</string>
</array>
```

**SignalNSE** / **SignalShareExtension**（相同模式）:
- Associated domains: `*.baxs.com`
- App Groups: `group.com.baxs.ba`

---

## 12. 多语言（Signal/translations/）

### Localizable.strings（45 个语言）

所有语言文件中的 Signal 品牌词均已替换：

| 原始内容 | 替换为 |
|---------|--------|
| `Signal`（品牌名） | `B&A` |
| `signal.org` | `baxs.com` / `ba-chat.com` |
| `support@signal.org` | `support@baxs.com` |
| `Signal Call` | `B&A Call` |
| `Invite to Signal` | `Invite to B&A` |
| `Signal Backups` | `B&A Backups` |

**注意**：
- 非品牌名的 signal 单词（如"信号强度"）保持不变
- 法语 `signaler`（动词"报告"）、瑞典语 `ringsignal`（名词"铃声"）不是品牌名，保持不变

### InfoPlist.strings（45 个语言）

系统权限提示文案全部替换：
```
NSCameraUsageDescription = "Signal uses your camera..." → "B&A uses your camera..."
NSMicrophoneUsageDescription = "Signal needs access..." → "B&A needs access..."
（共 9 个权限字段，每个语言）
```

---

## 13. UI 修改

### `Signal/ConversationView/MessageRequestView.swift`

**隐藏"了解更多"链接**（2 处）：
```swift
// appendLearnMoreLink = true
appendLearnMoreLink = false  // 注释掉，防止跳转到 signal.org
```

### `SignalUI/Appearance/Theme+Icons.swift`

新增自定义图标：
```swift
public static let linkBa = UIImage(named: "link_ba")!
```

---

## 14. 资源文件

### `Signal/Symbols.xcassets/link_ba/`

新增 BA 关联图标：
- `link_ba.imageset/link_ba.pdf`
- 支持 Dark Mode / Light Mode

### `Signal/AppIcon.xcassets/`

所有应用图标替换为 B&A 品牌图标（多尺寸 + Dark/Tinted 变体）

---

## 15. 构建脚本

### `ci_scripts/tag_template.txt`

Git tag 模板从 Signal 官方格式改为 BA 自定义格式

---

## 验证清单

合并新版本 tag 后，逐项检查：

- [ ] TSConstants 服务器 URL 全部指向 `ba-chat.com`
- [ ] 证书固定已禁用（`shouldUseSignalCertificate: false`）
- [ ] GExt 数据库表存在（`gext_recipient` / `gext_groups`）
- [ ] GExt 迁移已注册（GRDBSchemaMigrator）
- [ ] 深度链接协议为 `baxs://`
- [ ] Bundle ID 为 `com.baxs.ba`
- [ ] Associated domains 为 `*.baxs.com`
- [ ] 所有翻译文件 Signal→B&A 替换完整（45 语言 × 2 文件类型）
- [ ] InfoPlist.strings 权限文案无 Signal 残留
- [ ] 应用图标为 B&A 品牌
- [ ] MessageRequestView 了解更多链接已禁用
- [ ] GExt 自定义文件全部存在（12 个）
- [ ] LinkBA 相关 API 端点已添加（OWSRequestFactory）
- [ ] 编译通过且无警告

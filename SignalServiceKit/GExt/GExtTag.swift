//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

/// 单个 GExtTag 的数据模型，与服务器字段一一对应
public struct GExtTag: Codable, Equatable, Hashable {
    /// 标签唯一标识
    public let tagId: String

    /// 标签类型：0=文本标签，1=图片标签，2=混合标签
    public let tagType: Int

    /// 文本内容（tagType=0 或 2 时有效）
    public let text: String?

    /// Base64 编码的图片数据（tagType=1 或 2 时有效）
    public let imgBase64: String?

    // MARK: - CSS 样式字段

    /// 背景色，格式：#RRGGBB 或 #RRGGBBAA
    public let cssBackgroundColor: String?

    /// 文字颜色，格式：#RRGGBB 或 #RRGGBBAA
    public let cssColor: String?

    /// 整体透明度，范围 0.0~1.0
    public let cssOpacity: Double?

    /// 边框宽度（点数）
    public let cssBorderWidth: Double?

    /// 圆角半径（点数）
    public let cssBorderRadius: Double?

    /// 边框颜色，格式：#RRGGBB 或 #RRGGBBAA
    public let cssBorderColor: String?

    /// 边框样式：solid / dashed / dotted / double / none / hidden / groove / ridge / inset / outset
    public let cssBorderStyle: String?

    public init(
        tagId: String,
        tagType: Int,
        text: String? = nil,
        imgBase64: String? = nil,
        cssBackgroundColor: String? = nil,
        cssColor: String? = nil,
        cssOpacity: Double? = nil,
        cssBorderWidth: Double? = nil,
        cssBorderRadius: Double? = nil,
        cssBorderColor: String? = nil,
        cssBorderStyle: String? = nil
    ) {
        self.tagId = tagId
        self.tagType = tagType
        self.text = text
        self.imgBase64 = imgBase64
        self.cssBackgroundColor = cssBackgroundColor
        self.cssColor = cssColor
        self.cssOpacity = cssOpacity
        self.cssBorderWidth = cssBorderWidth
        self.cssBorderRadius = cssBorderRadius
        self.cssBorderColor = cssBorderColor
        self.cssBorderStyle = cssBorderStyle
    }
}

/// 个人 GExtTag Profile（预留）
public struct UserGExtTagProfile: Codable {
    public let extTags: [GExtTag]
}
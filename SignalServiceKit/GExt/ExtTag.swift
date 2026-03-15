//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

/// 单个 ExtTag 的数据模型，与服务器字段一一对应
public struct ExtTag: Codable, Equatable, Hashable {
    /// 标签唯一标识
    public let tagId: String

    /// 标签类型：1=文本标签，2=图片标签，3=混合标签
    public let tagType: Int

    /// 文本内容（tagType=1 或 3 时有效）
    public let text: String?

    /// Base64 编码的图片数据（tagType=2 或 3 时有效）
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

    // MARK: - 便利属性

    /// 将 imgBase64 解码为 UIImage（耗时操作，调用方自行缓存）
    public var image: UIImage? {
        guard let base64 = imgBase64,
              let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }
}

/// 服务器返回的群组 ExtTag Profile
public struct GroupExtTagProfile: Codable {
    public let extTags: [ExtTag]
}

/// 个人 ExtTag Profile（预留）
public struct UserExtTagProfile: Codable {
    public let extTags: [ExtTag]
}
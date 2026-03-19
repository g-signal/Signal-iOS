//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
public import SignalServiceKit

public class GExtTagsStackView: UIStackView {

    private var extTags: [GExtTag] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }

    private func setupStackView() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 4

        // 设置较低的 hugging priority，允许在需要时扩展
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    public func configure(with extTags: [GExtTag]) {
        self.extTags = extTags
        updateTagViews()
    }

    private func updateTagViews() {
        // 清除现有的标签视图
        arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加新的标签视图
        for extTag in extTags {
            let tagView = GExtTagView(extTag: extTag)
            addArrangedSubview(tagView)

            // 确保标签视图不被压缩
            tagView.setContentCompressionResistancePriority(.required, for: .horizontal)
            tagView.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        // ManualStackView 通过 isHidden 过滤子视图，所以空时需要隐藏
        isHidden = extTags.isEmpty
    }

    public var isEmpty: Bool {
        return extTags.isEmpty
    }

    // MARK: - 便利方法

    /// 从用户地址获取并配置标签
    public func configureForUser(_ address: SignalServiceAddress, transaction: DBReadTransaction) {
        let tags = GExtTagStore.shared.getUserExtTags(for: address, transaction: transaction)
        configure(with: tags)
    }

    /// 计算标签容器的理想大小（静态版本，用于 ManualStackView 测量阶段）
    public static func preferredSize(for extTags: [GExtTag]) -> CGSize {
        guard !extTags.isEmpty else { return .zero }
        var totalWidth: CGFloat = 0
        var maxHeight: CGFloat = 18
        for (index, extTag) in extTags.enumerated() {
            let tagSize = tagSize(for: extTag)
            totalWidth += tagSize.width
            maxHeight = max(maxHeight, tagSize.height)
            if index < extTags.count - 1 {
                totalWidth += 4 // spacing
            }
        }
        return CGSize(width: totalWidth, height: maxHeight)
    }

    /// 计算标签容器的理想大小
    public func calculatePreferredSize() -> CGSize {
        return Self.preferredSize(for: extTags)
    }

    private static func tagSize(for extTag: GExtTag) -> CGSize {
        switch extTag.tagType {
        case 0: // 纯文本
            if let text = extTag.text {
                let font = UIFont.systemFont(ofSize: 12, weight: .medium)
                let textSize = text.size(withAttributes: [.font: font])
                return CGSize(width: textSize.width + 12, height: 18)
            }
            return CGSize(width: 20, height: 18)

        case 1: // 纯图片
            return CGSize(width: 18, height: 18)

        case 2: // 文本+图片
            if let text = extTag.text {
                let font = UIFont.systemFont(ofSize: 12, weight: .medium)
                let textSize = text.size(withAttributes: [.font: font])
                return CGSize(width: 14 + 2 + textSize.width + 6 + 2, height: 18)
            }
            return CGSize(width: 22, height: 18)

        default:
            return .zero
        }
    }

    public override var intrinsicContentSize: CGSize {
        // 如果没有标签，返回零宽度（但保持高度以避免布局问题）
        guard !extTags.isEmpty else {
            return CGSize(width: 0, height: 18)
        }
        return calculatePreferredSize()
    }
}
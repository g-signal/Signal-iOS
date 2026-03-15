//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
public import SignalServiceKit

public class ExtTagsStackView: UIStackView {

    private var extTags: [ExtTag] = []

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

        // 确保标签不被压缩
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    public func configure(with extTags: [ExtTag]) {
        self.extTags = extTags
        updateTagViews()
    }

    private func updateTagViews() {
        // 清除现有的标签视图
        arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加新的标签视图
        for extTag in extTags {
            let tagView = ExtTagView(extTag: extTag)
            addArrangedSubview(tagView)

            // 确保标签视图不被压缩
            tagView.setContentCompressionResistancePriority(.required, for: .horizontal)
            tagView.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        // 如果没有标签，隐藏整个容器
        isHidden = extTags.isEmpty
    }

    public var isEmpty: Bool {
        return extTags.isEmpty
    }

    // MARK: - 便利方法

    /// 从群组线程获取并配置标签
    public func configureForGroup(_ thread: TSGroupThread, transaction: SDSAnyReadTransaction) {
        let tags = ExtTagStore.shared.getGroupExtTags(for: thread, transaction: transaction)
        configure(with: tags)
    }

    /// 从用户地址获取并配置标签
    public func configureForUser(_ address: SignalServiceAddress, transaction: SDSAnyReadTransaction) {
        let tags = ExtTagStore.shared.getUserExtTags(for: address, transaction: transaction)
        configure(with: tags)
    }

    /// 计算标签容器的理想大小
    public func calculatePreferredSize() -> CGSize {
        guard !extTags.isEmpty else { return .zero }

        var totalWidth: CGFloat = 0
        var maxHeight: CGFloat = 18 // 默认标签高度

        for (index, extTag) in extTags.enumerated() {
            let tagSize = calculateTagSize(for: extTag)
            totalWidth += tagSize.width
            maxHeight = max(maxHeight, tagSize.height)

            // 添加标签间距
            if index < extTags.count - 1 {
                totalWidth += spacing
            }
        }

        return CGSize(width: totalWidth, height: maxHeight)
    }

    private func calculateTagSize(for extTag: ExtTag) -> CGSize {
        switch extTag.tagType {
        case 1: // 纯文本
            if let text = extTag.text {
                let font = UIFont.systemFont(ofSize: 12, weight: .medium)
                let textSize = text.size(withAttributes: [.font: font])
                return CGSize(width: textSize.width + 12, height: 18)
            }
            return CGSize(width: 20, height: 18)

        case 2: // 纯图片
            return CGSize(width: 18, height: 18)

        case 3: // 文本+图片
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
}
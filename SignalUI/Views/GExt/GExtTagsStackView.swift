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

        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)
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

    /// 从群组 ID 获取并配置标签
    public func configureForGroup(_ groupId: String, transaction: DBReadTransaction) {
        let tags = GExtTagStore.shared.getGroupExtTags(for: groupId, transaction: transaction)
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
            let h: CGFloat = 18
            if let imgBase64 = extTag.imgBase64,
               let naturalSize = GExtTagView.imageSizeFromBase64(imgBase64),
               naturalSize.height > 0 {
                let aspectRatio = naturalSize.width / naturalSize.height
                return CGSize(width: h * aspectRatio, height: h)
            }
            return CGSize(width: h, height: h)

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

// MARK: -

public extension GExtTag {
    /// Renders the tag into a UIImage for use as an NSTextAttachment.
    /// Safe to call off the main thread.
    func renderedAsImage() -> UIImage? {
        guard tagType == 0, let text = text, !text.isEmpty else { return nil }

        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let textColor = cssColor.flatMap { UIColor(gextTagHex: $0) } ?? .white
        let bgColor = cssBackgroundColor.flatMap { UIColor(gextTagHex: $0) } ?? .clear
        let cornerRadius = CGFloat(cssBorderRadius ?? 9)
        let padding: CGFloat = 6
        let textSize = text.size(withAttributes: [.font: font])
        let size = CGSize(width: textSize.width + padding * 2, height: 18)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let opacity = max(0, min(1, CGFloat(cssOpacity ?? 1.0)))
            ctx.cgContext.setAlpha(opacity)

            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

            bgColor.setFill()
            path.fill()

            if let hex = cssBorderColor, let borderColor = UIColor(gextTagHex: hex),
               let borderWidth = cssBorderWidth, borderWidth > 0 {
                borderColor.setStroke()
                path.lineWidth = CGFloat(borderWidth)
                path.stroke()
            }

            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            let textOrigin = CGPoint(x: padding, y: (size.height - textSize.height) / 2)
            text.draw(at: textOrigin, withAttributes: attrs)
        }
    }
}

private extension UIColor {
    convenience init?(gextTagHex hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        if s.count == 6 {
            self.init(red: CGFloat((v & 0xFF0000) >> 16) / 255,
                      green: CGFloat((v & 0x00FF00) >> 8) / 255,
                      blue: CGFloat(v & 0x0000FF) / 255, alpha: 1)
        } else {
            self.init(red: CGFloat((v & 0xFF000000) >> 24) / 255,
                      green: CGFloat((v & 0x00FF0000) >> 16) / 255,
                      blue: CGFloat((v & 0x0000FF00) >> 8) / 255,
                      alpha: CGFloat(v & 0x000000FF) / 255)
        }
    }
}
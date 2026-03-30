//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
public import SignalServiceKit

public class GExtTagsStackView: UIStackView {

    private var extTags: [GExtTag] = []
    private var tagHeight: CGFloat = 18

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

    public func configure(with extTags: [GExtTag], tagHeight: CGFloat = 18) {
        self.extTags = extTags
        self.tagHeight = tagHeight
        updateTagViews()
    }

    private func updateTagViews() {
        // 清除现有的标签视图
        arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加新的标签视图
        for extTag in extTags {
            let tagView = GExtTagView(extTag: extTag, height: tagHeight)
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
    public func configureForUser(_ address: SignalServiceAddress, tagHeight: CGFloat = 18, transaction: DBReadTransaction) {
        let tags = GExtTagStore.shared.getUserExtTags(for: address, transaction: transaction)
        configure(with: tags, tagHeight: tagHeight)
    }

    /// 从群组 ID 获取并配置标签
    public func configureForGroup(_ groupId: String, tagHeight: CGFloat = 18, transaction: DBReadTransaction) {
        let tags = GExtTagStore.shared.getGroupExtTags(for: groupId, transaction: transaction)
        configure(with: tags, tagHeight: tagHeight)
    }

    /// 计算标签容器的理想大小（静态版本，用于 ManualStackView 测量阶段）
    public static func preferredSize(for extTags: [GExtTag], tagHeight: CGFloat = 18) -> CGSize {
        guard !extTags.isEmpty else { return .zero }
        var totalWidth: CGFloat = 0
        for (index, extTag) in extTags.enumerated() {
            let tagSize = tagSize(for: extTag, height: tagHeight)
            totalWidth += tagSize.width
            if index < extTags.count - 1 {
                totalWidth += 4 // spacing
            }
        }
        return CGSize(width: totalWidth, height: tagHeight)
    }

    /// 计算标签容器的理想大小
    public func calculatePreferredSize() -> CGSize {
        return Self.preferredSize(for: extTags, tagHeight: tagHeight)
    }

    private static func tagSize(for extTag: GExtTag, height: CGFloat = 18) -> CGSize {
        let h = height
        let hPad = h * 0.33
        switch extTag.tagType {
        case 0: // 纯文本
            if let text = extTag.text {
                let font = UIFont.systemFont(ofSize: max(8, h * 0.65), weight: .medium)
                let textSize = text.size(withAttributes: [.font: font])
                return CGSize(width: textSize.width + hPad * 2, height: h)
            }
            return CGSize(width: h, height: h)

        case 1: // 纯图片
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
        guard !extTags.isEmpty else {
            return CGSize(width: 0, height: tagHeight)
        }
        return calculatePreferredSize()
    }
}

// MARK: -

public extension GExtTag {
    /// Renders the tag into a UIImage for use as an NSTextAttachment.
    /// Safe to call off the main thread.
    func renderedAsImage(height: CGFloat = 18) -> UIImage? {
        guard tagType == 0, let text = text, !text.isEmpty else { return nil }

        let h = height
        let fontSize = max(8, h * 0.65)
        let padding = h * 0.33
        let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        let textColor = cssColor.flatMap { UIColor(gextTagHex: $0) } ?? .white
        let bgColor = cssBackgroundColor.flatMap { UIColor(gextTagHex: $0) } ?? .clear
        let cornerRadius = CGFloat(cssBorderRadius.map { max(0, min(CGFloat($0), h / 2)) } ?? h / 2)
        let textSize = text.size(withAttributes: [.font: font])
        let size = CGSize(width: textSize.width + padding * 2, height: h)

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
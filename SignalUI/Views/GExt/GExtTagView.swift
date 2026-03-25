//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
public import SignalServiceKit

public class GExtTagView: UIView {

    private let extTag: GExtTag
    private let imageView = UIImageView()
    private let textLabel = UILabel()
    private let borderLayer = CAShapeLayer()
    private var imageNaturalSize: CGSize = CGSize(width: 1, height: 1)

    public init(extTag: GExtTag) {
        self.extTag = extTag
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.clear

        setupTextLabel()
        setupImageView()
        setupStyling()
        setupLayout()

        layer.addSublayer(borderLayer)
    }

    private func setupTextLabel() {
        textLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 1
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.8
        textLabel.text = extTag.text

        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        guard let dataURI = extTag.imgBase64 else { return }

        var base64 = dataURI
        if let commaIndex = base64.range(of: "base64,") {
            base64 = String(base64[commaIndex.upperBound...])
        }
        if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            imageView.image = image
            imageNaturalSize = image.size
        }

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }

    // 从 base64 数据 URI 解析图片自然尺寸
    static func imageSizeFromBase64(_ dataURI: String) -> CGSize? {
        var base64 = dataURI
        if let range = base64.range(of: "base64,") { base64 = String(base64[range.upperBound...]) }
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)?.size
    }

    private func setupLayout() {
        switch extTag.tagType {
        case 0: // 纯文本
            imageView.isHidden = true
            let font = UIFont.systemFont(ofSize: 12, weight: .medium)
            let textWidth = (extTag.text ?? "").size(withAttributes: [.font: font]).width
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                widthAnchor.constraint(equalToConstant: textWidth + 12),
                heightAnchor.constraint(equalToConstant: 18)
            ])

        case 1: // 纯图片
            textLabel.isHidden = true
            let h: CGFloat = 18
            let innerH: CGFloat = h - 4  // 2pt top inset + 2pt bottom inset
            let aspectRatio = imageNaturalSize.height > 0 ? imageNaturalSize.width / imageNaturalSize.height : 1
            let imageW = innerH * aspectRatio
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
                imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                widthAnchor.constraint(equalToConstant: imageW + 4),
                heightAnchor.constraint(equalToConstant: h)
            ])

        default:
            textLabel.isHidden = true
            imageView.isHidden = true
        }
    }

    private func setupStyling() {
        guard extTag.tagType != 1 else { return }

        if let backgroundColor = extTag.cssBackgroundColor {
            self.backgroundColor = UIColor(hex: backgroundColor)
        }

        if let textColor = extTag.cssColor {
            textLabel.textColor = UIColor(hex: textColor)
        } else {
            textLabel.textColor = .white
        }

        if let opacity = extTag.cssOpacity {
            self.alpha = CGFloat(max(0, min(1, opacity)))
        }

        if let radius = extTag.cssBorderRadius {
            layer.cornerRadius = CGFloat(max(0, min(radius, 20)))
            clipsToBounds = true
        } else {
            layer.cornerRadius = 9
            clipsToBounds = true
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateBorderLayer()
    }

    private func updateBorderLayer() {
        guard extTag.tagType != 1 else {
            borderLayer.isHidden = true
            return
        }

        guard let borderWidth = extTag.cssBorderWidth,
              borderWidth > 0 else {
            borderLayer.isHidden = true
            return
        }

        borderLayer.isHidden = false
        borderLayer.path = UIBezierPath(roundedRect: bounds,
                                       cornerRadius: layer.cornerRadius).cgPath
        borderLayer.lineWidth = CGFloat(max(0, min(borderWidth, 10)))
        borderLayer.fillColor = UIColor.clear.cgColor

        if let borderColor = extTag.cssBorderColor {
            borderLayer.strokeColor = UIColor(hex: borderColor)?.cgColor
        } else {
            borderLayer.strokeColor = UIColor.gray.cgColor
        }

        if let borderStyle = extTag.cssBorderStyle {
            switch borderStyle.lowercased() {
            case "dashed":
                borderLayer.lineDashPattern = [NSNumber(value: borderWidth * 2), NSNumber(value: borderWidth)]
            case "dotted":
                borderLayer.lineDashPattern = [NSNumber(value: borderWidth), NSNumber(value: borderWidth)]
            default:
                borderLayer.lineDashPattern = nil
            }
        }
    }
}

private extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        let length = hexString.count
        guard length == 6 || length == 8 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        if length == 6 {
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            self.init(
                red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x000000FF) / 255.0
            )
        }
    }
}

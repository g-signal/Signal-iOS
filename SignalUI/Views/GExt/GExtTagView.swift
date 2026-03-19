//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
import WebKit
public import SignalServiceKit

public class GExtTagView: UIView {

    private let extTag: GExtTag
    private let imageView = UIImageView()
    private let textLabel = UILabel()
    private let borderLayer = CAShapeLayer()

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

        // 判断是否为 SVG，UIImage 不支持 SVG，需要 WKWebView 渲染
        if dataURI.contains("image/svg") {
            if let commaIndex = dataURI.range(of: "base64,") {
                let base64 = String(dataURI[commaIndex.upperBound...])
                SVGImageLoader.load(svgBase64: base64, size: CGSize(width: 18, height: 18)) { [weak self] image in
                    self?.imageView.image = image
                }
            }
        } else {
            var base64 = dataURI
            if let commaIndex = base64.range(of: "base64,") {
                base64 = String(base64[commaIndex.upperBound...])
            }
            if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) {
                imageView.image = UIImage(data: data)
            }
        }

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupLayout() {
        switch extTag.tagType {
        case 0: // 纯文本
            imageView.isHidden = true
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                heightAnchor.constraint(equalToConstant: 18)
            ])

        case 1: // 纯图片
            textLabel.isHidden = true
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
                imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                widthAnchor.constraint(equalToConstant: 18),
                heightAnchor.constraint(equalToConstant: 18)
            ])

        case 2: // 文本+图片
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                imageView.widthAnchor.constraint(equalToConstant: 14),
                imageView.heightAnchor.constraint(equalToConstant: 14),

                textLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 2),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

                heightAnchor.constraint(equalToConstant: 18)
            ])

        default:
            textLabel.isHidden = true
            imageView.isHidden = true
        }
    }

    private func setupStyling() {
        if extTag.tagType != 1, let backgroundColor = extTag.cssBackgroundColor {
            self.backgroundColor = UIColor(hex: backgroundColor)
        }

        if let textColor = extTag.cssColor {
            textLabel.textColor = UIColor(hex: textColor)
        } else {
            textLabel.textColor = .white
        }

        if let opacity = extTag.cssOpacity {
            self.alpha = CGFloat(opacity)
        }

        if let radius = extTag.cssBorderRadius {
            layer.cornerRadius = CGFloat(radius)
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
        guard let borderWidth = extTag.cssBorderWidth,
              borderWidth > 0 else {
            borderLayer.isHidden = true
            return
        }

        borderLayer.isHidden = false
        borderLayer.path = UIBezierPath(roundedRect: bounds,
                                       cornerRadius: layer.cornerRadius).cgPath
        borderLayer.lineWidth = CGFloat(borderWidth)
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

// MARK: - SVG 渲染

/// 用 WKWebView 将 SVG base64 异步渲染为 UIImage
private class SVGImageLoader: NSObject, WKNavigationDelegate {

    // 持有进行中的 loader，防止截图完成前被释放
    private static var active: [SVGImageLoader] = []

    // 以 svgBase64 为 key 缓存渲染结果，避免重复渲染和首次显示闪烁
    private static let cache = NSCache<NSString, UIImage>()

    private let cacheKey: NSString
    private let webView: WKWebView
    private let completion: (UIImage?) -> Void

    static func load(svgBase64: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let key = svgBase64 as NSString
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        let loader = SVGImageLoader(svgBase64: svgBase64, size: size, completion: completion)
        active.append(loader)
    }

    private init(svgBase64: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        self.cacheKey = svgBase64 as NSString
        self.completion = completion
        // frame 用 point，takeSnapshot 会自动按屏幕 scale 输出 Retina 分辨率
        self.webView = WKWebView(frame: CGRect(origin: .zero, size: size))
        super.init()

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = self

        let w = size.width
        let h = size.height
        let html = """
        <html><head>
        <meta name="viewport" content="width=\(w), initial-scale=1">
        <style>*{margin:0;padding:0;}html,body{width:\(w)px;height:\(h)px;overflow:hidden;background:transparent;}
        img{width:\(w)px;height:\(h)px;display:block;}</style>
        </head><body>
        <img src="data:image/svg+xml;base64,\(svgBase64)">
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds
        webView.takeSnapshot(with: config) { [weak self] image, _ in
            DispatchQueue.main.async {
                if let self, let image {
                    SVGImageLoader.cache.setObject(image, forKey: self.cacheKey)
                }
                self?.completion(image)
                SVGImageLoader.active.removeAll { $0 === self }
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
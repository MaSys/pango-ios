//
//  Funcs.swift
//  Pango
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI
import UIKit

private let _notificationGenerator = UINotificationFeedbackGenerator()
private let _impactGenerator = UIImpactFeedbackGenerator(style: .light)

func hapticSuccess() {
    _notificationGenerator.notificationOccurred(.success)
}

func hapticLight() {
    _impactGenerator.impactOccurred()
}

func baseDomain(from urlString: String) -> String {
    guard let url = URL(string: urlString) else { return "" }
    
    return "\(url.scheme ?? "https")://\(url.host ?? "")"
}

func fullURL(from urlString: String, ssl: Bool = true) -> String {
    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
        if ssl {
            return "https://" + urlString
        } else {
            return "http://" + urlString
        }
    }
    return urlString
}

func countryFlag(_ code: String) -> String {
    let base: UInt32 = 127397
    return code.uppercased().unicodeScalars.compactMap {
        UnicodeScalar(base + $0.value).map(String.init)
    }.joined()
}

func countryName(_ code: String) -> String {
    Locale.current.localizedString(forRegionCode: code) ?? code
}

func humanNumber(_ value: Int) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM", Double(value) / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.1fK", Double(value) / 1_000)
    }
    return "\(value)"
}

func humanMegabyte(from num: Float) -> String {
    if num <= 1024 {
        return "\(String(format: "%.2f", num)) MB"
    } else if (num / 1024) <= 1024 {
        return "\(String(format: "%.2f", num / 1024)) GB"
    } else if (num / 1024 / 1024) <= 1024 {
        return "\(String(format: "%.2f", num / 1024 / 1024)) TB"
    }
    return ""
}

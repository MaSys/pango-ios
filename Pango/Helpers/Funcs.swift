//
//  Funcs.swift
//  Pango
//
//  Created by Yaser Almasri on 05/08/25.
//

import SwiftUI

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

func humanMegabyte(from num: Float) -> String {
    if num <= 1024 {
        return "\(String(format: "%.2f", num)) MB"
    } else if (num / 1024) <= 1024 {
        return "\(String(format: "%.2f", num / 1024)) GB"
    } else if (num / 1024 / 1024) <= 1024 {
        return "\(String(format: "%.2f", num / 1024)) TB"
    }
    return ""
}

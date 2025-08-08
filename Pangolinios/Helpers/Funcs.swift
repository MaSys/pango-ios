//
//  Funcs.swift
//  Pangolinios
//
//  Created by Yaser Almasri on 05/08/25.
//

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

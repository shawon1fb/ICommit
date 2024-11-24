//
//  Request+Ext.swift
//  ICommit
//
//  Created by shahanul on 11/24/24.
//

import Foundation

public extension URLRequest {
  var cURL: String {
    guard let url = url else { return "" }
    var components = ["curl"]

    // Method
    components.append("-X \(httpMethod ?? "GET")")

    // URL
    components.append("\"\(url.absoluteString)\"")

    // Headers
    if let allHTTPHeaderFields = allHTTPHeaderFields {
      for (key, value) in allHTTPHeaderFields {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
        components.append("-H \"\(key): \(escapedValue)\"")
      }
    }

    // Body
    if let httpBody = httpBody {
      if let bodyString = String(data: httpBody, encoding: .utf8) {
        let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\\''")
        components.append("-d '\(escapedBody)'")
      } else {
        // Binary data
        let binaryDataString = httpBody.map { String(format: "\\x%02X", $0) }.joined()
        components.append("--data-binary $'\(binaryDataString)'")

      }
    }

    return components.joined(separator: " ")
  }
}

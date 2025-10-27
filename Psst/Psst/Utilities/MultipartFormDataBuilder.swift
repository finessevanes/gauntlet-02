//
//  MultipartFormDataBuilder.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//

import Foundation

/// Utility for building multipart/form-data request bodies
struct MultipartFormDataBuilder {
    private let boundary: String
    private var body = Data()

    init() {
        self.boundary = "Boundary-\(UUID().uuidString)"
    }

    var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }

    mutating func addTextField(named name: String, value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func addDataField(named name: String, data: Data, mimeType: String, filename: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }

    mutating func finalize() -> Data {
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

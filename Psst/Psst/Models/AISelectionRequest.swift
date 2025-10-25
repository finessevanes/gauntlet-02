//
//  AISelectionRequest.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Selection System
//  Handles multiple contact matches and other selection scenarios
//

import Foundation

/// Represents a selection request from the AI when multiple options are available
struct AISelectionRequest: Identifiable, Codable, Equatable {
    let id = UUID()
    let selectionType: SelectionType
    let prompt: String
    let options: [SelectionOption]
    let context: SelectionContext?

    // Equatable conformance - compare by ID
    static func == (lhs: AISelectionRequest, rhs: AISelectionRequest) -> Bool {
        lhs.id == rhs.id
    }

    enum SelectionType: String, Codable {
        case contact
        case time
        case action
        case parameter
        case generic
    }

    /// Individual selectable option
    struct SelectionOption: Identifiable, Codable {
        let id: String
        let title: String
        let subtitle: String?
        let icon: String?
        let metadata: [String: AnyCodable]?

        enum CodingKeys: String, CodingKey {
            case id, title, subtitle, icon, metadata
        }
    }

    /// Context about the original request
    struct SelectionContext: Codable {
        let originalFunction: String
        let originalParameters: [String: AnyCodable]
    }

    enum CodingKeys: String, CodingKey {
        case selectionType, prompt, options, context
    }

    /// Parse from backend response
    static func fromResponse(_ response: [String: Any]) -> AISelectionRequest? {
        guard let typeString = response["selectionType"] as? String,
              let type = SelectionType(rawValue: typeString),
              let prompt = response["prompt"] as? String,
              let optionsData = response["options"] as? [[String: Any]] else {
            return nil
        }

        let options = optionsData.compactMap { optionData -> SelectionOption? in
            guard let id = optionData["id"] as? String,
                  let title = optionData["title"] as? String else {
                return nil
            }

            let subtitle = optionData["subtitle"] as? String
            let icon = optionData["icon"] as? String
            let metadata = (optionData["metadata"] as? [String: Any])?.mapValues { AnyCodable($0) }

            return SelectionOption(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                metadata: metadata
            )
        }

        var context: SelectionContext? = nil
        if let contextData = response["context"] as? [String: Any],
           let functionName = contextData["originalFunction"] as? String,
           let parameters = contextData["originalParameters"] as? [String: Any] {
            context = SelectionContext(
                originalFunction: functionName,
                originalParameters: parameters.mapValues { AnyCodable($0) }
            )
        }

        return AISelectionRequest(
            selectionType: type,
            prompt: prompt,
            options: options,
            context: context
        )
    }
}

/// Type-erased wrapper for encoding/decoding Any values in Codable contexts
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unable to encode value of type \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Convenience Extensions

extension AnyCodable: Equatable {
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check - can be enhanced if needed
        switch (lhs.value, rhs.value) {
        case (let l as String, let r as String):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as Bool, let r as Bool):
            return l == r
        default:
            return false
        }
    }
}

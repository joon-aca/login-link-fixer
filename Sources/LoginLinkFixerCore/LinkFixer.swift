import Foundation

public enum LinkFixerError: LocalizedError, Equatable {
    case noLink
    case invalidLink

    public var errorDescription: String? {
        switch self {
        case .noLink:
            return "No web link found. Paste the whole link, including https://"
        case .invalidLink:
            return "That still doesn’t look like a complete web link."
        }
    }
}

public enum LinkFixer {
    public static func clean(_ input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LinkFixerError.noLink }

        let decoded = trimmed
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#38;", with: "&")

        var candidate = markdownTarget(in: decoded) ?? decoded
        guard let schemeRange = candidate.range(
            of: #"https?://"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            throw LinkFixerError.noLink
        }

        candidate = String(candidate[schemeRange.lowerBound...])

        if markdownTarget(in: decoded) == nil,
           let stop = candidate.firstIndex(where: { "<>\"'`".contains($0) }) {
            candidate = String(candidate[..<stop])
        }

        candidate = candidate
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: CharacterSet(charactersIn: "])},.;:"))

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil else {
            throw LinkFixerError.invalidLink
        }

        return url
    }

    public static func canClean(_ input: String) -> Bool {
        (try? clean(input)) != nil
    }

    private static func markdownTarget(in input: String) -> String? {
        let pattern = #"\]\(\s*(https?://[\s\S]*?)\s*\)(?:\s|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              let range = Range(match.range(at: 1), in: input) else {
            return nil
        }
        return String(input[range])
    }
}

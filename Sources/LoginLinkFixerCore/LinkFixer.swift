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

        let target = markdownTarget(in: decoded)?.replacingOccurrences(of: #"\&"#, with: "&")
        var candidate = target ?? decoded
        guard let schemeRange = candidate.range(
            of: #"https?://"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            throw LinkFixerError.noLink
        }

        candidate = String(candidate[schemeRange.lowerBound...])

        if target != nil {
            // The closing parenthesis bounds a Markdown target, so all whitespace inside it is wrapping.
            candidate = candidate.components(separatedBy: .whitespacesAndNewlines).joined()
        } else {
            if let stop = candidate.firstIndex(where: { "<>\"'`".contains($0) }) {
                candidate = String(candidate[..<stop])
            }
            candidate = unwrap(candidate)
        }

        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "])},.;:"))

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

    /// Rejoins a link that a terminal wrapped across lines, starting at its scheme.
    /// A wrapped fragment is a single unbroken run of characters, so whitespace
    /// within a line, a blank line, or a line of words marks the end of the link
    /// and keeps prose that follows it from being glued on.
    private static func unwrap(_ text: String) -> String {
        var link = ""
        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let fragment = line.trimmingCharacters(in: .whitespaces)
            let isUnbroken = !fragment.contains(where: \.isWhitespace)
            if link.isEmpty {
                link = String(fragment.prefix { !$0.isWhitespace })
                guard isUnbroken else { break }
            } else {
                guard !fragment.isEmpty, isUnbroken else { break }
                link += fragment
            }
        }
        return link
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

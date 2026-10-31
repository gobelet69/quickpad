import Foundation

public enum LineEnding: String, CaseIterable, Sendable {
    case lf = "\n"
    case crlf = "\r\n"
    case cr = "\r"

    public var displayName: String {
        switch self {
        case .lf: return "LF"
        case .crlf: return "CRLF"
        case .cr: return "CR"
        }
    }

    public static func detect(in string: String) -> LineEnding {
        var crlfCount = 0
        var lfCount = 0
        var crCount = 0

        for char in string {
            if char == "\r\n" {
                crlfCount += 1
            } else if char == "\n" {
                lfCount += 1
            } else if char == "\r" {
                crCount += 1
            }
            if crlfCount + lfCount + crCount > 1000 { break }
        }

        if crlfCount >= lfCount && crlfCount >= crCount && crlfCount > 0 {
            return .crlf
        } else if crCount > lfCount && crCount > crlfCount {
            return .cr
        } else {
            return .lf
        }
    }

    public func normalize(text: String) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
                             .replacingOccurrences(of: "\r", with: "\n")
        if self == .lf {
            return normalized
        }
        return normalized.replacingOccurrences(of: "\n", with: self.rawValue)
    }
}

import Foundation

extension JSONDecoder {

    /// Decoder for **all** PostgREST responses (`/rest/v1/...`) so every mapped table decodes the same way.
    ///
    /// Postgres / PostgREST often returns timestamps **without** a zone suffix, e.g. `2026-03-25T14:01:45`
    /// or `2026-03-25 14:01:45`. Those are parsed as **UTC** (matches typical API behavior).
    static func supabasePostgresREST() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters: [Any] = [
                ISO8601DateFormatter(),
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return f
                }(),
                postgresUTCFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"),
                postgresUTCFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
                postgresUTCFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS"),
                postgresUTCFormatter("yyyy-MM-dd'T'HH:mm:ss"),
                postgresUTCFormatter("yyyy-MM-dd HH:mm:ss.SSSSSS"),
                postgresUTCFormatter("yyyy-MM-dd HH:mm:ss.SSS"),
                postgresUTCFormatter("yyyy-MM-dd HH:mm:ss"),
                postgresUTCFormatter("yyyy-MM-dd")
            ]

            for formatter in formatters {
                if let iso = formatter as? ISO8601DateFormatter {
                    if let date = iso.date(from: dateString) { return date }
                } else if let df = formatter as? DateFormatter {
                    if let date = df.date(from: dateString) { return date }
                }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return d
    }

    private static func postgresUTCFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = format
        return f
    }
}

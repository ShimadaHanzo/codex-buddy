import Foundation

// Resolve once at launch using macOS preferred languages, including app-specific overrides.
enum AppLanguage {
    static func isChinese(_ languages: [String]) -> Bool {
        for language in languages {
            let code = language.lowercased().replacingOccurrences(of:"_",with:"-")
            if code == "zh" || code.hasPrefix("zh-") { return true }
            if code == "en" || code.hasPrefix("en-") { return false }
        }
        return false
    }
    static let chinese = isChinese(Locale.preferredLanguages)
}
func L(_ chinese: String, _ english: String) -> String {
    AppLanguage.chinese ? chinese : english
}

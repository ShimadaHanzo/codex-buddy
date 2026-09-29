import Foundation

// Bound outage traffic; manual refresh and wake can still retry immediately.
enum RefreshPolicy {
    static func interval(failures: Int) -> TimeInterval {
        60 * pow(2, Double(min(max(failures, 0), 4)))
    }
}

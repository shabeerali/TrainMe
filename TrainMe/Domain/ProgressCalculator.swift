import Foundation

enum ProgressCalculator {
    /// Whole-number percentage (0...100), rounded to nearest.
    static func percentage(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let clamped = min(max(completed, 0), total)
        return Int((Double(clamped) / Double(total) * 100).rounded())
    }
}

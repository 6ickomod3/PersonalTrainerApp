import Foundation

/// Validates picker inputs without changing the configuration stored by older versions.
struct WeightConfiguration {
    let min: Double
    let max: Double
    let step: Double

    private static let maximumIntervals = 1_000
    private static let fallbackValues = (0...40).map { Double($0) * 5 }

    var validationMessage: String? {
        guard min.isFinite, max.isFinite, step.isFinite else {
            return "Enter finite numbers for the weight range and increment."
        }
        guard min >= 0 else { return "Minimum weight must be zero or greater." }
        guard max >= min else { return "Maximum weight must be at least the minimum." }
        guard step > 0 else { return "Weight increment must be greater than zero." }
        let intervals = (max - min) / step
        guard intervals.isFinite, intervals <= Double(Self.maximumIntervals) else {
            return "Use a larger increment or a smaller range (up to 1,001 weights)."
        }
        guard min == max || min + step > min else {
            return "Use a larger weight increment."
        }
        return nil
    }

    /// Invalid legacy settings get a bounded fallback until the user corrects them.
    var values: [Double] {
        guard validationMessage == nil else { return Self.fallbackValues }
        let intervals = (max - min) / step
        // Decimal increments can place an exact endpoint just below an integer.
        let count = Swift.min(Int(floor(intervals + 1e-9)), Self.maximumIntervals)
        return (0...count).map { Swift.min(min + Double($0) * step, max) }
    }

    func nearest(to weight: Double) -> Double {
        let choices = values
        guard weight.isFinite else { return choices[0] }
        return choices.min { abs($0 - weight) < abs($1 - weight) } ?? choices[0]
    }
}

extension Exercise {
    var weightConfiguration: WeightConfiguration {
        WeightConfiguration(min: weightMin, max: weightMax, step: weightStep)
    }
}

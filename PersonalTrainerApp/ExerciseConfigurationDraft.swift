import Foundation

/// Text drafts keep incomplete or invalid input out of the persistent model.
struct ExerciseConfigurationDraft {
    var name = ""
    var minimum = "0"
    var maximum = "200"
    var increment = "5"
    var improvement = "3"

    init(exercise: Exercise? = nil) {
        guard let exercise else { return }
        name = exercise.name
        minimum = exercise.weightMin.formatted(.number.grouping(.never).precision(.significantDigits(1...17)))
        maximum = exercise.weightMax.formatted(.number.grouping(.never).precision(.significantDigits(1...17)))
        increment = exercise.weightStep.formatted(.number.grouping(.never).precision(.significantDigits(1...17)))
        improvement = exercise.volumeImprovementPercent.formatted(.number.grouping(.never).precision(.significantDigits(1...17)))
    }

    static func number(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = Locale.current.decimalSeparator ?? "."
        let normalized = trimmed.replacingOccurrences(of: separator, with: ".")
        // Foundation's number parser accepts numeric prefixes such as "1abc".
        // Require the entire draft to be a number before converting it.
        guard normalized.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"#, options: .regularExpression) != nil else { return nil }
        return Double(normalized)
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var configuration: WeightConfiguration? {
        guard let min = Self.number(minimum), let max = Self.number(maximum), let step = Self.number(increment) else { return nil }
        return WeightConfiguration(min: min, max: max, step: step)
    }
    var improvementValue: Double? { Self.number(improvement) }
    var validationMessage: String? {
        guard !trimmedName.isEmpty else { return "Enter an exercise name." }
        guard let configuration else { return "Enter a number for each weight setting." }
        if let message = configuration.validationMessage { return message }
        guard let improvementValue, improvementValue.isFinite, (0...100).contains(improvementValue) else {
            return "Volume increase must be between 0 and 100%."
        }
        return nil
    }
}

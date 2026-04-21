import Foundation

@propertyWrapper
struct Validated<T> {
    private var value: T
    private let validate: @Sendable (T) -> String?

    init(wrappedValue: T, validate: @escaping @Sendable (T) -> String?) {
        self.value = wrappedValue
        self.validate = validate
    }

    var wrappedValue: T {
        get { value }
        set { value = newValue }
    }

    var projectedValue: Validated<T> { self }

    var isValid: Bool { validate(value) == nil }
    var errorMessage: String? { validate(value) }
}

extension Validated: Sendable where T: Sendable {}

extension Validated where T == String {
    static func email(wrappedValue: String = "") -> Validated<String> {
        Validated(wrappedValue: wrappedValue) { v in
            v.contains("@") && v.count > 3 ? nil : "Enter a valid email"
        }
    }

    static func password(wrappedValue: String = "") -> Validated<String> {
        Validated(wrappedValue: wrappedValue) { v in
            v.count >= 6 ? nil : "Password must be at least 6 characters"
        }
    }

    static func displayName(wrappedValue: String = "") -> Validated<String> {
        Validated(wrappedValue: wrappedValue) { v in
            v.trimmingCharacters(in: .whitespaces).count >= 2 ? nil : "Name must be at least 2 characters"
        }
    }
}

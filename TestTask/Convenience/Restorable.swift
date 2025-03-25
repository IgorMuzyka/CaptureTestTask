
import Foundation

/// Something that can be restored from `UserDefaults`.
protocol Restorable: Decodable {
    static var persistanceKey: String { get }
}

extension Restorable {
    static func restore() throws(RestorationError) -> Self {
        guard let json = UserDefaults.standard.string(forKey: Self.persistanceKey) else {
            throw .userDefaultsValueWasNeverSet
        }
        guard let data = json.data(using: .utf8) else {
            throw .failedToProduceDataFromUserDefaultsValue
        }
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch {
            throw .jsonDecoderFailed(error)
        }
    }
}

enum RestorationError: Error {
    case userDefaultsValueWasNeverSet
    case failedToProduceDataFromUserDefaultsValue
    case jsonDecoderFailed(any Error)
}


import Foundation

/// Something that can be persisted into `UserDefaults`.
protocol Persistable: Encodable {
    static var persistanceKey: String { get }
}

extension Persistable {
    func persist() throws(PersistanceError) {
        let data: Data
        do {
            data = try JSONEncoder().encode(self)
        } catch {
            throw .jsonEncoderFailed(error)
        }
        guard let json = String(data: data, encoding: .utf8) else {
            throw .failedToProduceJSONFromData
        }
        UserDefaults.standard.set(json, forKey: Self.persistanceKey)
    }
}

enum PersistanceError: Error {
    case failedToProduceJSONFromData
    case jsonEncoderFailed(any Error)
}

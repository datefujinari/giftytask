import Foundation
import FirebaseStorage
import UIKit

// MARK: - Storage Service（完了報告画像のアップロード）
enum StorageService {
    private static let bucket = Storage.storage().reference()
    private static let completionImagesPath = "task_completion_images"
    
    /// 画像をアップロードし、ダウンロードURLを返す
    static func uploadCompletionImage(taskId: String, imageData: Data) async throws -> String {
        let filename = "\(taskId)_\(UUID().uuidString.prefix(8)).jpg"
        let ref = bucket.child("\(completionImagesPath)/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: StorageServiceError.failedToEncodeImage)
                }
            }
        }
        return url.absoluteString
    }
    
    /// UIImage を JPEG データに変換してアップロード
    static func uploadCompletionImage(taskId: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageServiceError.failedToEncodeImage
        }
        return try await uploadCompletionImage(taskId: taskId, imageData: data)
    }
}

enum StorageServiceError: LocalizedError {
    case failedToEncodeImage
    
    var errorDescription: String? {
        switch self {
        case .failedToEncodeImage: return "画像の変換に失敗しました"
        }
    }
}

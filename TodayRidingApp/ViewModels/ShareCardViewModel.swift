import Combine
import Foundation
import SwiftUI
import TodayRidingCore
import UIKit

@MainActor
final class ShareCardViewModel: ObservableObject {
    let summary: RideSummary
    @Published private(set) var renderedImage: UIImage?

    init(summary: RideSummary) {
        self.summary = summary
    }

    func renderCardImage() {
        let content = ShareCardContent(summary: summary)
            .frame(width: 390, height: 693)

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        renderedImage = renderer.uiImage
    }

    func saveRenderedImageToPhotos() -> String {
        guard let renderedImage else {
            renderCardImage()
            guard let renderedImage else {
                return "공유 카드 이미지를 아직 만들지 못했습니다."
            }
            UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
            return "사진 앱에 저장 요청을 보냈습니다."
        }

        UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
        return "사진 앱에 저장 요청을 보냈습니다."
    }
}

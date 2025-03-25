
import SwiftUI
import AppKit
import AVFoundation

struct CaptureVideoPreviewLayerRepresentable: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        view.layer = previewLayer
        return view
    }

    func updateNSView(_ view: some NSView, context: Context) {
        previewLayer.frame = view.frame
        previewLayer.contentsGravity = .resizeAspectFill
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isEnabled = true
        view.layer = previewLayer
    }
}

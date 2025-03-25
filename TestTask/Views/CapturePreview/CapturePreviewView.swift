
import SwiftUI
import Factory

struct CapturePreviewView: View {
    @StateObject private var viewModel = CapturePreviewViewModel()

    var body: some View {
        ZStack {
            Rectangle().fill(.clear)
            if viewModel.isFilterEnabled {
                pixelBufferPreview
            } else {
                captureVideoPreivewLayer
            }
        }
        .onAppear { [weak viewModel] in
            viewModel?.previewDidAppear()
        }
        .onDisappear { [weak viewModel] in
            viewModel?.previewDidDisappear()
        }
    }

    private let minWidth: CGFloat = 330

    @ViewBuilder private var captureVideoPreivewLayer: some View {
        if let previewLayer = viewModel.previewLayer {
            CaptureVideoPreviewLayerRepresentable(previewLayer: previewLayer)
                .frame(minWidth: minWidth, minHeight: minWidth / viewModel.aspectRatio)
                .aspectRatio(viewModel.aspectRatio, contentMode: .fit)
                .transition(.opacity)
                .animation(.snappy, value: viewModel.previewLayer)
        } else {
            bufferingBanner
                .animation(.snappy, value: viewModel.previewLayer)
        }
    }

    @ViewBuilder private var pixelBufferPreview: some View {
        if let image = viewModel.image {
            Image(decorative: image, scale: 1.0)
                .resizable()
                .interpolation(.none)
                .frame(minWidth: minWidth, minHeight: minWidth / viewModel.aspectRatio)
                .aspectRatio(viewModel.aspectRatio, contentMode: .fit)
                .transition(.opacity)
        } else {
            bufferingBanner
                .animation(.snappy, value: viewModel.image)
        }
    }

    @ViewBuilder private var bufferingBanner: some View {
        ProgressView("Buffering")
            .progressViewStyle(.circular)
            .transition(.opacity)
    }
}

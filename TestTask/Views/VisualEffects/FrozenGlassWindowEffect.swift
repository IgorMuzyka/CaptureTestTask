
import SwiftUI
import AppKit

struct FrozenGlassWindowEffect: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let state: NSVisualEffectView.State
    private let configureWindow: ((NSWindow) -> Void)?

    func makeNSView(context: Context) -> NSVisualEffectView {
        let effect = NSVisualEffectView()
        DispatchQueue.main.async { [weak effect] in
            guard let window = effect?.window else { return }
            configure(window)
        }
        return effect
    }

    func updateNSView(_ effect: NSVisualEffectView, context: Context) {
        configure(effect)
    }

    private func configure(_ effect: NSVisualEffectView) {
        effect.isHidden = false
        effect.isEmphasized = true
        effect.material = material
        effect.blendingMode = blendingMode
        effect.state = state
    }

    private func configure(_ window: NSWindow) {
        configureWindow?(window)
    }
}

extension FrozenGlassWindowEffect {
    static func blurringBackground(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState
    ) -> some View {
        Self(material: material, blendingMode: blendingMode, state: state, configureWindow: .none)
    }

    static func reconfiguringWindow(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState,
        configureWindow: @escaping (NSWindow) -> Void = { _ in }
    ) -> some View {
        Self(material: material, blendingMode: blendingMode, state: state, configureWindow: configureWindow)
    }

}

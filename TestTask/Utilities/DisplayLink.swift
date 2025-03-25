
import Combine
import CoreVideo

public final class DisplayLink {
    public var frameSubject = PassthroughSubject<Void, Never>()
    private var link: CVDisplayLink?
    private var isActive: Bool = false

    deinit {
        guard let link = link else { return }
        CVDisplayLinkStop(link)
    }

    public func activate() {
        guard !isActive else { return }
        isActive = true
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let link = link else { return }
        CVDisplayLinkSetOutputHandler(link) { [weak self] link, now, outputTime, flagsIn, flagsOut in
            self?.consume(now)
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(link)
    }

    private func consume(_ now: UnsafePointer<CVTimeStamp>) {
        frameSubject.send(())
    }
}

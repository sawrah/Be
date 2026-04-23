import Metal
import ARKit

enum ARBackend { case realityKit, sceneKit }

enum Capability {
    static let backend: ARBackend = {
        guard let device = MTLCreateSystemDefaultDevice() else { return .sceneKit }
        return device.supportsFamily(.metal3) ? .realityKit : .sceneKit
    }()
}

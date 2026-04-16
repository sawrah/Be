import SwiftUI
import SceneKit

struct SceneFlowerView: View {
    @State private var appeared = false

    var body: some View {
        FlowerSCNViewContainer()
            .frame(width: 90, height: 120)
            .background(Color.clear)
            .allowsHitTesting(false)
            .scaleEffect(appeared ? 1 : 0, anchor: .bottom)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
    }
}

struct FlowerSCNViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false

        let scene = SCNScene()

        if let url = Bundle.main.url(forResource: "3Dflower", withExtension: "usdz"),
           let node = SCNReferenceNode(url: url) {
            node.load()

            // Scale to fit the view
            node.scale = SCNVector3(0.3, 0.3, 0.3)

            node.eulerAngles.y = .pi / 2
            node.eulerAngles.x = -.pi / 12 // slight backward tilt so it reads upright

            // Pivot at the bottom-center of the bounding box → flower grows upward from origin
            let (minB, maxB) = node.boundingBox
            node.pivot = SCNMatrix4MakeTranslation(
                (maxB.x + minB.x) / 2,
                minB.y,
                (maxB.z + minB.z) / 2
            )
            node.position = SCNVector3(0.5, -1, 0)
            scene.rootNode.addChildNode(node)
        }

        // Camera: slightly elevated, angled down — matches isometric viewer perspective
        // lookAt (0, 1.2, 0) focuses on mid-upper body of flower, keeping it in lower 2/3 of frame
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 2.0
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 9)
        cameraNode.look(at: SCNVector3(x: 0, y: 1.5, z: 0))
        scene.rootNode.addChildNode(cameraNode)

        // Lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.position = SCNVector3(x: 4, y: 10, z: 6)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)

        scnView.scene = scene
        scnView.antialiasingMode = .multisampling4X

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

#Preview {
    ZStack {
        Color.gray
        SceneFlowerView()
    }
}

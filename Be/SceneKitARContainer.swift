import SwiftUI
import SceneKit
import ARKit

struct SceneKitARContainer: UIViewRepresentable {

    var onPlaced: () -> Void
    var onSurfaceNotFound: () -> Void
    @Binding var shouldDropPetals: Bool
    @Binding var shouldGrowPetals: Bool
    @Binding var shouldDropAllPetals: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)

        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.antialiasingMode = .none

        context.coordinator.arView = arView
        context.coordinator.onPlaced = onPlaced
        context.coordinator.onSurfaceNotFound = onSurfaceNotFound

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none
        config.isLightEstimationEnabled = true
        // Do NOT enable sceneReconstruction — mesh compute pipeline crashes on A12Z

        arView.session.run(config)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        arView.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(pan)

        let rotation = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        rotation.delegate = context.coordinator
        arView.addGestureRecognizer(rotation)

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if shouldDropPetals {
            context.coordinator.dropPetals()
        }

        if shouldDropAllPetals && !context.coordinator.isDroppingAllPetals {
            context.coordinator.dropAllRemainingPetals()
        }
        context.coordinator.isDroppingAllPetals = shouldDropAllPetals

        if shouldGrowPetals && !context.coordinator.isGrowingPetals {
            context.coordinator.growPetalsBack()
        }
        context.coordinator.isGrowingPetals = shouldGrowPetals
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate, UIGestureRecognizerDelegate {

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return (gestureRecognizer is UIPinchGestureRecognizer && other is UIRotationGestureRecognizer)
                || (gestureRecognizer is UIRotationGestureRecognizer && other is UIPinchGestureRecognizer)
        }
        weak var arView: ARSCNView?

        var flowerNode: SCNNode?
        var onPlaced: (() -> Void)?
        var onSurfaceNotFound: (() -> Void)?

        var initialScale: SCNVector3 = SCNVector3(0.07, 0.07, 0.07)
        var panOffset: SCNVector3?

        let minScale: Float = 0.001
        let maxScale: Float = 0.3

        var nextPetalIndex: Int = 1
        let totalPetals: Int = 7

        var isDroppingAllPetals: Bool = false
        var isGrowingPetals: Bool = false

        var lastDropTime: TimeInterval = 0

        // Plane dot visuals — keyed by plane anchor UUID
        var planeVisualNodes: [UUID: SCNNode] = [:]

        struct PetalRegrowInfo {
            let pristineClone: SCNNode
            let originalPosition: SCNVector3
            let originalRotation: SCNVector4
            let originalScale: SCNVector3
            let originalParent: SCNNode
            let petalName: String
        }
        var pendingRegrowths: [PetalRegrowInfo] = []

        // MARK: - ARSCNViewDelegate — plane detection

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let plane = anchor as? ARPlaneAnchor,
                  plane.alignment == .horizontal,
                  flowerNode == nil else { return }
            DispatchQueue.main.async { self.addPlaneVisual(for: plane, node: node) }
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let plane = anchor as? ARPlaneAnchor,
                  flowerNode == nil else { return }
            DispatchQueue.main.async { self.updatePlaneVisual(for: plane, node: node) }
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            DispatchQueue.main.async {
                if let visual = self.planeVisualNodes.removeValue(forKey: anchor.identifier) {
                    visual.removeFromParentNode()
                }
            }
        }

        // MARK: - Plane visual — grid of white dots

        func addPlaneVisual(for plane: ARPlaneAnchor, node: SCNNode) {
            // Remove stale visual so we redraw with updated extent
            if let old = planeVisualNodes[plane.identifier] {
                old.removeFromParentNode()
            }

            let dotNode = buildDotGrid(for: plane)
            node.addChildNode(dotNode)
            planeVisualNodes[plane.identifier] = dotNode
        }

        func updatePlaneVisual(for plane: ARPlaneAnchor, node: SCNNode) {
            if let old = planeVisualNodes[plane.identifier] {
                old.removeFromParentNode()
            }
            let dotNode = buildDotGrid(for: plane)
            node.addChildNode(dotNode)
            planeVisualNodes[plane.identifier] = dotNode
        }

        private func buildDotGrid(for plane: ARPlaneAnchor) -> SCNNode {
            let container = SCNNode()

            let w = max(plane.planeExtent.width, 0.15)
            let d = max(plane.planeExtent.height, 0.15)
            let cx = plane.center.x
            let cz = plane.center.z

            let spacing: Float = 0.08
            let cols = max(2, Int((w / spacing).rounded()) + 1)
            let rows = max(2, Int((d / spacing).rounded()) + 1)
            let total = cols * rows
            let skip = total > 49 ? Int((Float(total) / 49.0).rounded(.up)) : 1

            let dotGeo = SCNSphere(radius: 0.005)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
            mat.lightingModel = .constant
            dotGeo.materials = [mat]

            var count = 0
            for row in 0..<rows {
                for col in 0..<cols {
                    guard (row * cols + col) % skip == 0, count < 49 else { continue }
                    count += 1

                    let x = cx - w / 2 + (cols > 1 ? Float(col) * w / Float(cols - 1) : w / 2)
                    let z = cz - d / 2 + (rows > 1 ? Float(row) * d / Float(rows - 1) : d / 2)

                    let dot = SCNNode(geometry: dotGeo.copy() as? SCNGeometry)
                    dot.position = SCNVector3(x, 0.003, z)
                    container.addChildNode(dot)
                }
            }
            return container
        }

        func removeAllPlaneVisuals() {
            for (_, node) in planeVisualNodes {
                node.removeFromParentNode()
            }
            planeVisualNodes.removeAll()
        }

        // MARK: - Tap — Place flower

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARSCNView else { return }

            if flowerNode != nil {
                return
            }

            let tapLocation = recognizer.location(in: arView)

            // Tiered raycast — same precedence as RealityKit version
            let query1 = arView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
            let query2 = arView.raycastQuery(from: tapLocation, allowing: .existingPlaneInfinite, alignment: .horizontal)
            let query3 = arView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)

            var results: [ARRaycastResult] = []
            if let q = query1 { results += arView.session.raycast(q) }
            if let q = query2 { results += arView.session.raycast(q) }
            if let q = query3 { results += arView.session.raycast(q) }

            guard let firstResult = results.first else {
                onSurfaceNotFound?()
                return
            }

            guard let url = Bundle.main.url(forResource: "3Dflower", withExtension: "usdz"),
                  let scene = try? SCNScene(url: url, options: nil) else {
                print("Failed to load 3Dflower.usdz")
                return
            }

            let flower = SCNNode()
            for child in scene.rootNode.childNodes {
                flower.addChildNode(child)
            }

            flower.scale = SCNVector3(0.07, 0.07, 0.07)

            let faceAngle: Float
            if let frame = arView.session.currentFrame {
                let cam = frame.camera.transform.columns.3
                let pos = firstResult.worldTransform.columns.3
                faceAngle = atan2(cam.x - pos.x, cam.z - pos.z) + (30.0 * .pi / 180.0)
            } else {
                faceAngle = Float(40.0) * (.pi / 180)
            }
            flower.eulerAngles = SCNVector3(0, faceAngle, 0)

            let transform = firstResult.worldTransform
            flower.simdPosition = simd_float3(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )

            arView.scene.rootNode.addChildNode(flower)
            flowerNode = flower

            removeAllPlaneVisuals()
            onPlaced?()
        }

        // MARK: - Pan — Move flower

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARSCNView,
                  let flower = flowerNode else { return }

            if recognizer.numberOfTouches > 1 { return }

            let location = recognizer.location(in: arView)

            func raycast(_ loc: CGPoint) -> simd_float3? {
                let q1 = arView.raycastQuery(from: loc, allowing: .existingPlaneGeometry, alignment: .horizontal)
                let q2 = arView.raycastQuery(from: loc, allowing: .existingPlaneInfinite, alignment: .horizontal)
                let q3 = arView.raycastQuery(from: loc, allowing: .estimatedPlane, alignment: .horizontal)
                var r: [ARRaycastResult] = []
                if let q = q1 { r += arView.session.raycast(q) }
                if let q = q2 { r += arView.session.raycast(q) }
                if let q = q3 { r += arView.session.raycast(q) }
                guard let first = r.first else { return nil }
                let c = first.worldTransform.columns.3
                return simd_float3(c.x, c.y, c.z)
            }

            switch recognizer.state {
            case .began:
                if let hit = raycast(location) {
                    let fp = flower.simdPosition
                    panOffset = SCNVector3(fp.x - hit.x, fp.y - hit.y, fp.z - hit.z)
                }
            case .changed:
                if let hit = raycast(location) {
                    let off = panOffset ?? SCNVector3(0, 0, 0)
                    flower.simdPosition = simd_float3(
                        hit.x + off.x,
                        hit.y + off.y,
                        hit.z + off.z
                    )
                }
            case .ended, .cancelled:
                panOffset = nil
            default:
                break
            }
        }

        // MARK: - Rotation

        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let flower = flowerNode else { return }

            if recognizer.state == .changed {
                let delta = Float(recognizer.rotation)
                flower.eulerAngles.y += delta
                recognizer.rotation = 0
            }
        }

        // MARK: - Pinch — Scale

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let flower = flowerNode else { return }

            switch recognizer.state {
            case .began:
                initialScale = flower.scale
            case .changed:
                let s = Float(recognizer.scale)
                let nx = max(minScale, min(maxScale, initialScale.x * s))
                let ny = max(minScale, min(maxScale, initialScale.y * s))
                let nz = max(minScale, min(maxScale, initialScale.z * s))
                flower.scale = SCNVector3(nx, ny, nz)
            case .cancelled:
                flower.scale = initialScale
            default:
                break
            }
        }

        // MARK: - Drop single petal

        func dropPetals() {
            let now = Date().timeIntervalSince1970
            guard now - lastDropTime >= 0.25 else { return }
            guard let flower = flowerNode else { return }
            if pendingRegrowths.count >= totalPetals { return }

            var foundPetal: SCNNode? = nil
            var petalName = ""

            for _ in 0..<totalPetals {
                petalName = String(format: "petal_%02d", nextPetalIndex)
                if let node = flower.childNode(withName: petalName, recursively: true) {
                    foundPetal = node
                    break
                }
                nextPetalIndex += 1
                if nextPetalIndex > totalPetals { nextPetalIndex = 1 }
            }

            guard let petalNode = foundPetal,
                  let parent = petalNode.parent else { return }

            lastDropTime = now

            let origPos = petalNode.position
            let origRot = petalNode.rotation
            let origScale = petalNode.scale

            let clone = petalNode.clone()
            clone.name = petalName

            // Reparent to scene root so it falls independently
            let worldTransform = petalNode.simdWorldTransform
            arView?.scene.rootNode.addChildNode(petalNode)
            petalNode.simdTransform = worldTransform

            // Animate: fall to plane surface and rotate flat
            // petalNode.position is now world-space (root has identity transform)
            let planeY = flowerNode?.position.y ?? petalNode.position.y
            let targetY = Float(planeY) + 0.005
            let randomYaw = Float.random(in: 0...(2 * .pi))
            let dropAction = SCNAction.group([
                SCNAction.move(
                    to: SCNVector3(petalNode.position.x, targetY, petalNode.position.z),
                    duration: 2.0
                ),
                SCNAction.rotateTo(
                    x: CGFloat(Float.pi / 2),
                    y: CGFloat(randomYaw),
                    z: 0,
                    duration: 2.0,
                    usesShortestUnitArc: true
                )
            ])
            dropAction.timingMode = .easeOut
            petalNode.runAction(dropAction)
            petalNode.name = "\(petalName)_fallen_\(UUID().uuidString)"

            pendingRegrowths.append(PetalRegrowInfo(
                pristineClone: clone,
                originalPosition: origPos,
                originalRotation: origRot,
                originalScale: origScale,
                originalParent: parent,
                petalName: petalName
            ))

            nextPetalIndex += 1
            if nextPetalIndex > totalPetals { nextPetalIndex = 1 }
        }

        // MARK: - Force-drop all remaining petals

        func dropAllRemainingPetals() {
            guard let flower = flowerNode else { return }

            for i in 1...totalPetals {
                let name = String(format: "petal_%02d", i)
                guard let petalNode = flower.childNode(withName: name, recursively: true),
                      let parent = petalNode.parent else { continue }

                let origPos = petalNode.position
                let origRot = petalNode.rotation
                let origScale = petalNode.scale

                let clone = petalNode.clone()
                clone.name = name

                let worldTransform = petalNode.simdWorldTransform
                arView?.scene.rootNode.addChildNode(petalNode)
                petalNode.simdTransform = worldTransform

                let planeY = flowerNode?.position.y ?? petalNode.position.y
                let targetY = Float(planeY) + 0.005
                let randomYaw = Float.random(in: 0...(2 * .pi))
                let dropAction = SCNAction.group([
                    SCNAction.move(
                        to: SCNVector3(petalNode.position.x, targetY, petalNode.position.z),
                        duration: 2.0
                    ),
                    SCNAction.rotateTo(
                        x: CGFloat(Float.pi / 2),
                        y: CGFloat(randomYaw),
                        z: 0,
                        duration: 2.0,
                        usesShortestUnitArc: true
                    )
                ])
                dropAction.timingMode = .easeOut
                petalNode.runAction(dropAction)
                petalNode.name = "\(name)_fallen_\(UUID().uuidString)"

                pendingRegrowths.append(PetalRegrowInfo(
                    pristineClone: clone,
                    originalPosition: origPos,
                    originalRotation: origRot,
                    originalScale: origScale,
                    originalParent: parent,
                    petalName: name
                ))
            }
            nextPetalIndex = 1
        }

        // MARK: - Regrow all petals

        func growPetalsBack() {
            guard !pendingRegrowths.isEmpty else { return }

            for info in pendingRegrowths {
                let newPetal = info.pristineClone
                info.originalParent.addChildNode(newPetal)
                newPetal.position = info.originalPosition
                newPetal.rotation = info.originalRotation
                newPetal.scale = SCNVector3(0.001, 0.001, 0.001)

                let regrow = SCNAction.group([
                    SCNAction.scale(to: CGFloat(info.originalScale.x), duration: 4.0),
                    SCNAction.rotate(
                        toAxisAngle: info.originalRotation,
                        duration: 4.0
                    )
                ])
                regrow.timingMode = .easeIn
                newPetal.runAction(regrow)
            }
            pendingRegrowths.removeAll()
        }
    }
}

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {

    var onPlaced: () -> Void
    var onSurfaceNotFound: () -> Void
    @Binding var shouldDropPetals: Bool
    @Binding var shouldGrowPetals: Bool
    @Binding var shouldDropAllPetals: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        context.coordinator.onPlaced = onPlaced
        context.coordinator.onSurfaceNotFound = onSurfaceNotFound

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
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

    class Coordinator {
        var selectedEntity: Entity?
        var flowerAnchor: AnchorEntity?
        var onPlaced: (() -> Void)?
        var onSurfaceNotFound: (() -> Void)?

        var initialScale: SIMD3<Float> = [0.1, 0.1, 0.1]
        var initialRotation: Float = 0.0
        var panOffset: SIMD3<Float>?

        let minScale: Float = 0.001
        let maxScale: Float = 0.3

        var nextPetalIndex: Int = 1
        let totalPetals: Int = 7

        var isDroppingAllPetals: Bool = false
        var isGrowingPetals: Bool = false
        
        var lastDropTime: TimeInterval = 0

        // Stores info needed to regrow each dropped petal
        struct PetalRegrowInfo {
            let pristineClone: ModelEntity
            let originalTransform: Transform
            let originalParent: Entity
            let petalName: String
        }
        var pendingRegrowths: [PetalRegrowInfo] = []

        // MARK: Tap – Place flower

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }

            if flowerAnchor != nil {
                print("Flower already placed. Drag to move it.")
                return
            }

            let tapLocation = recognizer.location(in: arView)
            let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)

            guard let firstResult = result.first else {
                onSurfaceNotFound?()
                return
            }

            guard let modelEntity = try? Entity.load(named: "3Dflower") else {
                print("Failed to load 3D model.")
                return
            }

            modelEntity.scale = [0.1, 0.1, 0.1]

            let angle = Float(40.0) * (.pi / 180)
            modelEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])

            func addCollision(to entity: Entity) {
                if let model = entity as? ModelEntity {
                    model.generateCollisionShapes(recursive: true)
                }
                for child in entity.children {
                    addCollision(to: child)
                }
            }
            addCollision(to: modelEntity)

            let anchorEntity = AnchorEntity(world: firstResult.worldTransform)
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)

            flowerAnchor = anchorEntity
            selectedEntity = modelEntity
            onPlaced?()
        }

        // MARK: Pan – Move flower

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARView,
                  let flowerAnchor = flowerAnchor else { return }

            if recognizer.numberOfTouches > 1 { return }

            let location = recognizer.location(in: arView)

            switch recognizer.state {
            case .began:
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let firstResult = results.first {
                    let hitPosition = SIMD3<Float>(
                        firstResult.worldTransform.columns.3.x,
                        firstResult.worldTransform.columns.3.y,
                        firstResult.worldTransform.columns.3.z
                    )
                    panOffset = flowerAnchor.position - hitPosition
                }
            case .changed:
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let firstResult = results.first {
                    var newPosition = SIMD3<Float>(
                        firstResult.worldTransform.columns.3.x,
                        firstResult.worldTransform.columns.3.y,
                        firstResult.worldTransform.columns.3.z
                    )
                    if let offset = panOffset {
                        newPosition += offset
                    }
                    flowerAnchor.position = newPosition
                }
            case .ended, .cancelled:
                panOffset = nil
            default:
                break
            }
        }

        // MARK: Rotate

        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let entity = selectedEntity else { return }

            switch recognizer.state {
            case .changed:
                let rotation = Float(recognizer.rotation)
                let rotationUpdate = simd_quatf(angle: rotation, axis: [0, 1, 0])
                entity.transform.rotation = entity.transform.rotation * rotationUpdate
                recognizer.rotation = 0
            default:
                break
            }
        }

        // MARK: Pinch – Scale

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let entity = selectedEntity else { return }

            switch recognizer.state {
            case .began:
                initialScale = entity.scale
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                let clampscale = SIMD3<Float>(
                    x: max(minScale, min(maxScale, newScale.x)),
                    y: max(minScale, min(maxScale, newScale.y)),
                    z: max(minScale, min(maxScale, newScale.z))
                )
                entity.scale = clampscale
            case .cancelled:
                entity.scale = initialScale
            default:
                break
            }
        }

        // MARK: Drop single petal (user blow)

        func dropPetals() {
            let now = Date().timeIntervalSince1970
            guard now - lastDropTime >= 0.25 else { return }
            
            guard let flowerAnchor = flowerAnchor, let selectedEntity = selectedEntity else { return }
            
            if pendingRegrowths.count >= totalPetals { return }

            var foundPetal: ModelEntity? = nil
            var petalName = ""
            
            for _ in 0..<totalPetals {
                petalName = String(format: "petal_%02d", nextPetalIndex)
                if let entity = selectedEntity.findEntity(named: petalName) as? ModelEntity {
                    foundPetal = entity
                    break
                }
                nextPetalIndex += 1
                if nextPetalIndex > totalPetals { nextPetalIndex = 1 }
            }
            
            guard let petalEntity = foundPetal else { return }
            
            lastDropTime = now

            let originalTransform = petalEntity.transform
            let originalParent = petalEntity.parent

            // PRE-CLONE BEFORE DETACHING: Preserves immaculate original matrix
            let cloneToRegrow = petalEntity.clone(recursive: true)
            cloneToRegrow.name = petalName

            let worldMatrix = petalEntity.transformMatrix(relativeTo: nil)
            flowerAnchor.addChild(petalEntity)
            petalEntity.setTransformMatrix(worldMatrix, relativeTo: nil)

            var dropTransform = petalEntity.transform
            dropTransform.translation.y = 0.005

            let randomYaw = Float.random(in: 0...(2 * .pi))
            let flatRot = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            let yawRot = simd_quatf(angle: randomYaw, axis: [0, 1, 0])
            dropTransform.rotation = yawRot * flatRot

            petalEntity.move(to: dropTransform, relativeTo: petalEntity.parent, duration: 2.0, timingFunction: .easeOut)
            petalEntity.name = "\(petalName)_fallen_\(UUID().uuidString)"

            // Store regrow info – petals are regrown later when inhale starts
            if let parent = originalParent {
                pendingRegrowths.append(PetalRegrowInfo(
                    pristineClone: cloneToRegrow,
                    originalTransform: originalTransform,
                    originalParent: parent,
                    petalName: petalName
                ))
            }

            nextPetalIndex += 1
            if nextPetalIndex > totalPetals {
                nextPetalIndex = 1
            }
        }

        // MARK: Force-drop all remaining petals (end of exhale)

        func dropAllRemainingPetals() {
            guard let selectedEntity = selectedEntity, let flowerAnchor = flowerAnchor else { return }

            for i in 1...totalPetals {
                let name = String(format: "petal_%02d", i)
                guard let petalEntity = selectedEntity.findEntity(named: name) as? ModelEntity else { continue }

                let originalTransform = petalEntity.transform
                let originalParent = petalEntity.parent

                // PRE-CLONE BEFORE DETACHING: Preserves immaculate original matrix
                let cloneToRegrow = petalEntity.clone(recursive: true)
                cloneToRegrow.name = name

                let worldMatrix = petalEntity.transformMatrix(relativeTo: nil)
                flowerAnchor.addChild(petalEntity)
                petalEntity.setTransformMatrix(worldMatrix, relativeTo: nil)

                var dropTransform = petalEntity.transform
                dropTransform.translation.y = 0.005

                let randomYaw = Float.random(in: 0...(2 * .pi))
                let flatRot = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                let yawRot = simd_quatf(angle: randomYaw, axis: [0, 1, 0])
                dropTransform.rotation = yawRot * flatRot

                // Smooth 2.0s drop so it majestically shedding old petals to surface
                petalEntity.move(to: dropTransform, relativeTo: petalEntity.parent, duration: 2.0, timingFunction: .easeOut)
                petalEntity.name = "\(name)_fallen_\(UUID().uuidString)"

                if let parent = originalParent {
                    pendingRegrowths.append(PetalRegrowInfo(
                        pristineClone: cloneToRegrow,
                        originalTransform: originalTransform,
                        originalParent: parent,
                        petalName: name
                    ))
                }
            }
            nextPetalIndex = 1
        }

        // MARK: Regrow all petals (inhale phase, 4s animation)

        func growPetalsBack() {
            guard !pendingRegrowths.isEmpty else { return }

            for info in pendingRegrowths {
                let newPetal = info.pristineClone
                info.originalParent.addChild(newPetal)
                newPetal.transform = info.originalTransform
                newPetal.scale = [0.001, 0.001, 0.001]
                newPetal.move(to: info.originalTransform, relativeTo: newPetal.parent, duration: 4.0, timingFunction: .easeIn)
            }
            pendingRegrowths.removeAll()
        }

        // MARK: Debug helper

        func listAllEntities(entity: Entity, indent: Int) {
            let indentString = String(repeating: "  ", count: indent)
            print("\(indentString)- \(entity.name) (type: \(type(of: entity)))")
            for child in entity.children {
                listAllEntities(entity: child, indent: indent + 1)
            }
        }
    }
}

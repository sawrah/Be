import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable{
    
    var onPlaced: () -> Void
    @Binding var shouldDropPetals: Bool
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        // Pass the closure to the coordinator
        context.coordinator.onPlaced = onPlaced
        
        let config = ARWorldTrackingConfiguration()
        
        config.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)

        
        // Tap gesture for placement
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Pan gesture for moving (dragging)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Rotation gesture for rotating
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if shouldDropPetals {
            context.coordinator.dropPetals()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator{
        var selectedEntity: Entity?
        var flowerAnchor: AnchorEntity? // Track the single instance
        var onPlaced: (() -> Void)?
        
        var initialScale: SIMD3<Float> = [0.1, 0.1, 0.1]
        var initialRotation: Float = 0.0
        
        let minScale: Float = 0.001
        let maxScale: Float = 0.3
        
        // Track which petals have already been dropped
        var nextPetalIndex: Int = 1
        let totalPetals: Int = 8
        
        // Tap gesture: Place object if none exists
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            
            // If we already have a flower, do not place another one.
            if flowerAnchor != nil {
                print("Flower already placed. Drag to move it.")
                return
            }
            
            let tapLocation = recognizer.location(in: arView)
            
            // Raycast to find surface
            let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            guard let firstResult = result.first else {
                print("No surface was found - point camera at flat surface")
                return
            }
            
            // Load 3D model
            guard let modelEntity = try? Entity.load(named: "3Dflower") else{
                print("failed to load 3D model. check that flower is usdz in your project!")
                return
            }
            
            // Initial scale
            modelEntity.scale = [0.1, 0.1, 0.1]
            
            // Default rotation: 40 degrees around Y axis
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
            
            // Create the anchor
            let anchorEntity = AnchorEntity(world: firstResult.worldTransform)
            
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            // Store references
            flowerAnchor = anchorEntity
            selectedEntity = modelEntity
            onPlaced?()
        }
        
        // Pan gesture: Move the existing object
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARView,
                  let flowerAnchor = flowerAnchor else { return }
            
            // Only allow dragging with 1 finger
            if recognizer.numberOfTouches > 1 {
                return
            }
            
            let location = recognizer.location(in: arView)
            
            switch recognizer.state {
            case .changed:
                // Raycast to find new position on the plane
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let firstResult = results.first {
                    // Update only positioning, preserving rotation and scale of the anchor
                    let newPosition = SIMD3<Float>(
                        firstResult.worldTransform.columns.3.x,
                        firstResult.worldTransform.columns.3.y,
                        firstResult.worldTransform.columns.3.z
                    )
                    
                    flowerAnchor.position = newPosition
                }
            default:
                break
            }
        }
        
        // Rotation gesture: Rotate the object
        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let entity = selectedEntity else { return }
            
            switch recognizer.state {
            case .began:
                print("Rotation began")
                
            case .changed:
                // recognizer.rotation is in radians
                let rotation = Float(recognizer.rotation)
                
                // Create a rotation quaternion around the Y axis
                let rotationUpdate = simd_quatf(angle: rotation, axis: [0, 1, 0])
                
                // Resetting the recognizer rotation to 0 allows us to apply incremental changes
                entity.transform.rotation = entity.transform.rotation * rotationUpdate
                recognizer.rotation = 0
                
            case .ended:
                print("Rotation ended")
                
            default:
                break
            }
        }
        
        // Pinch gesture: Scale the object
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let entity = selectedEntity else {
                print ("No entity is selected tap to place the flower first")
                return
            }
            
            switch recognizer.state {
            case .began:
                initialScale = entity.scale
                print ("Started scaling from \(initialScale)")
                
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                
                let clampscale = SIMD3<Float>(
                    x: max(minScale, min(maxScale, newScale.x)),
                    y: max(minScale, min(maxScale, newScale.y)),
                    z: max(minScale, min(maxScale, newScale.z))
                )
                entity.scale = clampscale
                
            case .ended:
                print ("Final scale \(entity.scale)")
                
            case .cancelled:
                entity.scale = initialScale
                print("Scale Cancelled")
                
            default: break
                
            }
        }
        
        
        // Drop petals animation
        func dropPetals() {
            guard let flowerAnchor = flowerAnchor else {
                print("No flower placed yet")
                return
            }
            
            // Check if all petals have been dropped
            if nextPetalIndex > totalPetals {
                print("All petals have already been dropped")
                return
            }
            
            // The petals in the USDZ are named "petal_01", "petal_02", etc.
            let petalName = String(format: "petal_%02d", nextPetalIndex)

            if let selectedEntity = selectedEntity, let petalEntity = selectedEntity.findEntity(named: petalName) as? ModelEntity {

                let worldMatrix = petalEntity.transformMatrix(relativeTo: nil)
                
                flowerAnchor.addChild(petalEntity)
                
                petalEntity.setTransformMatrix(worldMatrix, relativeTo: nil)

                var dropTransform = petalEntity.transform
                

                dropTransform.translation.y = 0.005 
                

                let randomYaw = Float.random(in: 0...(2 * .pi))
                let flatRot = simd_quatf(angle: .pi / 2, axis: [1, 0, 0]) // lay flat on ground
                let yawRot = simd_quatf(angle: randomYaw, axis: [0, 1, 0])
                dropTransform.rotation = yawRot * flatRot
                
                // Play animation over 2 seconds
                petalEntity.move(to: dropTransform, relativeTo: petalEntity.parent, duration: 2.0, timingFunction: .easeOut)
                
                // Keep the petal visible on the floor!
                print("Successfully animated \\(petalName) down to the floor")
            } else {
                print("Error: Could not find entity named \(petalName) in the 3D model. Hierarchy:")
                if let selectedEntity = selectedEntity {
                    listAllEntities(entity: selectedEntity, indent: 0)
                }
            }

            nextPetalIndex += 1
        }

        
        // Helper function to recursively list all entities
        func listAllEntities(entity: Entity, indent: Int) {
            let indentString = String(repeating: "  ", count: indent)
            print("\(indentString)- \(entity.name) (type: \(type(of: entity)))")
            
            for child in entity.children {
                listAllEntities(entity: child, indent: indent + 1)
            }
        }
    }
}

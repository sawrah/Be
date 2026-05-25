import RealityKit
import ARKit

let arView = ARView(frame: .zero)
arView.renderOptions.insert(.disableAREnvironmentLighting)
arView.renderOptions.insert(.disableGroundingShadows)
print("Valid")

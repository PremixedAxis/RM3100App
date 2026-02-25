//
//  TelemetrySceneView.swift
//  LearningApp
//
//  Created by Temporary Dev User on 2/4/26.
//

import SwiftUI
import SceneKit

struct TelemetrySceneView: UIViewRepresentable {
    var samples: [Sample]
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = .white
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        
        // 1. Setup Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 10, y: 10, z: 20)
        
        // Point camera at the origin
        let lookAt = SCNLookAtConstraint(target: scene.rootNode)
        cameraNode.constraints = [lookAt]
        
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Create Axes (X=Red, Y=Green, Z=Blue)
        createAxes(in: scene.rootNode)
        
        // 3. Current Position Marker (Black Dot)
        let sphere = SCNSphere(radius: 0.2)
        sphere.firstMaterial?.diffuse.contents = UIColor.black
        let currentMarker = SCNNode(geometry: sphere)
        currentMarker.name = "centerNode"
        currentMarker.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(currentMarker)
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene, let current = samples.last else { return }
        
        // Remove old trail dots
        scene.rootNode.childNodes.filter({ $0.name == "trailDot" }).forEach({ $0.removeFromParentNode() })
        
        let trailLimit = 100
        let recentSamples = samples.suffix(trailLimit)
        
        for sample in recentSamples {
            // Relative math: (Previous - Current)
            let relX = Float(sample.x - current.x)
            let relY = Float(sample.y - current.y)
            let relZ = Float(sample.z - current.z)
            
            // Skip drawing a red dot on top of the black center dot
            if abs(relX) < 0.01 && abs(relY) < 0.01 && abs(relZ) < 0.01 { continue }
            
            let dot = SCNSphere(radius: 0.1)
            dot.firstMaterial?.diffuse.contents = UIColor.red
            let dotNode = SCNNode(geometry: dot)
            dotNode.name = "trailDot"
            dotNode.position = SCNVector3(relX, relY, relZ)
            
            scene.rootNode.addChildNode(dotNode)
        }
    }
    
    // Helper to build the visual X, Y, Z lines
    private func createAxes(in rootNode: SCNNode) {
        let axisLength: CGFloat = 10.0
        let axisThickness: CGFloat = 0.03
        
        func buildAxis(color: UIColor, rotation: SCNVector3) -> SCNNode {
            let cyl = SCNCylinder(radius: axisThickness, height: axisLength)
            cyl.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: cyl)
            node.eulerAngles = rotation
            // Offset position because cylinder center is at 0,0,0
            return node
        }
        
        // Y Axis (Green) - Default orientation for cylinder
        rootNode.addChildNode(buildAxis(color: .green, rotation: SCNVector3(0, 0, 0)))
        
        // X Axis (Red) - Rotate Z by 90 degrees
        rootNode.addChildNode(buildAxis(color: .red, rotation: SCNVector3(0, 0, Float.pi / 2)))
        
        // Z Axis (Blue) - Rotate X by 90 degrees
        rootNode.addChildNode(buildAxis(color: .blue, rotation: SCNVector3(Float.pi / 2, 0, 0)))
    }
}


import Foundation
import ARKit

extension ARPlaneAnchor {
    
    //ShapedPlaneを追加する場合
    func addPlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        if let program = contents as? SCNProgram {
            material.program = program
        } else {
            material.diffuse.contents = contents
        }
        
        let planeNode = SCNNode(geometry: geometry)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
        
        return planeNode
    }
    
    //四角いPlaneを検知する場合
    func addPlaneNode(on node: SCNNode, color: UIColor) {
        
        // 平面ジオメトリを作成
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        geometry.materials.first?.diffuse.contents = color

        // 平面ジオメトリを持つノードを作成
        let planeNode = SCNNode(geometry: geometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
    }
    
    func updatePlaneNode(on node: SCNNode) {
        
        DispatchQueue.main.async(execute: {
            for childNode in node.childNodes {
                guard let plane = childNode.geometry as? SCNPlane else {continue}
                guard !PlaneSizeEqualToExtent(plane: plane, extent: self.extent) else {continue}

                // 平面ジオメトリのサイズを更新
                print("current plane size: (\(plane.width), \(plane.height))")
                plane.width = CGFloat(self.extent.x)
                plane.height = CGFloat(self.extent.z)
                print("updated plane size: (\(plane.width), \(plane.height))")
                
                break
            }
        })
    }
}

fileprivate func PlaneSizeEqualToExtent(plane: SCNPlane, extent: vector_float3) -> Bool {
    if plane.width != CGFloat(extent.x) || plane.height != CGFloat(extent.z) {
        return false
    } else {
        return true
    }
}


import UIKit
import SceneKit

extension UIColor {
    // iOS 11 Programmingのイメージ画像から取得
    class var bookYellow: UIColor {
        get {
            return UIColor(red: 0.857, green: 0.919, blue: 0, alpha: 0.3)
        }
    }
}

extension SCNNode {
    
    class func sphereNode(color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.007)
        geometry.materials.first?.diffuse.contents = color
        return SCNNode(geometry: geometry)
    }
    
//    class func textNode(text: String) -> SCNNode {
//        let geometry = SCNText(string: text, extrusionDepth: 0.01)
//        geometry.alignmentMode = kCAAlignmentCenter
//        if let material = geometry.firstMaterial {
//            material.diffuse.contents = UIColor.white
//            material.isDoubleSided = true
//        }
//        let textNode = SCNNode(geometry: geometry)
//
//        // フォントサイズ小さくしすぎると荒くなるので、scaleで調整
//        geometry.font = UIFont.systemFont(ofSize: 1)
//        textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)
//
//        // テキストが見えるようにtranslationを計算してpivotにセット
//        let (min, max) = geometry.boundingBox
//        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, min.y - 0.5, 0)
//
//        // Y軸を自由にしてカメラの方を向くように（親ノードに）制約をつける
//        let node = SCNNode()
//        let billboardConstraint = SCNBillboardConstraint()
//        billboardConstraint.freeAxes = SCNBillboardAxis.Y
//        node.constraints = [billboardConstraint]
//
//        node.addChildNode(textNode)
//
//        return node
//    }
    
    class func lineNode(length: CGFloat, color: UIColor) -> SCNNode {
        
        // 線としてのカプセル型ジオメトリを持つノード
        let geometry = SCNCapsule(capRadius: 0.002, height: length) // 半径4cm
        geometry.materials.first?.diffuse.contents = color
        let line = SCNNode(geometry: geometry)
        
        // lineをz軸に対して90°回転させるためのコンテナノード
        let node = SCNNode()
        node.eulerAngles = SCNVector3Make(Float.pi/2, 0, 0)
        node.addChildNode(line)
        
        return node
    }
}

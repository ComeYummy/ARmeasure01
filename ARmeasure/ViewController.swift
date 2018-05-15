//
//  ViewController.swift
//  ARMeasure
//
//  Created by Naoki Kameyama
//  Copyright © 2018 Naoki Kameyama. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?
    private var textNode: SCNNode?
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    
    var startPosition: SCNVector3!
    
    //timer同期用変数定義
    var isMeasuring = false
    var timer: Timer!
    
    //ARsessionフラグ
//    var ARsessionFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        
        // デバッグオプションをセット。デフォルトはoff
        sceneView.debugOptions = []
        sceneView.showsStatistics = false
        trackingStateLabel.isHidden = true
        
//       sceneView.debugOptions = [.renderAsWireframe, ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        //初回reset処理
        reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //ARのsession開始
        beginSession()
        
        //timer作成、update関数を呼び出し続ける
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        //timerスタート
        timer.fire()
        
    }
    
    // MARK: - Private
    
    private func putSphere(at pos: SCNVector3, color: UIColor) -> SCNNode {
        //点sphereを定義
        let node = SCNNode.sphereNode(color: color)
        //点をsceneView上に子nodeとして追加
        sceneView.scene.rootNode.addChildNode(node)
        //nodeのpositionを設定
        node.position = pos
        return node
    }
    
    private func drawLine(from: SCNNode, to: SCNNode, length: Float) -> SCNNode {
        //線nodeを定義
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: UIColor.red)
        //from点nodeにlinenodeを追加
        from.addChildNode(lineNode)
        //
        lineNode.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to.position)
        return lineNode
    }
    
    //configurationを設定してsession開始
    func beginSession(){
        // セッション開始
        let configuration = ARWorldTrackingConfiguration()
        //水平方向の平面検知
        //        configuration.planeDetection = .horizontal
        //垂直方向の平面検知
        //        configuration.planeDetection = .vertical
        //垂直・水平方向の平面検知
        configuration.planeDetection = [.vertical, .horizontal]
        
        // 現実の環境光に合わせてレンダリング
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    //hittestを実行して、始点を配置
    private func hitTestToSphere(_ pos: CGPoint) {
        
        // 検出平面と特徴点を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent, .featurePoint])
        
        // 平面のみを対象にヒットテストを実行
//      let results = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent])
        
        // 最も近い（手前にある）結果を取得
        guard let result = results.first else {return}
        
        // ヒットした位置を計算する.2D座標からSCNVector3座標へ変換
        let hitPosition = result.worldTransform.position()
        
        // 始点を配置する（始点ノードを追加）
        startNode = putSphere(at: hitPosition, color: UIColor.blue)
        
    }
    
    //hittestを実行して、終点を配置
    private func hitTestToEndSphere(_ pos: CGPoint) {
        
        // 検出平面と特徴点を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent, .featurePoint])
        
        // 最も近い（手前にある）結果を取得
        guard let result = results.first else {return}
        
        // ヒットした位置を計算する.2D座標からSCNVector3座標へ変換
        let hitPosition = result.worldTransform.position()
        
        // 終点を決定する（終点ノードを追加）
        endNode = putSphere(at: hitPosition, color: UIColor.green)
    }
    
    
    
    
    //timerで呼び出す関数
    // 計測中に円柱の描画を更新する
    @objc func update(tm: Timer) {
        //ifMeasuringがfalseならば発火させない。touchbeginでフラグ変更する。
        if isMeasuring {
            //0.1秒ごとにendNodeを画面中心点とする。
            // 始点はもう決まっているか？
            if let startNode = startNode {
                // 終点が既に決まっている場合はendNodeとlineNode,textNodeを一度removeする。
                    if let endNode = endNode {
                        endNode.removeFromParentNode()
                        lineNode?.removeFromParentNode()
                        textNode?.removeFromParentNode()
                    }

                //画面2D中心座標の取得
                let updateCenterPositon = sceneView.center //CGPoint型

                //hitTest&終点の配置。endNodeの再設定
                hitTestToEndSphere(updateCenterPositon)
                
                // 始点と終点の距離を計算する[m]
                let distance = ((endNode?.position)! - startNode.position).length()
                print("distance: \(distance) [m]")
                
                // 始点と終点を結ぶ線を描画する
                lineNode = drawLine(from: startNode, to: endNode!, length: distance)
                
                // ラベルに表示
                statusLabel.text = String(format: "Distance: %.2f [cm]", distance*100)
                
                //textnode表記を作成
                let textMessage = String(format: "%.2f cm", distance*100)
                //textnodeの追加
                appendtText(message: textMessage)
            } else {
                print("if letでstartNodeが存在しないとき")
            }
        }
    }
    
    
    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        // タップ位置のスクリーン座標を取得
        //        guard let touch = touches.first else {return}
        //        let pos = touch.location(in: sceneView)
        
        //statusLabelの表示
        statusLabel.isHidden = false
        //画面2D中心座標の取得
        let centerPosition2D = sceneView.center //CGPoint型
        
        //isMeasuringで場合分け
        if isMeasuring == false {
            //reset処理
            reset()
            //isMeasuringのフラグ変更
            isMeasuring = true
            //hitTest&始点の配置
            hitTestToSphere(centerPosition2D)
        //isMeasuringがtrueのときに画面タップ時の動作
        }else if isMeasuring == true {
            //isMeasuringのフラグ変更, これでupdateの動作が止まる。
            isMeasuring = false
        }
    }
    
    //計測した距離をAR上にテキスト表示
    func appendtText(message:String){
        let str = message
        let depth:CGFloat = 0.01
        let text = SCNText(string: str, extrusionDepth: depth)
//        text.font = UIFont(name: "HelveticaNeue-Light", size: 0.5);
        text.font = UIFont.systemFont(ofSize:1)
        textNode = SCNNode(geometry: text)
        
        //textNodeの0座標をendNodeの座標に設定
        textNode?.position = (endNode?.position)!
        
        // 縮小
        let scaleValue = 0.05
        textNode?.scale = SCNVector3(scaleValue, scaleValue, scaleValue)
        
        sceneView.scene.rootNode.addChildNode(textNode!)
    }
    
    
    
    // MARK: - Actions
    
    @IBAction func resetBtnTapped(_ sender: UIButton) {
        
        //alert表示前の設定
        let alertController = UIAlertController(title: "AR初期化", message: "ARをはじめの状態にもどします。\n検知した平面は削除されます。", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("OKが押された")
            //nodeをreset
            self.reset()
            //ARをstop
            self.stopARsession()
            //ARsession開始
            self.beginSession()
        }
        
        let action2 = UIAlertAction(title: "キャンセル", style: .default) { (action:UIAlertAction) in
            print("キャンセルが押された")
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        //alert表示
        self.present(alertController, animated: true, completion: nil)

    }
    
    //reset処理（初期化）
    private func reset() {
        //nodeを親nodeから削除
        startNode?.removeFromParentNode()
        //node自体を削除
        startNode = nil
        //nodeを親nodeから削除
        endNode?.removeFromParentNode()
        //node自体を削除
        endNode = nil
        //nodeを親nodeから削除
        textNode?.removeFromParentNode()
        //node自体を削除
        textNode = nil
        statusLabel.isHidden = true
        
        //isMeasuringフラグを初期化
        isMeasuring = false
    }
    
    //AR停止
    private func stopARsession(){
        //ARsession停止
        sceneView.session.pause()
        //ARsessionFlag
//        ARsessionFlag = false
    }
    
    
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        DispatchQueue.main.async(execute: {
            self.statusLabel.isHidden = !(frame.anchors.count > 0)
            if self.startNode == nil {
                self.statusLabel.text = "始点をタップしてください"
            }
        })
        
        //textnodeの向きを常にカメラ側にする。
        //カメラ座標の取得
        if let camera = sceneView.pointOfView {
            //textNodeのみオイラー角をカメラと同じにする。カメラ回転とnodeの回転を合わせる。
            textNode?.rotation = camera.rotation
            
//            let x = Double(camera.eulerAngles.x) * 180 / Double.pi
//            let y = Double(camera.eulerAngles.y) * 180 / Double.pi
//            let z = Double(camera.eulerAngles.z) * 180 / Double.pi
//            print(String(format: "eulerAngles x:%.2f y:%.2f z:%.2f", x/10, y/10, z/10))
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        // 平面検知したときanchorをprint
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        
        // 平面アンカーを可視化
        planeAnchor.addPlaneNode(on: node, color: UIColor.bookYellow.withAlphaComponent(0.1))
        
        // 仮想オブジェクトのノードを作成
        let virtualObjectNode = loadModel()
        
        DispatchQueue.main.async(execute: {
            // 仮想オブジェクトを乗せる
            node.addChildNode(virtualObjectNode)
        })
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
        
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    
    // 画面disapper時の動作
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //ARをstop
        stopARsession()
        //timer停止
        timer.invalidate()

    }
    
    //平面検知したときに呼び出し
    private func loadModel() -> SCNNode {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        
        let modelNode = SCNNode()
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child)
        }
        
        return modelNode
    }
    
    //debag用onoffスイッチ
    @IBAction func debugSwitch(_ sender: UISwitch) {
        if ( sender.isOn ) {
            //onのときはdebugOptionを有効に
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            sceneView.showsStatistics = true
            trackingStateLabel.isHidden = false
        } else {
            //offは無効
            sceneView.debugOptions = []
            sceneView.showsStatistics = false
            trackingStateLabel.isHidden = true
        }
        
    }
    
    
    

}

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
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    
    var startPosition: SCNVector3!
    
    //timer同期用変数定義
    var isMeasuring = false
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        // デバッグオプションをセット
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        //初回reset処理
        reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // セッション開始
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // 現実の環境光に合わせてレンダリングしてくれるらしい
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
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
    
    //hittestを実行して、始点を配置
    private func hitTestToSphere(_ pos: CGPoint) {
        
        // 平面を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.existingPlane])
        
        // 平面もしくは特徴点を対象にヒットテストを実行
        //        let results = sceneView.hitTest(pos, types: [.existingPlane, .featurePoint])
        
        // 最も近い（手前にある）結果を取得
        guard let result = results.first else {return}
        
        // ヒットした位置を計算する.2D座標からSCNVector3座標へ変換
        let hitPosition = result.worldTransform.position()
        
        // 始点を配置する（始点ノードを追加）
        startNode = putSphere(at: hitPosition, color: UIColor.blue)
        
    }
    
    //hittestを実行して、終点を配置
    private func hitTestToEndSphere(_ pos: CGPoint) {
        
        // 平面を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.existingPlane])
        
        // 平面もしくは特徴点を対象にヒットテストを実行
        //        let results = sceneView.hitTest(pos, types: [.existingPlane, .featurePoint])
        
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
                // 終点が既に決まっている場合はendNodeとlineNodeを一度removeする。
                    if let endNode = endNode {
                        endNode.removeFromParentNode()
                        lineNode?.removeFromParentNode()
                    }

                //画面2D中心座標の取得
                let updateCenterPositon = sceneView.center //CGPoint型

                //hitTest&終点の配置。endNodeの再設定
                hitTestToEndSphere(updateCenterPositon)
                
                // 始点と終点の距離を計算する
                let distance = ((endNode?.position)! - startNode.position).length()
                print("distance: \(distance) [m]")
                
                // 始点と終点を結ぶ線を描画する
                lineNode = drawLine(from: startNode, to: endNode!, length: distance)
                
                // ラベルに表示
                statusLabel.text = String(format: "Distance: %.2f [m]", distance)
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
    
    // MARK: - Actions
    
    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
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
        statusLabel.isHidden = true
        
        //isMeasuringフラグを初期化
        isMeasuring = false
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
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        planeAnchor.addPlaneNode(on: node, color: UIColor.bookYellow.withAlphaComponent(0.1))
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
        
        //ARsession停止
        sceneView.session.pause()
        //timer停止
        timer.invalidate()
    }
    

}

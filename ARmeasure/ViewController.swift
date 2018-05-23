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
import SCLAlertView
import BWWalkthrough

class ViewController: UIViewController, ARSCNViewDelegate, BWWalkthroughViewControllerDelegate {
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?
    private var textNode: SCNNode?
    
    private let device = MTLCreateSystemDefaultDevice()!
    
    @IBOutlet var screenshot: UIView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    @IBOutlet weak var mainBtn: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    
    var startPosition: SCNVector3!
    
    //navigationbar ボタン
    var myRightButton: UIBarButtonItem!
    
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
        
        // 右ボタンを作成する.
        myRightButton = UIBarButtonItem(image: UIImage(named: "info20.png"), style: .plain, target: self, action: #selector(ViewController.onClickMyButton(sender:)))
        myRightButton.tintColor = UIColor.white
        
        // ナビゲーションバーの右に設置する.
        self.navigationItem.rightBarButtonItem = myRightButton
        

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        //ARのsession開始
        beginSession()
        
        //timer作成、update関数を呼び出し続ける
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        //timerスタート
        timer.fire()
        

        
        //ナビゲーションバーの表示
        navigationController?.setNavigationBarHidden(false, animated: false)
        //backボタンの非表示
        self.navigationItem.hidesBackButton = true
        //バー背景色
        self.navigationController?.navigationBar.barTintColor = UIColor.rgba(red: 99, green: 176, blue: 184, alpha: 1.0)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.alpha  = 0.85
        
        //バーアイテムカラー
        self.navigationController?.navigationBar.tintColor = UIColor.white

        //タイトル文字色の変更
        self.navigationController?.navigationBar.titleTextAttributes = [
            // 文字の色
            .foregroundColor: UIColor.white
        ]
        //初期表示
        self.title = "スタート地点を選択してください"
        
        
        
        
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
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: UIColor.white)
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
        startNode = putSphere(at: hitPosition, color: UIColor.rgba(red: 99, green: 176, blue: 184, alpha: 1))
        
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
        endNode = putSphere(at: hitPosition, color: UIColor.rgba(red: 216, green: 81, blue: 62, alpha: 1))
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
                self.title = String(format: "Distance: %.2f cm", distance*100)

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
    
    //画面全体タップを認識する場合。
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        //        // タップ位置のスクリーン座標を取得
//        //        guard let touch = touches.first else {return}
//        //        let pos = touch.location(in: sceneView)
//
//        //画面2D中心座標の取得
//        let centerPosition2D = sceneView.center //CGPoint型
//
//        //isMeasuringで場合分け
//        if isMeasuring == false {
//            //reset処理
//            reset()
//            //isMeasuringのフラグ変更
//            isMeasuring = true
//            //hitTest&始点の配置
//            hitTestToSphere(centerPosition2D)
//        //isMeasuringがtrueのときに画面タップ時の動作
//        }else if isMeasuring == true {
//            //isMeasuringのフラグ変更, これでupdateの動作が止まる。
//            isMeasuring = false
//        }
//    }
    
    //計測した距離をAR上にテキスト表示
    func appendtText(message:String){
        let str = message
        let depth:CGFloat = 0.01
        let text = SCNText(string: str, extrusionDepth: depth)
//        text.font = UIFont(name: "HelveticaNeue-Light", size: 0.5);
        text.font = UIFont.systemFont(ofSize:1)
        //flatness ポリゴンの細かさ
        text.flatness = 0
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
        
        //SCLAlert
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false
        )
        
        
        let alertView = SCLAlertView(appearance: appearance)
        //ボタンの追加
        alertView.addButton("OK") {
            //タップ時の処理
            print("OKが押された")
            //nodeをreset
            self.reset()
            //ARをstop
            self.stopARsession()
            //ARsession開始
            self.beginSession()
            //初期表示
            self.title = "スタート地点を選択してください"
            
        }
        alertView.addButton("キャンセル") {
            print("キャンセルが押された")
        }
        //表示実行
        alertView.showNotice("AR初期化", subTitle: "ARをはじめの状態にもどします。\n検知した平面は削除されます。")
        
//        //alert表示前の設定
//        let alertController = UIAlertController(title: "AR初期化", message: "ARをはじめの状態にもどします。\n検知した平面は削除されます。", preferredStyle: .alert)
//
//        let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
//            print("OKが押された")
//            //nodeをreset
//            self.reset()
//            //ARをstop
//            self.stopARsession()
//            //ARsession開始
//            self.beginSession()
//            //初期表示
//            self.statusLabel.text = "スタート地点を選択してください"
//        }
//
//        let action2 = UIAlertAction(title: "キャンセル", style: .default) { (action:UIAlertAction) in
//            print("キャンセルが押された")
//        }
//
//        alertController.addAction(action1)
//        alertController.addAction(action2)
//        //alert表示
//        self.present(alertController, animated: true, completion: nil)

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
        
        //isMeasuringフラグを初期化
        isMeasuring = false
        //mainBtn画像変更
        mainBtn.setImage(changeButtonImage(flag: isMeasuring), for: UIControlState())
        
        
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
        guard sceneView.session.currentFrame != nil else {return}
        DispatchQueue.main.async(execute: {
//            self.statusLabel.isHidden = !(frame.anchors.count > 0)
            if self.startNode == nil {
//                self.statusLabel.text = "start pointを選択してください"
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
        
        //①四角い平面を検知する場合
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        // 平面検知したときanchorをprint
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")

        // 平面アンカーを可視化
        planeAnchor.addPlaneNode(on: node, color: UIColor.bookYellow.withAlphaComponent(0.1))
        
        //②ShapedPlaneにする場合
//        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
//        let planeGeometry = ARSCNPlaneGeometry(device: device)!
//        planeGeometry.update(from: planeAnchor.geometry)
//        planeAnchor.addPlaneNode(on: node, geometry: planeGeometry, contents: UIColor.bookYellow)
        
        
        
        
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
    
    //撮影ボタンタップ
    @IBAction func buttonTapped(_ sender: UIButton) {
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
            //isMeasuringフラグに合わせて、ボタン画像変更
            sender.setImage(changeButtonImage(flag: isMeasuring), for: UIControlState())
            //hitTest&始点の配置
            hitTestToSphere(centerPosition2D)
            //isMeasuringがtrueのときに画面タップ時の動作
        }else if isMeasuring == true {
            //isMeasuringのフラグ変更, これでupdateの動作が止まる。
            isMeasuring = false
            //isMeasuringフラグに合わせて、ボタン画像変更
            sender.setImage(changeButtonImage(flag: isMeasuring), for: UIControlState())
        }
    }
    
    //isMeasuringフラグでボタン画像変更
    func changeButtonImage(flag:Bool) -> UIImage{
        if flag{
            return UIImage(named:"button02.png")!//停止ボタン
        }else{
            return UIImage(named:"button01.png")!//開始ボタン
        }
    }
    
    //スクリーンショット保存機能
    //画面のImage生成
    func GetImage(view: UIView) -> UIImage{
        
        // ビットマップ画像のcontextを作成.
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0);
        
        self.view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        
        // 現在のcontextのビットマップをUIImageとして取得.
        let capturedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        // contextを閉じる.
        UIGraphicsEndImageContext()
        
        
        
        
          // ↓この方法だとscene Viewが真っ白になるよ。
//        // ビットマップ画像のcontextを作成.
//        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
//        let context: CGContext = UIGraphicsGetCurrentContext()!
//
//        // 対象のview内の描画をcontextに複写する.
//        self.layer.render(in: context)
//
//        // 現在のcontextのビットマップをUIImageとして取得.
//        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//
//        // contextを閉じる.
//        UIGraphicsEndImageContext()
        
        return capturedImage
    }
    
    //ボタンタップ時の動作
    @IBAction func tappedCaptureButton(_ sender: UIButton) {
        // キャプチャ画像を取得.
        let captureImage = GetImage(view: view) as UIImage
        
        // UIImage の画像をカメラロールに画像を保存
        UIImageWriteToSavedPhotosAlbum(captureImage, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    
    // 保存を試みた結果をダイアログで表示
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        
        //エラーSCLAlert
        if error != nil {
            let appearance = SCLAlertView.SCLAppearance(
                kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
                kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
                kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
                showCloseButton: false
            )
            
            let alertView = SCLAlertView(appearance: appearance)
            //ボタンの追加
            alertView.addButton("OK") {
                //タップ時の処理
                print("保存エラー！")
            }

            //表示実行
            alertView.showInfo("エラー", subTitle: "保存に失敗しました")
        }else{
            // 成功SCLAlert
            let appearance = SCLAlertView.SCLAppearance(
                kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
                kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
                kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
                showCloseButton: false
            )
            
            let alertView = SCLAlertView(appearance: appearance)
            //ボタンの追加
            alertView.addButton("OK") {
                //タップ時の処理
                print("保存成功")
            }
            
            //表示実行
            alertView.showSuccess("保存完了", subTitle: "カメラロールに保存しました")
        }
        
//        var title = "保存完了"
//        var message = "カメラロールに保存しました"
//
//        if error != nil {
//            title = "エラー"
//            message = "保存に失敗しました"
//        }
//
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//        // OKボタンを追加
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//
//        // UIAlertController を表示
//        self.present(alert, animated: true, completion: nil)
    }
    
    //画像を保存する関数
    private func saveImage (image: UIImage, fileName: String ) -> Bool{
        //pngで保存する場合
        let pngImageData = UIImagePNGRepresentation(image)
        // jpgで保存する場合
        //    let jpgImageData = UIImageJPEGRepresentation(image, 1.0)
        let documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        do {
            try pngImageData!.write(to: fileURL)
        } catch {
            //エラー処理
            return false
        }
        return true
    }
    
    //起動時の注意アラート
    func initialAlert(){
        
        //SCLAlertViewを利用
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false
        )
        
        
        let alertView = SCLAlertView(appearance: appearance)
        //ボタンの追加
        alertView.addButton("OK") {

        }
        //表示実行
        alertView.showInfo("はじめに", subTitle: "カメラで読み込むまで\n３秒ほどお待ちください😣\n平面を検知すると\n精度が上がります👍\nアヒルはオマケ🐤")

//        //alert表示前の設定
//        let alertController = UIAlertController(
//            title: "はじめに",
//            message: "カメラで読み込むまで\n３秒ほどお待ちください😣\n平面を検知すると精度が上がります👍\nアヒルはオマケ🐤",
//            preferredStyle: .alert)
//
//        let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
//
//        }
//
//        //Actionの設定
//        alertController.addAction(action1)
//
//        //alert表示
//        self.present(alertController, animated: true, completion: nil)
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
    

    
    
    //初回起動時はチュートリアルへ
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("showWalkthrough")
        
        let userDefaults = UserDefaults.standard
        
            if !userDefaults.bool(forKey: "walkthroughPresented") {
    
                showWalkthrough()
    
                userDefaults.set(true, forKey: "walkthroughPresented")
                userDefaults.synchronize()
            }
        
    }
    
    //WalkThrough画面表示
    func showWalkthrough(){
        
        print("showWalkthrough2")
        // Get view controllers and build the walkthrough
        let stb = UIStoryboard(name: "Walkthrough", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "walk") as! BWWalkthroughViewController
        
        let page_one = stb.instantiateViewController(withIdentifier: "walk1")
        let page_two = stb.instantiateViewController(withIdentifier: "walk2")
        let page_three = stb.instantiateViewController(withIdentifier: "walk3")
        let page_four = stb.instantiateViewController(withIdentifier: "walk4")
        
        // Attach the pages to the master
        walkthrough.delegate = self
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        walkthrough.add(viewController:page_four)
        
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        print("Current Page \(pageNumber)")
    }
    
    //closdボタンタップ時の動作
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
        
        //はじめに注意アラート
        initialAlert()
    }
    
    //navigationbar ボタンタップ
    @objc func onClickMyButton(sender: UIButton){
        showWalkthrough()
    }
    

    
}

//RGB 255段階表記
extension UIColor {
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}


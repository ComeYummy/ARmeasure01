//
//  TutorialViewController.swift
//  ARmeasure
//
//  Created by 亀山直季 on 2018/05/15.
//  Copyright © 2018年 NaokiKameyama. All rights reserved.
//

import UIKit


class TutorialViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //行間の調整
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 20
        let attributes = [kCTParagraphStyleAttributeName : style]
        textView.attributedText = NSAttributedString(string: textView.text,
                                                     attributes: attributes as [NSAttributedStringKey : Any])
        textView.font = UIFont.systemFont(ofSize: 20)
        
        //ボタンタップ時の背景画像変更
        startButton.setBackgroundImage(self.createImageFromUIColor(color: UIColor.blue), for: .highlighted)
//        startButton.setTitle("Tap!!!!!!!!", for: UIControlState.normal)
//        startButton.setTitle("highlited!!!!!!!!", for: UIControlState.highlighted)
        
    }
    
    //ボタンタップ時に背景色を変えたい。小さなこだわり。UIcolor指定からUIImageへの変換
    private func createImageFromUIColor(color: UIColor) -> UIImage {
        // 1x1のbitmapを作成
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        // bitmapを塗りつぶし
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        // UIImageに変換
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("createImageFromUIColor")
        return image!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

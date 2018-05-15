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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

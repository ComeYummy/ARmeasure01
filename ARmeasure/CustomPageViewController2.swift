//
//  CustomPageViewController2.swift
//  ARmeasure
//
//  Created by 亀山直季 on 2018/05/20.
//  Copyright © 2018年 NaokiKameyama. All rights reserved.
//

import UIKit
import BWWalkthrough

class CustomPageViewController2: UIViewController, BWWalkthroughPage{
    func walkthroughDidScroll(to: CGFloat, offset: CGFloat) {
        print("did scroll")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("four")
        
    }
    
    
    
}

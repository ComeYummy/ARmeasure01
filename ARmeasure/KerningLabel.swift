//
//  KerningLabel.swift
//  ARmeasure
//
//  Created by 亀山直季 on 2018/05/15.
//  Copyright © 2018年 NaokiKameyama. All rights reserved.
//

import UIKit

@IBDesignable
class KerningLabel: UILabel {
    @IBInspectable var kerning: CGFloat = 0.0 {
        didSet {
            if let attributedText = self.attributedText {
                let attribString = NSMutableAttributedString(attributedString: attributedText)
                attribString.addAttributes([.kern: kerning], range: NSRange(location: 0, length: attributedText.length))
                self.attributedText = attribString
            }
        }
    }
}

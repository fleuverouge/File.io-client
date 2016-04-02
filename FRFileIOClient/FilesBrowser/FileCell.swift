//
//  FileCell.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit

class FileCell: UICollectionViewCell {

    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        fileNameLabel.textColor = ColorTemplate.Text
        fileImageView.tintColor = ColorTemplate.Icon
        fileSizeLabel.textColor = ColorTemplate.SubText
//        layer.borderColor = ColorTemplate.MainTint.CGColor
    }

    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            super.selected = newValue
//            layer.borderWidth = newValue ? 1.0 : 0.0
            backgroundColor = newValue ? ColorTemplate.MainTint.colorByAdjustAlpha(0.3) : UIColor.clearColor()
        }
    }
}

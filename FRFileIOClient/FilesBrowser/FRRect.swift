//
//  FRRect.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 4/1/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit
extension CGRect {
    func rectByScaleWithRatio(ratio: CGFloat) -> CGRect {
        let newSize = size.sizeByScaleWithRatio(ratio)
        let newOrgX = size.width/2 - newSize.width / 2
        let newOrgY = size.height/2 - newSize.height / 2
        return CGRect(x: round(newOrgX), y: round(newOrgY), width: round(newSize.width), height: round(newSize.height))
    }
}

extension CGSize {
    func sizeByScaleWithRatio(ratio: CGFloat) -> CGSize {
        return CGSize(width: width * ratio, height: height * ratio)
    }
}
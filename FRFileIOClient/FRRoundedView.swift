//
//  FRRoundedView.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit

class FRRoundedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setCornerRadius(frame.size.height / 2)
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            setCornerRadius(newValue.size.height / 2)
        }
    }
    
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            setCornerRadius(newValue.size.height / 2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class FRRoundedImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setCornerRadius(frame.size.height / 2)
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            setCornerRadius(newValue.size.height / 2)
        }
    }
    
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            setCornerRadius(newValue.size.height / 2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
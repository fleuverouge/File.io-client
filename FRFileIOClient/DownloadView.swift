//
//  ProgressView.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit

class DownloadView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstDescLabel: UILabel!
    @IBOutlet weak var secondDescLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    class func view() -> DownloadView {
        let output = UIView.loadFromNibNamed("DownloadView") as! DownloadView
        output.progressView.tintColor = ColorTemplate.MainTint
        output.subviews[0].layer.cornerRadius = 4
        return output
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addToView(superView: UIView) {
        superView .addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[me]-0-|", options: [], metrics: nil, views: ["me": self]))
        superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[me]-0-|", options: [], metrics: nil, views: ["me": self]))
        progressView.progress = 0
    }
    
    func dismiss() {
        removeFromSuperview()
    }
}

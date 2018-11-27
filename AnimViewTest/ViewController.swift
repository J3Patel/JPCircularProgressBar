//
//  ViewController.swift
//  AnimViewTest
//
//  Created by MP-11 on 01/11/18.
//  Copyright © 2018 Jatin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let label = JPCircularProgressBar()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func loadView() {
        super.loadView()
        label.frame = CGRect(x: 0,
                             y: 100,
                             width: UIScreen.main.bounds.width,
                             height: UIScreen.main.bounds.width)
        view.addSubview(label)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        label.setNeedsDisplay()
    }

}


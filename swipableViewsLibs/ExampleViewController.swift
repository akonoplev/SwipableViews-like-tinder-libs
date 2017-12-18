//
//  ViewController.swift
//  swipableViewsLibs
//
//  Created by Андрей Коноплев on 18.12.17.
//  Copyright © 2017 Андрей Коноплев. All rights reserved.
//

import UIKit

class ExampleViewController: UIViewController {

    @IBOutlet weak var exampleSwipableView: SwipableViews!
    
    let viewNib = UINib(nibName: "SwipableView", bundle: nil)
    var dataArray = [1,2,3,4,5,6,7,8,9]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exampleSwipableView.registerNib(nib: viewNib)
        exampleSwipableView.dataSource = self
        exampleSwipableView.delegate = self
    }
}


//MARK: dataSource and delegate func
extension ExampleViewController: SwipableViewsDelegate, SwipableViewsDataSource {
    func numberOfViews() -> Int {
        return dataArray.count
    }
    
    func view(view: UIView, atIndex index: Int) {
        let label = view.viewWithTag(11) as! UILabel
        label.text = "\(dataArray[index])"

    }
    
    func willSwiped(direction: swipeDirection, index: Int) {
        if index <= dataArray.count {
            for i in dataArray.count + 1...dataArray.count + 10 {
                dataArray.append(i)
            }
            exampleSwipableView.reloadData()
        }
    }
}


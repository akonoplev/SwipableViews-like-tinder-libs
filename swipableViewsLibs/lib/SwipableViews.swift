//
//  SwipableViews.swift
//  swipableViewsLibs
//
//  Created by Андрей Коноплев on 18.12.17.
//  Copyright © 2017 Андрей Коноплев. All rights reserved.
//

import UIKit

enum swipeDirection {
    case left
    case right
}

protocol SwipableViewsDataSource: class {
    func view ( view : UIView , atIndex index : Int )
    func numberOfViews () -> Int
}
protocol SwipableViewsDelegate: class {
    func willSwiped ( direction : swipeDirection , index : Int )
}


//MARK: - interface
class SwipableViews: UIView {
    weak var dataSource : SwipableViewsDataSource?
        {
        didSet
        {
            setUp()
        }
    }
    weak var delegate : SwipableViewsDelegate?
    
    private var nib : UINib?
    
    var visibleViews = NSArray()
    var visibleIndex = 0
    var modelsCount = 0
    var visivleReuseCardIndex = 0
    let operationQueue = OperationQueue()
    
    func registerNib ( nib : UINib )
    {
        self.nib = nib
    }
    
    private func setUp ()
    {
        clipsToBounds = false
        
        if nib == nil
        {
            print("Nib is nil")
            return
        }
        
        drawViews()
    }
    
    func reloadData ()
    {
        if modelsCount >= dataSource!.numberOfViews(){
            print("error")
            return
        }
        
        let dataDiff = dataSource!.numberOfViews() - modelsCount
        let  viewsDiff = dataDiff > 3 - subviews.count ? 3 - subviews.count : dataDiff
        
        if viewsDiff >= 0 {
            modelsCount = dataSource!.numberOfViews()
            renderViews(number: viewsDiff, startIndex: visibleIndex + 1 )
        }
    }
    
    private func drawViews ()
    {
        modelsCount = dataSource!.numberOfViews()
        if dataSource!.numberOfViews() == 0
        {
            return
        }
        
        let viewsNumber = dataSource!.numberOfViews() >= 3 ? 3 : modelsCount
        renderViews( number: viewsNumber, startIndex: visibleIndex )
    }
    
    private func renderViews ( number : Int, startIndex: Int )
    {
        let viewsArray = NSMutableArray()
        var indexCounter = startIndex
        
        for _ in 0..<number
        {
            let rawView = nib!.instantiate(withOwner: nil, options: nil)[0] as! UIView
            dataSource!.view(view: rawView, atIndex: indexCounter)
            
            rawView.frame = bounds
            insertSubview(rawView, at: 0)
            viewsArray.add(rawView)
            indexCounter += 1
        }
        
        visibleViews = viewsArray.count > 0 ?  viewsArray : visibleViews
        
        
        addRecognizers()
    }
    
    private func addRecognizers ()
    {
        for i in 0..<visibleViews.count
        {
            let view = visibleViews[i] as! UIView
            addPanGestureRecognizer ( view: view )
        }
    }
    
    private func addPanGestureRecognizer ( view : UIView )
    {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(rec:)))
        view.addGestureRecognizer(recognizer)
    }
}

//MARK:- селекторы жестовых распознавателей
extension SwipableViews
{
    @objc func handlePan(rec: UIPanGestureRecognizer) {
        let view = rec.view!
        let translation = rec.translation(in: self)
        
        let centerDiff = view.center.x - self.bounds.width / 2
        
        // center movement
        let newCenter = CGPoint(x: self.bounds.width / 2 + translation.x, y: self.bounds.height / 2 + translation.y)
        view.center = newCenter
        
        // вращение
        let rotator = self.bounds.width / 2 / 0.3
        
        view.transform = CGAffineTransform(rotationAngle: centerDiff / rotator)
        if rec.state == .ended {
            if fabs(centerDiff) >= view.frame.size.width / 2 && centerDiff > 0 {
                //доводчик в лево
                UIView.animate(withDuration: 0.1, animations: {
                    view.center = CGPoint(x: view.center.x + 500, y: view.center.y)
                }, completion: { [weak self] (finished) in
                    self?.handleAction(direction: .right, view: view)
                })
            } else if fabs(centerDiff) >= view.frame.size.width / 2 && centerDiff < 0 {
                UIView.animate(withDuration: 0.1, animations: {
                    view.center = CGPoint(x: view.center.x - 500, y: view.center.y)
                }, completion: { [weak self] (finished) in
                    self?.handleAction(direction: .left, view: view)
                })
            } else {
                //доводчик в центр
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    if self != nil {
                        view.center = CGPoint(x: self!.bounds.size.width / 2, y: self!.bounds.size.height / 2)
                    }
                    view.transform = .identity
                })
                
            }
        }
    }
    
    
    
    func handleAction ( direction : swipeDirection , view : UIView)
    {
        delegate?.willSwiped(direction: direction, index: visibleIndex)
        view.removeFromSuperview()
        
        
        if modelsCount - visibleIndex <= 3
        {
            if visibleIndex < modelsCount  {
                visibleIndex += 1
                return
            }
        }
        visivleReuseCardIndex = visivleReuseCardIndex == 2 ? 0 : visivleReuseCardIndex + 1
        
        dataSource?.view(view: view, atIndex: visibleIndex + 3 )
        view.transform = CGAffineTransform.identity
        view.frame = bounds
        insertSubview(view, at: 0)
        visibleIndex += 1
    }
}

extension SwipableViews {
    func autoSwipe(direction: swipeDirection) {
        operationQueue.maxConcurrentOperationCount = 1
        
        if operationQueue.operations.count > 1 {
            operationQueue.cancelAllOperations()
        }
        
        let animateOperation = AutomaticSwipeOperation(direction: direction, superview: self) { }
        operationQueue.addOperation(animateOperation)
    }
}


class AutomaticSwipeOperation: Operation {
    var direction: swipeDirection?
    var superview: SwipableViews!
    var success: () -> ()
    var view: UIView!
    
    init(direction: swipeDirection, superview: SwipableViews, success: @escaping ()-> ()) {
        self.success = success
        super.init()
        self.direction = direction
        self.superview = superview
        
    }
    
    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            
            self.view = self.superview.subviews.last
            let newCenter = self.direction == .left ? CGPoint(x: self.view.center.x - 500 , y: self.view.center.y) : CGPoint(x: self.view.center.x + 500 , y: self.view.center.y)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.center = newCenter
                let centerDiff = self.view.center.x - self.superview.bounds.width / 2
                let rotator = self.superview.bounds.width / 2 / 0.3
                self.view.transform = CGAffineTransform(rotationAngle: centerDiff / rotator)
            }) { (finished) in
                
                if finished
                {
                    self.superview.handleAction(direction: self.direction!, view: self.view)
                    self.success()
                    semaphore.signal()
                    
                }
            }
        }
        
        
        _ = semaphore.wait(timeout: .distantFuture)
        
    }
}

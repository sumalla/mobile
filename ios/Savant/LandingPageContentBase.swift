//
//  LandingPageContentBase.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class LandingPageContentBase: FakeNavBarViewController {

    let coordinator: CoordinatorReference<SignInState>
    var cancelBlock: SCSCancelBlock?

    init(coordinator c: CoordinatorReference<SignInState>) {
        coordinator = c
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if let cancelBlock = cancelBlock {
            cancelBlock()
        }
    }

}

extension LandingPageContentBase: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view as? ErrorTextField != nil || touch.view.superview as? ErrorTextField != nil || touch.view as? TTTAttributedLabel != nil{
            return false
        } else {
            return true
        }
    }

    func handleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
}

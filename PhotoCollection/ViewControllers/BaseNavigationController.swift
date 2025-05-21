//
//  BaseNavigationController.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/18/25.
//

import UIKit

class BaseNavigationController: UINavigationController {
    var isNewViewControllerBeingAdded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func contains(viewController: UIViewController) -> Bool {
        return viewControllers.map { $0.className }.contains(viewController.className)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if (!isNewViewControllerBeingAdded && !contains(viewController: viewController)) {
            isNewViewControllerBeingAdded = true
            super.pushViewController(viewController, animated: animated)
        }
    }
}

extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isNewViewControllerBeingAdded = false
    }
}

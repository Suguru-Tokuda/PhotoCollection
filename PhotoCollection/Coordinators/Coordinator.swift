//
//  Coordinator.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/18/25.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
    func finish()
}

//
//  MainCoordinator.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/18/25.
//

import UIKit

enum TabBarPage {
    case dogs
    case cats
    case search
    
    init?(index: Int) {
        switch index {
        case 0:
            self = .dogs
        case 1:
            self = .cats
        case 2:
            self = .search
        default:
            return nil
        }
    }
    
    var tabTitle: String {
        switch self {
        case .dogs:
            return "Dogs"
        case .cats:
            return "Cats"
        case .search:
            return "Search"
        }
    }
    
    var tabOrderNumber: Int {
        switch self {
        case .dogs:
            return 0
        case .cats:
            return 1
        case .search:
            return 2
        }
    }
    
    var tabImage: UIImage? {
        switch self {
        case .dogs:
            return UIImage(systemName: "dog.fill")
        case .cats:
            return UIImage(systemName: "cat.fill")
        case .search:
            return UIImage(systemName: "magnifyingglass")
        }
    }
}

protocol MainCoordinatorProtocol: Coordinator {
    func showMainFlow()
}

class MainCoordinator: MainCoordinatorProtocol {
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()

    init(_ navigationController: UINavigationController = BaseNavigationController()) {
        self.navigationController = navigationController
        navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        showMainFlow()
    }

    func showMainFlow() {
        let tabCoordinator = TabCoordinator(navigationController)
        tabCoordinator.start()
        childCoordinators.append(tabCoordinator)
    }

    func finish() {
        childCoordinators.forEach { $0.finish() }
        childCoordinators.removeAll()
        navigationController.popToRootViewController(animated: true)
    }
}

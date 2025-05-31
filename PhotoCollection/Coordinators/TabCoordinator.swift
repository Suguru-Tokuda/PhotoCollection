//
//  TabCoordinator.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/18/25.
//

import UIKit

protocol TabCoordinatorProtocol: Coordinator {
    var tabBarController: UITabBarController { get set }
    func selectPage(_ page: TabBarPage)
    func setSelectedIndex(_ index: Int)
    func currentPage() -> TabBarPage?
}

class TabCoordinator: NSObject, TabCoordinatorProtocol {
    var tabBarController: UITabBarController
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(_ navigationController: UINavigationController = BaseNavigationController()) {
        self.navigationController = navigationController
        tabBarController = UITabBarController()
        super.init()
    }
    
    func selectPage(_ page: TabBarPage) {
        UIView.performWithoutAnimation { [weak self] in
            self?.tabBarController.selectedIndex = page.tabOrderNumber
        }
    }
    
    func setSelectedIndex(_ index: Int) {
        guard let page = TabBarPage.init(index: index) else { return }

        selectPage(page)
    }
    
    func currentPage() -> TabBarPage? {
        TabBarPage(index: tabBarController.selectedIndex)
    }
    
    func start() {
        let pages: [TabBarPage] = [
            .dogs,
            .cats,
            .search
        ].sorted(by: { $0.tabOrderNumber < $1.tabOrderNumber })
        let controllers: [UINavigationController] = pages.compactMap({ getTabController($0) })
        prepareTabBarController(withTabControllers: controllers)
    }
    
    func finish() {
        childCoordinators.removeAll()
    }
    
    private func getTabController(_ page: TabBarPage) -> UINavigationController? {
        var navController: UINavigationController?

        switch page {
        case .dogs:
            navController = BaseNavigationController()
            let viewController = PhotoCollectionViewController(allowBatchCaching: false,
                                                               query: .dogs,
                                                               searchEnabled: false)
            navController?.setViewControllers([viewController], animated: false)
        case .cats:
            navController = BaseNavigationController()
            let viewController = PhotoCollectionViewController(allowBatchCaching: true,
                                                               query: .cats,
                                                               searchEnabled: false)
            navController?.setViewControllers([viewController], animated: false)
        case .search:
            navController = BaseNavigationController()
            let viewControllejr = PhotoCollectionViewController(allowBatchCaching: true,
                                                                searchEnabled: true)
            navController?.setViewControllers([viewControllejr], animated: false)
        }

        navController?.setNavigationBarHidden(true, animated: false)
        navController?.tabBarItem = UITabBarItem.init(title: page.tabTitle,
                                                      image: page.tabImage,
                                                      tag: page.tabOrderNumber)

        return navController
    }

    private func prepareTabBarController(withTabControllers tabControllers: [UIViewController]) {
        tabBarController.delegate = self
        tabBarController.setViewControllers(tabControllers, animated: false)
        tabBarController.selectedIndex = TabBarPage.dogs.tabOrderNumber
        tabBarController.tabBar.isTranslucent = false
        navigationController.viewControllers = [tabBarController]
    }
}

extension TabCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let newIndex = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        setSelectedIndex(newIndex)
        return false
    }
}

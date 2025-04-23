//
//  MessagesViewController.swift
//  TutorFinder
//
//  Created by Evan Oberneder on 4/12/25.
//

import UIKit

class MessagesViewController: UIViewController, UITabBarDelegate {
    
    // MARK: - UI Components
    private let bottomNavBar = UITabBar()

    // MARK: - Variables
    private var userToken: String
    
    let classesTab = UITabBarItem(
        title: "Classes",
        image: UIImage(systemName: "book"),
        tag: 0
    )
    
    let profileTab = UITabBarItem(
        title: "Profile",
        image: UIImage(systemName: "person.circle"),
        tag: 2
    )
    
    let messagesTab = UITabBarItem(
        title: "Messages",
        image: UIImage(systemName: "message.fill"),
        tag: 1
    )

    // MARK: - Initialization
    
    init(token: String = UserDefaults.standard.string(forKey: "userToken") ?? "No token found") {
        self.userToken = token
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    // Reload Table everytime you go back to it
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomNavBar.selectedItem = messagesTab
        //loadMessages()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        //loadMessages()
        setupBottomNavigation()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        self.title = "Messages"
        
        //Bottom Navigation Bar
        bottomNavBar.delegate = self
        view.addSubview(bottomNavBar)
    }
    
    private func setupConstraints() {
        bottomNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bottomNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomNavBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomNavBar.heightAnchor.constraint(equalToConstant: 49)
            
        ])
    }
    
    // MARK: - Actions
    
    private func setupBottomNavigation() {
        bottomNavBar.items = [classesTab, messagesTab, profileTab]
        bottomNavBar.selectedItem = classesTab
        bottomNavBar.delegate = self
        
        bottomNavBar.barTintColor = .white
        bottomNavBar.tintColor = .purple
        bottomNavBar.unselectedItemTintColor = .gray
        bottomNavBar.isTranslucent = false
    }
    
    // MARK: - Helpers
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

// MARK: - UITabBarDelegate
extension MessagesViewController: UITabBarControllerDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            DispatchQueue.main.async { // Go to main thread (currently on background thread from network request)
                if let windowScene = self.view.window?.windowScene { // Update to class window
                    let classesVC = ClassesViewController()
                    let navController = UINavigationController(rootViewController: classesVC)
                    windowScene.windows.first?.rootViewController = navController
                    windowScene.windows.first?.makeKeyAndVisible()
                }
            }
        }
        if item.tag == 2 {
            DispatchQueue.main.async { // Go to main thread (currently on background thread from network request)
                if let windowScene = self.view.window?.windowScene { // Update to class window
                    let profileVC = ProfileViewController(token: self.userToken)
                    let navController = UINavigationController(rootViewController: profileVC)
                    windowScene.windows.first?.rootViewController = navController
                    windowScene.windows.first?.makeKeyAndVisible()
                }
            }
        }
    }
}

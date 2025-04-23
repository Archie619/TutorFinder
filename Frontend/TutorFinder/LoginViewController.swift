//
//  LoginViewController.swift
//  TutorFinder
//
//  Created by RENIK MULLER on 27/03/2025.
//

import UIKit

class LoginViewController: UIViewController {
    
    struct LoginResponse: Codable {
        let token: String?
        //let username: String?
        let valid: Bool
        let errormsg: String?
    }

    // MARK: - UI Components
    
    private let gradientLayer = CAGradientLayer()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "graduationcap.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tutor Finder"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white.withAlphaComponent(0.9)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.accessibilityIdentifier = "usernameTextField"
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white.withAlphaComponent(0.9)
        textField.isSecureTextEntry = true // Turn to false for testing
        textField.autocapitalizationType = .none
        textField.accessibilityIdentifier = "passwordTextField"
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0) // Purple color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = "loginButton"
        return button
    }()
    
    private let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Account", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let guestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue as Guest", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupConstraints()
        setupActions()
        
        // Allows user to tap/swipe out of keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false 
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Background Setup
    
    private func setupGradientBackground() {
        let darkPurple = UIColor(red: 0.3, green: 0.1, blue: 0.5, alpha: 1.0).cgColor
        let lightPurple = UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
        
        gradientLayer.colors = [darkPurple, lightPurple]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(loginButton)
        stackView.addArrangedSubview(createAccountButton)
        stackView.addArrangedSubview(guestButton)
        
        
        view.addSubview(stackView)
    }
    
    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            guestButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
        guestButton.addTarget(self, action: #selector(guestButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc public func loginButtonTapped() {
        // Get text from text fields
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            
            // If any field empty, alert user
            let alert = UIAlertController(title: "Error",
                                      message: "1 or more fields left blank.",
                                      preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)) // Add "OK" button to exit alert
            present(alert, animated: true) // Show 2 user
            return // Leave function
            
        }
        
        /*-----------------*
         * SEND TO BACKEND *
         *-----------------*/
        
        let url = URL(string: "http://172.30.195.217:8000/login")!
        
        // Build URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Expected PyDantic Model:
        // User:
        //      username: str
        //      password: str
        
        // Take parameters -> Convert into JSON -> Put into request.
        // do/catch block for potential JSONSerialization fail
        do {
            let parameters = ["username": username, "password": password] // Create dictionary according to User
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: []) // Convert 2 JSON
            request.httpBody = jsonData // Attach to request
            request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Tells server data is in request body
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)") // Print error message according to error from catch block
            return
        }
        
        
        // Build URLSession
        let task = URLSession.shared.dataTask(with: request) { data, response, error in // Create shared session w/ dataTask(request)
            
            // Check for errors
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            // Handle response if data (response) exist
            if let data = data {
                // Parse JSON response into expected response (SignupResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(LoginResponse.self, from: data) // Try to decode data
                    
                    if jsonResponse.valid, let token = jsonResponse.token {
                        // Success, send user to class page
                        // Save token
                        UserDefaults.standard.set(jsonResponse.token, forKey: "userToken")
                        UserDefaults.standard.set(username, forKey: "username")
                        
                        DispatchQueue.main.async { // Go to main thread (currently on background thread from network request)
                            if let windowScene = self.view.window?.windowScene { // Update to class window
                                let classVC = ClassesViewController()
                                let navController = UINavigationController(rootViewController: classVC)
                                windowScene.windows.first?.rootViewController = navController
                                windowScene.windows.first?.makeKeyAndVisible()
                            }
                        }
                        
                    } else {
                        // Success, alert user that sign up was successful & send back to login
                        let alert = UIAlertController(title: "TutorBuddy",
                                                  message: "Invalid username/password",
                                                  preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        DispatchQueue.main.async {
                            self.present(alert, animated: true)
                        }
                        return
                    }
                    
                } catch {
                    print("Failed to parse JSON")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    @objc private func createAccountTapped() {
        // Navigate to signup screen
        let signupVC = SignupViewController()
        navigationController?.pushViewController(signupVC, animated: true)
    }
    
    @objc private func guestButtonTapped() {
        let classVC = ClassesViewController(token: "guest_token")
        
        if let navController = navigationController {
            navController.setViewControllers([classVC], animated: true)
        } else {
            let navController = UINavigationController(rootViewController: classVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

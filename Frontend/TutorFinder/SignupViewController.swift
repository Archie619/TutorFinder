//
//  SignupViewController.swift
//  TutorFinder
//
//  Created by RENIK MULLER on 27/03/2025.
//
import UIKit

class SignupViewController: UIViewController {
    
    struct SignupResponse: Codable {
        let user: String
        let valid: Bool
        let errormsg: String?
    }
    
    // MARK: - UI Components
    
    private let gradientLayer = CAGradientLayer()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
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
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white.withAlphaComponent(0.9)
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Confirm Password"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white.withAlphaComponent(0.9)
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Already have an account? Login", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupConstraints()
        setupActions()
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
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(confirmPasswordTextField)
        stackView.addArrangedSubview(signupButton)
        stackView.addArrangedSubview(loginButton)
        
        view.addSubview(stackView)
    }
    
    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            usernameTextField.heightAnchor.constraint(equalToConstant: 45),
            passwordTextField.heightAnchor.constraint(equalToConstant: 45),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 45),
            signupButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        signupButton.addTarget(self, action: #selector(signupButtonTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func signupButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(message: "Passwords don't match")
            return
        }
        
        signup(username: username, password: password)
    }
    
    @objc private func loginButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Networking
    
    public func signup(username: String, password: String) {
        
        /*-----------------*
         * SEND TO BACKEND *
         *-----------------*/
        
        let url = URL(string: "http://172.30.195.217:8000/signup")!
        
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
                    let jsonResponse = try JSONDecoder().decode(SignupResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    if jsonResponse.valid {
                        // Success, alert user that sign up was successful & send back to login
                        let alert = UIAlertController(title: "TutorBuddy",
                                                  message: "Account Created!",
                                                  preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Sign in", style: .default, handler: { action in // When sign in tapped...
                            DispatchQueue.main.async { // Ensures UI Updates happen on main thread - not background thread! (NEEDED)
                                self.navigationController?.popViewController(animated: true) // Close current view, return to main screen
                            }
                        }))
                        DispatchQueue.main.async {
                            self.present(alert, animated: true)
                        }
                    } else {
                        // Success, alert user that sign up was successful & send back to login
                        let alert = UIAlertController(title: "TutorBuddy",
                                                  message: "Invalid username/password length.",
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
    
    // MARK: - Helpers
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlertWithAction(title: String, message: String, action: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            action()
        })
        present(alert, animated: true)
    }
}

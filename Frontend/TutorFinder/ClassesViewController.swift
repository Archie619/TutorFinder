//
//  ClassesViewController.swift
//  TutorFinder
//
//  Created by RENIK MULLER on 27/03/2025.
//
import UIKit

class ClassesViewController: UIViewController, UITabBarDelegate {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let addButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let bottomNavBar = UITabBar()
    
    // MARK: - Properties
    
    private var classes: [Class] = []
    private var filteredClasses: [Class] = []
    private var isSearching = false
    private var userToken: String
    
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
        loadClasses()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadClasses()
        setupBottomNavigation()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        self.title = "My Classes"
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ClassTableViewCell.self, forCellReuseIdentifier: ClassTableViewCell.identifier)
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "classesTableView"
        view.addSubview(tableView)
        
        //Bottom Navigation Bar
        bottomNavBar.delegate = self
        view.addSubview(bottomNavBar)
        
        // Add Button
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.backgroundColor = .systemPurple
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 25
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 4
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        view.addSubview(addButton)
        
        // Search Button
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.backgroundColor = .systemPurple
        searchButton.tintColor = .white
        searchButton.layer.cornerRadius = 25
        searchButton.layer.shadowColor = UIColor.black.cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchButton.layer.shadowOpacity = 0.3
        searchButton.layer.shadowRadius = 4
        searchButton.accessibilityIdentifier = "searchGeneralButton"
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        view.addSubview(searchButton)
        
        // Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
    
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        bottomNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Search button constraints
            searchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            searchButton.widthAnchor.constraint(equalToConstant: 50),
            searchButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            bottomNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomNavBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomNavBar.heightAnchor.constraint(equalToConstant: 49)
            
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadClasses() {
        loadingIndicator.startAnimating()
        
        APIManager.shared.loadClasses(token: userToken) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if let response = response, response.valid, let classes = response.classes {
                    self.classes = classes
                    self.tableView.reloadData()
                } else {
                    self.showAlert(message: "Invalid Token.")
                }
            }
        }
    }
    
    private func searchClasses(with specification: ClassSpecification) {
        loadingIndicator.startAnimating()
        
        APIManager.shared.searchClasses(specification: specification) { [weak self] response in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if let classes = response?.classes {
                    // Navigate to search screen
                    let searchVC = SearchViewController()
                    searchVC.setClasses(classes: classes)
                    self.navigationController?.pushViewController(searchVC, animated: true)
                } else {
                    self.showAlert(message: "Search failed")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func setupBottomNavigation() {
        let classesTab = UITabBarItem(
            title: "Classes",
            image: UIImage(systemName: "book"),
            tag: 0
        )
        
        let profileTab = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle"),
            tag: 1
        )
        
        bottomNavBar.items = [classesTab, profileTab]
        bottomNavBar.selectedItem = classesTab
        bottomNavBar.delegate = self
        
        bottomNavBar.barTintColor = .white
        bottomNavBar.tintColor = .purple
        bottomNavBar.unselectedItemTintColor = .gray
        bottomNavBar.isTranslucent = false
    }
    
    @objc private func addButtonTapped() {
        showAddClassDialog()
    }
    
    @objc private func searchButtonTapped() {
        showSearchClassDialog()
    }
    
    private func showAddClassDialog() {
        let alert = UIAlertController(title: "Add Class", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Department"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Class ID"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Class Name"
        }
        
        let segment = UISegmentedControl(items: ["Tutor", "Student"])
        segment.selectedSegmentIndex = 0
        segment.frame = CGRect(x: 10, y: 60, width: 250, height: 40)
        alert.view.addSubview(segment)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let dept = alert.textFields?[0].text, !dept.isEmpty,
                  let id = alert.textFields?[1].text, !id.isEmpty,
                  let name = alert.textFields?[2].text, !name.isEmpty else {
                        self?.showAlert(message: "Please fill in all fields")
                        return }
            let designation = segment.selectedSegmentIndex == 0 ? "tutor" : "student"
            self.addClass(dept: dept, id: id, name: name, designation: designation)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showSearchClassDialog() {
        let alert = UIAlertController(title: "Search Classes", message: "\n\n\n", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Department"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Class ID"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Class Name"
        }
        
        let addAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let self = self,
                  let dept = alert.textFields?[0].text,
                  let id = alert.textFields?[1].text,
                  let name = alert.textFields?[2].text else { return }
            
            self.searchClasses(with: ClassSpecification(dept: dept, id: id, name: name))
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        addAction.accessibilityIdentifier = "searchAlertButton"
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func addClass(dept: String, id: String, name: String, designation: String) {
        loadingIndicator.startAnimating()
        
        let specification = AddUserToClassSpecification(
            token: userToken,
            designation: designation,
            dept: dept,
            id: id,
            name: name
        )
        
        APIManager.shared.addClass(specification: specification) { [weak self] response in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if response?.valid == true {
                    self.showAlert(message: "Class added successfully!")
                    self.loadClasses() // Refresh the list
                } else if response?.errormsg == "user already in class" {
                    self.showAlert(message: "Class is already added!")
                } else {
                    self.showAlert(message: "Failed to add class")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate

extension ClassesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredClasses.count : classes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClassTableViewCell.identifier, for: indexPath) as! ClassTableViewCell
        cell.accessibilityIdentifier = "classesTableViewCell"
        
        let classItem = isSearching ? filteredClasses[indexPath.row] : classes[indexPath.row]
        cell.configure(with: classItem)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let classItem = isSearching ? filteredClasses[indexPath.row] : classes[indexPath.row]
        // Navigate to class detail view if needed
        let postsVC = ClassPostsViewController(classItem: classItem)
        navigationController?.pushViewController(postsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - UISearchBar Delegate

extension ClassesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            tableView.reloadData()
        } else {
            isSearching = true
            let specification = ClassSpecification(dept: searchText, id: searchText, name: searchText)
            searchClasses(with: specification)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
}

// MARK: - UITabBarDelegate
extension ClassesViewController: UITabBarControllerDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 1 {
            let profileVC = ProfileViewController(token: userToken)
            navigationController?.pushViewController(profileVC, animated: true)
        }
    }
}

// MARK: - Class Table View Cell

class ClassTableViewCell: UITableViewCell {
    static let identifier = "ClassTableViewCell"
    
    private let deptLabel = UILabel()
    private let idLabel = UILabel()
    private let nameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        
        deptLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        idLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        stackView.addArrangedSubview(deptLabel)
        stackView.addArrangedSubview(idLabel)
        stackView.addArrangedSubview(nameLabel)
        
        contentView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with classItem: Class) {
        
        let components = classItem.name.split(separator: " ")
        let dept: String = String(components[0])
        let id: String = String(components[1])
        let name: String = String(components.dropFirst(2).joined(separator: " "))
        
        deptLabel.text = "Department: \(dept)"
        idLabel.text = "ID: \(id)"
        nameLabel.text = name
    }
}

// MARK: - Data Models

struct Class: Codable {
    let class_id: Int // Needs to be sent to backend to view unique posts to classes
    let name: String
}

struct ClassSpecification {
    let dept: String
    let id: String
    let name: String
}

public struct AddUserToClassSpecification {
    let token: String?
    let designation: String?
    let dept: String?
    let id: String?
    let name: String?
}

public struct AddClassResponse: Codable {
    let username: String?
    let addedclass: String?
    let valid: Bool
    let errormsg: String?
}

struct LoadClassesResponse: Codable {
    let username: String?
    let classes: [Class]?
    let valid: Bool
    let errormsg: String?
}

struct SearchClassesResponse: Codable {
    let classes: [String]?
}

// MARK: - APIManager

class APIManager {
    static let shared = APIManager()
    
    private init() {}
    
    func addClass(specification: AddUserToClassSpecification, completion: @escaping (AddClassResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/classes/add")!
        
        // Build URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Expected PyDantic Model:
        // AddUserToClassSpecification
        /* struct AddUserToClassSpecification {
         let token: String?
         let designation: String?
         let dept: String?
         let id: String?
         let name: String?
         }  */
        
        // Take parameters -> Convert into JSON -> Put into request.
        // do/catch block for potential JSONSerialization fail
        do {
            let parameters = ["token": specification.token, "designation": specification.designation, "dept": specification.dept, "id": specification.id, "name": specification.name] // Create dictionary according to User
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
                print("TestError1: \(error.localizedDescription)")
                return
            }
            
            // Handle response if data (response) exist
            if let data = data {
                let rawResponse = String(data: data, encoding: .utf8) // Testing purposes
                print("Raw Response: \(rawResponse ?? "No response")")
                // Parse JSON response into expected response (AddClassResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(AddClassResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    
    }
    
    func loadClasses(token: String, completion: @escaping (LoadClassesResponse?) -> Void) {
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/classes")!
        
        // Build URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Expected PyDantic Model:
        // UserToken:
        //      token: str
        
        request.setValue(token, forHTTPHeaderField: "token-header") // Tells server data is in token-header field
        
        // Build URLSession
        let task = URLSession.shared.dataTask(with: request) { data, response, error in // Create shared session w/ dataTask(request)
            // Check for errors
            if let error = error {
                print("TestError1: \(error.localizedDescription)")
                return
            }
            
            // Handle response if data (response) exist
            if let data = data {
                let rawResponse = String(data: data, encoding: .utf8) // Testing purposes
                print("Raw Response: \(rawResponse ?? "No response")")
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(LoadClassesResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func searchClasses(specification: ClassSpecification, completion: @escaping (SearchClassesResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/classes/filter")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set header info
        request.setValue(specification.dept, forHTTPHeaderField: "dept-header")
        request.setValue(specification.id, forHTTPHeaderField: "id-header")
        request.setValue(specification.name, forHTTPHeaderField: "name-header")
        
        // Build URLSession
        let task = URLSession.shared.dataTask(with: request) { data, response, error in // Create shared session w/ dataTask(request)
            // Check for errors
            if let error = error {
                print("TestError1: \(error.localizedDescription)")
                return
            }
            
            // Handle response if data (response) exist
            if let data = data {
                let rawResponse = String(data: data, encoding: .utf8) // Testing purposes
                print("Raw Response: \(rawResponse ?? "No response")")
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(SearchClassesResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
}

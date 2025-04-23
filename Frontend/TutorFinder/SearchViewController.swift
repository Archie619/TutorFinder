//
//  SearchViewController.swift
//  TutorFinder
//
//  Created by Evan Oberneder on 4/8/25.
//

import UIKit

class SearchViewController: UIViewController {
    
    // UI
    private let tableView = UITableView()
    
    // Variables
    private var classes: [String] = []
    private var userToken: String
    
    // Init
    init(token: String = UserDefaults.standard.string(forKey: "userToken") ?? "No token found") {
        self.userToken = token
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        tableView.reloadData()
    }
    
    private func setupUI() {
        
        view.backgroundColor = .systemBackground
        self.title = "Search Results"
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ClassTableViewCell.self, forCellReuseIdentifier: ClassTableViewCell.identifier)
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "searchTableView"
        view.addSubview(tableView)

    }
    
    private func setupConstraints() {
        
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        
        ])
        
    }
    
    func setClasses(classes: [String]) {
        self.classes = classes
    }
    
    private func showAddClassDialog(dept: String, id: String, name: String) {
        let alert = UIAlertController(title: "Add Class", message: "\n\n\n", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = dept
        }
        
        alert.addTextField { textField in
            textField.text = id
        }
        
        alert.addTextField { textField in
            textField.text = name
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
                    if response?.valid == true {
                        self.showAlert(message: "Class added successfully!")
                        self.navigationController?.popViewController(animated: true) // Close current view, return to main screen
                    } else if response?.errormsg == "user already in class" {
                        self.showAlert(message: "Class is already added!")
                    } else {
                        self.showAlert(message: "Failed to add class")
                    }
                }
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        addAction.accessibilityIdentifier = "addSearchedClassActionButton"
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClassTableViewCell.identifier, for: indexPath) as! ClassTableViewCell
        cell.accessibilityIdentifier = "searchTableViewCell"
        cell.textLabel?.text = classes[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let className = classes[indexPath.row]
        let components = className.split(separator: " ")
        let dept: String = String(components[0])
        let id: String = String(components[1])
        let name: String = String(components.dropFirst(2).joined(separator: " "))
        
        showAddClassDialog(dept: dept, id: id, name: name)
            
    }
}

class SearchTableViewCell: UITableViewCell {

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
        nameLabel.text = classItem.name
    }
}

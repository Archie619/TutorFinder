//
//  ProfileViewController.swift
//  TutorFinder
//

import UIKit

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private var userToken: String
    private var username: String 

    // MARK: - UI Components
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    // Removed emailLabel
    private let ratingButton = UIButton(type: .system)
    private let subjectsButton = UIButton(type: .system)
    private let availabilityButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    // MARK: - Initialization
    init(token: String) {
        self.userToken = token
        self.username = UserDefaults.standard.string(forKey: "username") ?? "Unknown"
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadProfileData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Profile"

        // Edit Button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editProfileTapped))
        
        // Profile Picture
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = UIColor.systemPurple
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        profileImageView.addGestureRecognizer(tapGesture)
        view.addSubview(profileImageView)

        // Name Label
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        view.addSubview(nameLabel)

        // Rating Button
        ratingButton.setTitle("⭐ 4.8 / 5.0", for: .normal)
        ratingButton.setTitleColor(.white, for: .normal)
        ratingButton.backgroundColor = UIColor.systemPurple
        ratingButton.layer.cornerRadius = 8
        view.addSubview(ratingButton)

        // Subjects
        subjectsButton.setTitle("Subjects: Math, Physics, Programming", for: .normal)
        subjectsButton.setTitleColor(.label, for: .normal)
        subjectsButton.addTarget(self, action: #selector(editSubjects), for: .touchUpInside)
        view.addSubview(subjectsButton)

        // Availability
        availabilityButton.setTitle("Availability: Weekdays 4 PM - 8 PM", for: .normal)
        availabilityButton.setTitleColor(.label, for: .normal)
        availabilityButton.addTarget(self, action: #selector(editAvailability), for: .touchUpInside)
        view.addSubview(availabilityButton)

        // Logout Button
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.tintColor = .white
        logoutButton.layer.cornerRadius = 8
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
    }

    private func setupConstraints() {
        [profileImageView, nameLabel, ratingButton, subjectsButton, availabilityButton, logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            ratingButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            ratingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ratingButton.widthAnchor.constraint(equalToConstant: 150),
            ratingButton.heightAnchor.constraint(equalToConstant: 40),

            subjectsButton.topAnchor.constraint(equalTo: ratingButton.bottomAnchor, constant: 20),
            subjectsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            availabilityButton.topAnchor.constraint(equalTo: subjectsButton.bottomAnchor, constant: 10),
            availabilityButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            logoutButton.topAnchor.constraint(equalTo: availabilityButton.bottomAnchor, constant: 30),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 200),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Data Loading
    private func loadProfileData() {
        // Set dummy profile data (no email)
        nameLabel.text = username
    }
    
    // MARK: - Actions
    @objc private func logoutButtonTapped() {
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "username")
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func didTapProfileImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
        }
        dismiss(animated: true)
    }

    @objc private func editProfileTapped() {
        let alert = UIAlertController(title: "Edit Name", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.nameLabel.text
        }
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text {
                self.nameLabel.text = newName
            }
        }
        alert.addAction(save)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func editSubjects() {
        let alert = UIAlertController(title: "Edit Subjects", message: "Comma separated", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.subjectsButton.title(for: .normal)?.replacingOccurrences(of: "Subjects: ", with: "")
        }
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text {
                self.subjectsButton.setTitle("Subjects: \(text)", for: .normal)
            }
        }
        alert.addAction(save)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func editAvailability() {
        let alert = UIAlertController(title: "Edit Availability", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.availabilityButton.title(for: .normal)?.replacingOccurrences(of: "Availability: ", with: "")
        }
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text {
                self.availabilityButton.setTitle("Availability: \(text)", for: .normal)
            }
        }
        alert.addAction(save)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

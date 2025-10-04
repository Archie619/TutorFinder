import UIKit

final class ProfileViewController: UIViewController,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,
                                   UITabBarDelegate {

    // MARK: - Properties (mock / state)
    private var userToken: String
    private var username: String

    // MARK: - UI
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bottomNavBar = UITabBar()

    private let ratingButton = UIButton(type: .system)
    private let subjectsButton = UIButton(type: .system)
    private let availabilityButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    // MARK: - Init
    /// Use this init when you have a token; for now you can pass an empty string (“”)
    init(token: String) {
        self.userToken = token
        // Mock username until backend connects
        self.username = UserDefaults.standard.string(forKey: "username") ?? "Demo User"
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Profile",
                                  image: UIImage(systemName: "person.circle"),
                                  tag: 2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Profile"

        configureUI()
        layoutUI()
        applyMockData()
    }

    // MARK: - UI Setup
    private func configureUI() {
        // Avatar
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 48
        profileImageView.backgroundColor = .secondarySystemBackground
        profileImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeAvatarTapped))
        profileImageView.addGestureRecognizer(tap)

        // Name
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label

        // Buttons
        configurePrimaryButton(ratingButton, title: "Rating", action: #selector(ratingTapped))
        configurePrimaryButton(subjectsButton, title: "Subjects", action: #selector(subjectsTapped))
        configurePrimaryButton(availabilityButton, title: "Availability", action: #selector(availabilityTapped))
        configureDestructiveButton(logoutButton, title: "Logout", action: #selector(logoutTapped))

        // Bottom Tab Bar (local nav)
        let classesTab = UITabBarItem(title: "Classes", image: UIImage(systemName: "book"), tag: 0)
        let messagesTab = UITabBarItem(title: "Messages", image: UIImage(systemName: "message.fill"), tag: 1)
        let profileTab = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 2)

        bottomNavBar.items = [classesTab, messagesTab, profileTab]
        bottomNavBar.selectedItem = profileTab
        bottomNavBar.delegate = self
    }

    private func configurePrimaryButton(_ button: UIButton, title: String, action: Selector) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureDestructiveButton(_ button: UIButton, title: String, action: Selector) {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .systemRed
        config.cornerStyle = .large
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func layoutUI() {
        [profileImageView, nameLabel,
         ratingButton, subjectsButton, availabilityButton, logoutButton,
         bottomNavBar].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 96),
            profileImageView.heightAnchor.constraint(equalToConstant: 96),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            ratingButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            ratingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            ratingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            ratingButton.heightAnchor.constraint(equalToConstant: 48),

            subjectsButton.topAnchor.constraint(equalTo: ratingButton.bottomAnchor, constant: 12),
            subjectsButton.leadingAnchor.constraint(equalTo: ratingButton.leadingAnchor),
            subjectsButton.trailingAnchor.constraint(equalTo: ratingButton.trailingAnchor),
            subjectsButton.heightAnchor.constraint(equalTo: ratingButton.heightAnchor),

            availabilityButton.topAnchor.constraint(equalTo: subjectsButton.bottomAnchor, constant: 12),
            availabilityButton.leadingAnchor.constraint(equalTo: ratingButton.leadingAnchor),
            availabilityButton.trailingAnchor.constraint(equalTo: ratingButton.trailingAnchor),
            availabilityButton.heightAnchor.constraint(equalTo: ratingButton.heightAnchor),

            logoutButton.topAnchor.constraint(equalTo: availabilityButton.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: ratingButton.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: ratingButton.trailingAnchor),
            logoutButton.heightAnchor.constraint(equalTo: ratingButton.heightAnchor),

            bottomNavBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomNavBar.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func applyMockData() {
        // name
        nameLabel.text = username

        // placeholder avatar
        let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .regular)
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")?.applyingSymbolConfiguration(config)
        profileImageView.tintColor = .tertiaryLabel
        profileImageView.backgroundColor = .clear
    }

    // MARK: - Actions
    @objc private func changeAvatarTapped() {
        // open photo picker (mock)
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @objc private func ratingTapped() {
        // TODO: replace with real screen; for now just show a message
        showToast("Rating tapped")
    }

    @objc private func subjectsTapped() {
        showToast("Subjects tapped")
    }

    @objc private func availabilityTapped() {
        showToast("Availability tapped")
    }

    @objc private func logoutTapped() {
        // TODO: hook to backend logout later
        showToast("Logged out (mock)")
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            profileImageView.image = image
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    // MARK: - UITabBarDelegate (local nav)
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Hook these to your app’s real navigation later
        switch item.tag {
        case 0: showToast("Switch to Classes")
        case 1: showToast("Switch to Messages")
        case 2: break // already here
        default: break
        }
    }

    // MARK: - Helpers
    private func showToast(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            alert.dismiss(animated: true)
        }
    }
}
@objc private func ratingTapped() {
    let vc = RatingViewController()
    navigationController?.pushViewController(vc, animated: true)
}

@objc private func subjectsTapped() {
    let vc = SubjectsViewController()
    navigationController?.pushViewController(vc, animated: true)
}

@objc private func availabilityTapped() {
    let vc = AvailabilityViewController()
    navigationController?.pushViewController(vc, animated: true)
}

@objc private func logoutTapped() {
    // TODO: Replace with backend logout later
    let alert = UIAlertController(title: "Logout", message: "Logout tapped", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
}
ratingButton.addTarget(self, action: #selector(ratingTapped), for: .touchUpInside)
subjectsButton.addTarget(self, action: #selector(subjectsTapped), for: .touchUpInside)
availabilityButton.addTarget(self, action: #selector(availabilityTapped), for: .touchUpInside)
logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

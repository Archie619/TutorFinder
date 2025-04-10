// PostViewController.swift
// TutorFinder

import UIKit

struct PostSpecification: Codable {
    let token: String
    let post_id: Int
    let rating: Float?
    let search_username: String?
}

struct PostDetails: Codable {
    let pfp: String?
    let name: String?
    let rating: Float?
    let post_type: String?
    let desc: String?
    let joined: Bool?
    let valid: Bool
    let errormsg: String?
}

struct ConfirmationResponse: Codable {
    let valid: Bool
    let errormsg: String?
}

class PostViewController: UIViewController {

    var postId: Int = 0
    var token: String = ""
    var className: String = ""

    private var postDetails: PostDetails?

    private let descriptionLabel = UILabel()
    private let joinButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = className
        setupUI()
        loadPost()
    }

    private func setupUI() {
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        joinButton.setTitle("Join Group", for: .normal)
        joinButton.backgroundColor = .systemBlue
        joinButton.tintColor = .white
        joinButton.layer.cornerRadius = 10
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(joinGroup), for: .touchUpInside)

        view.addSubview(descriptionLabel)
        view.addSubview(joinButton)

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            joinButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func loadPost() {
        let spec = PostSpecification(token: token, post_id: postId, rating: nil, search_username: nil)
        guard let url = URL(string: "http://<your-ip>:8000/post") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(spec)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            if let details = try? JSONDecoder().decode(PostDetails.self, from: data), details.valid {
                DispatchQueue.main.async {
                    self.postDetails = details
                    self.descriptionLabel.text = details.desc ?? "No description provided."
                }
            }
        }.resume()
    }

    @objc private func joinGroup() {
        print("Join button tapped — directly navigating to chat")

        let convoVC = ConversationViewController()
        convoVC.conversationId = self.postId
        convoVC.token = self.token
        convoVC.className = self.className
        convoVC.postOwnerName = self.postDetails?.name ?? "Group"

        self.navigationController?.pushViewController(convoVC, animated: true)
    }

}

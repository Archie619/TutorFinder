// PostViewController.swift
// TutorFinder

import UIKit

class PostViewController: UIViewController {
    
    // Token
    private let userToken: String

    // Post
    private let selectedPost: PostDetails
    
    // UI
    private let descriptionLabel = UILabel()
    private let profileImage = UIImageView()
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let post_type = UILabel()

    private let joinButton = UIButton(type: .system)
    
    // MARK: - Init
    init(post: PostDetails) {
        self.selectedPost = post
        userToken = UserDefaults.standard.string(forKey: "userToken") ?? "No token found"
        super.init(nibName: nil, bundle: nil)
        if let name = post.name {
            self.title = "\(name)'s Group"
        } else {
            self.title = "Group"
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadPostDetails()
    }

    private func setupUI() {
        
        profileImage.contentMode = .scaleAspectFill
        profileImage.layer.cornerRadius = 30
        profileImage.clipsToBounds = true
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        post_type.font = UIFont.italicSystemFont(ofSize: 14)
        post_type.textColor = .systemGray
        post_type.translatesAutoresizingMaskIntoConstraints = false
            
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
            
        view.addSubview(profileImage)
        view.addSubview(nameLabel)
        view.addSubview(ratingLabel)
        view.addSubview(post_type)
        view.addSubview(descriptionLabel)
        view.addSubview(joinButton)

        let stackView = UIStackView(arrangedSubviews: [nameLabel, post_type, ratingLabel, descriptionLabel, joinButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileImage.widthAnchor.constraint(equalToConstant: 100),
            profileImage.heightAnchor.constraint(equalToConstant: 100),
            
            stackView.topAnchor.constraint(equalTo: profileImage.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    
            joinButton.heightAnchor.constraint(equalToConstant: 50),
            joinButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func loadPostDetails() {
        descriptionLabel.text = selectedPost.desc
        nameLabel.text = selectedPost.name
        post_type.text = selectedPost.post_type
        
        if selectedPost.rating != nil {
            ratingLabel.text = selectedPost.rating.map { String(format: "%.1f", $0) } ?? "N/A"
        } else {
            ratingLabel.text = "Rating: No Rating Yet"
        }
        
        if selectedPost.pfp != nil {
            // Show profile pic
            let url = URL(string: selectedPost.pfp!)
            profileImage.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle"))
        } else {
            // Placeholder pic
            profileImage.image = UIImage(systemName: "person.crop.circle")
        }
        
    }


    @objc private func joinGroup() {
        print("Join button tapped — directly navigating to chat")

        let convoVC = ConversationViewController()
        //convoVC.conversationId = self.postId
        //convoVC.token = self.token
        //convoVC.className = self.className
        //convoVC.postOwnerName = self.postDetails?.name ?? "Group"

        self.navigationController?.pushViewController(convoVC, animated: true)
    }

}

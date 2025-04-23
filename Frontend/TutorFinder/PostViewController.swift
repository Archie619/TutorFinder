// PostViewController.swift
// TutorFinder

import UIKit

class PostViewController: UIViewController {
    
    // Token
    private let userToken: String

    // Post
    private let selectedPost: PostDetails
    private let postID: Int
    
    // UI
    // Messaging
    private let tableView = UITableView() // Contact table for existing messages
    private let postUsersTableView = UITableView() // All users in post (to create group)
    private var contacts: [ConvoPreview] = [] // Contacts (previously messaged groups)
    private let convoTableView = UITableView() // conversation w/ messages
    private var usersInPost: [String] = [] // Users in post
    private var selectedUsers: [String] = [] // Selected users for new group
    private var convo: [[String: String]] = [] // Dictionary of messages
    private var timer: Timer? // Timer for updating messages
    private var currentConvoID: Int = 0
    private var isVisible = false
    private var createMeetingButton = UIButton(type: .system)
    private var loadMeetingButton = UIButton(type: .system)

    private let descriptionLabel = UILabel()
    private let profileImage = UIImageView()
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let post_type = UILabel()
    private let joinButton = UIButton(type: .system)
    private let createRatingButton = UIButton(type: .system)
    private let messageInputContainerView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    // MARK: - Init
    init(post: PostDetails, postID: Int) {
        self.selectedPost = post
        self.postID = postID
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
        isVisible = true
        loadPostDetails()
        
        // Allows user to tap/swipe out of keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
        isVisible = false
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
        
        createRatingButton.setTitle("Create Rating", for: .normal)
        createRatingButton.backgroundColor = .systemGreen
        createRatingButton.tintColor = .white
        createRatingButton.layer.cornerRadius = 10
        createRatingButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        createRatingButton.translatesAutoresizingMaskIntoConstraints = false
        createRatingButton.addTarget(self, action: #selector(showRatingAlert), for: .touchUpInside)
            
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.systemGray6
        tableView.register(ContactsTableViewCell.self, forCellReuseIdentifier: "ContactsTableViewCell")
        
        postUsersTableView.translatesAutoresizingMaskIntoConstraints = false
        postUsersTableView.backgroundColor = UIColor.systemGray6
        postUsersTableView.register(PostUsersTableViewCell.self, forCellReuseIdentifier: "PostUsersTableViewCell")
        
        convoTableView.translatesAutoresizingMaskIntoConstraints = false
        convoTableView.backgroundColor = UIColor.systemGray6
        convoTableView.register(ConvoTableViewCell.self, forCellReuseIdentifier: "ConvoTableViewCell")
        
        messageInputContainerView.backgroundColor = .systemGray6
        messageInputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInputContainerView)

        messageTextField.placeholder = "Type a message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainerView.addSubview(messageTextField)

        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        messageInputContainerView.addSubview(sendButton)
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        let headerLabel = UILabel()
        headerLabel.text = "Messages"
        headerLabel.frame = CGRect(x: 10, y: 10, width: 150, height: 40)
        let addButton = UIButton(type: .system)
        addButton.setTitle("+ Add Contact", for: .normal)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        addButton.tintColor = .systemBlue
        addButton.frame = CGRect(x: 250, y: 10, width: 150, height: 40)
        addButton.addTarget(self, action: #selector(addContactTapped), for: .touchUpInside)

        headerView.addSubview(addButton)
        headerView.addSubview(headerLabel)
        tableView.tableHeaderView = headerView
        
        let headerView2 = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        let headerLabel2 = UILabel()
        headerLabel2.text = "Users in Group:"
        headerLabel2.frame = CGRect(x: 10, y: 10, width: 150, height: 40)
        let createGroupButton = UIButton(type: .system)
        createGroupButton.setTitle("+ Create Group", for: .normal)
        createGroupButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createGroupButton.tintColor = .systemBlue
        createGroupButton.frame = CGRect(x: 250, y: 10, width: 150, height: 40)
        createGroupButton.addTarget(self, action: #selector(createGroupButtonTapped), for: .touchUpInside)
        
        headerView2.addSubview(createGroupButton)
        headerView2.addSubview(headerLabel2)
        postUsersTableView.tableHeaderView = headerView2
        
        let headerView3 = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        let headerLabel3 = UILabel()
        headerLabel3.text = "Messages"
        headerLabel3.frame = CGRect(x: 10, y: 10, width: 150, height: 40)
        let backButton = UIButton(type: .system)
        backButton.setTitle("< Back", for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        backButton.tintColor = .systemBlue
        backButton.frame = CGRect(x: 260, y: 10, width: 150, height: 40)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        createMeetingButton.setTitle("Create Meeting", for: .normal)
        createMeetingButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createMeetingButton.tintColor = .systemOrange
        createMeetingButton.frame = CGRect(x: 100, y: 10, width: 150, height: 40)
        createMeetingButton.addTarget(self, action: #selector(createMeetingButtonTapped), for: .touchUpInside)
        loadMeetingButton.setTitle("Load Meeting", for: .normal)
        loadMeetingButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        loadMeetingButton.tintColor = .systemOrange
        loadMeetingButton.frame = CGRect(x: 100, y: 10, width: 150, height: 40)
        loadMeetingButton.addTarget(self, action: #selector(loadMeetingButtonTapped), for: .touchUpInside)
        
        headerView3.addSubview(createMeetingButton)
        headerView3.addSubview(loadMeetingButton)
        headerView3.addSubview(backButton)
        headerView3.addSubview(headerLabel3)
        convoTableView.tableHeaderView = headerView3
        
        view.addSubview(convoTableView)
        view.addSubview(postUsersTableView)
        view.addSubview(tableView)
        view.addSubview(profileImage)
        view.addSubview(nameLabel)
        view.addSubview(ratingLabel)
        view.addSubview(post_type)
        view.addSubview(descriptionLabel)
        view.addSubview(joinButton)
        view.addSubview(createRatingButton)

        let stackView = UIStackView(arrangedSubviews: [nameLabel, post_type, ratingLabel, descriptionLabel, joinButton, createRatingButton])
        stackView.axis = .vertical
        stackView.spacing = 7
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
            joinButton.widthAnchor.constraint(equalToConstant: 200),
            
            createRatingButton.heightAnchor.constraint(equalToConstant: 30),
            createRatingButton.widthAnchor.constraint(equalToConstant: 150),
            
            tableView.topAnchor.constraint(equalTo: createRatingButton.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            postUsersTableView.topAnchor.constraint(equalTo: createRatingButton.bottomAnchor, constant: 10),
            postUsersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postUsersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            postUsersTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            convoTableView.topAnchor.constraint(equalTo: createRatingButton.bottomAnchor, constant: 10),
            convoTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            convoTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            convoTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            messageInputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputContainerView.heightAnchor.constraint(equalToConstant: 50),

            messageTextField.leadingAnchor.constraint(equalTo: messageInputContainerView.leadingAnchor, constant: 8),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputContainerView.centerYAnchor),
            messageTextField.heightAnchor.constraint(equalToConstant: 36),
            
            sendButton.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: messageInputContainerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
        ])
        
        messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8).isActive = true

    }
    
    func loadPostDetails() {

        tableView.dataSource = self
        tableView.delegate = self
        descriptionLabel.text = selectedPost.desc
        nameLabel.text = selectedPost.name
        post_type.text = selectedPost.post_type
        postUsersTableView.dataSource = self
        postUsersTableView.delegate = self
        postUsersTableView.isHidden = true
        postUsersTableView.tableHeaderView?.isHidden = true
        convoTableView.dataSource = self
        convoTableView.delegate = self
        convoTableView.isHidden = true
        convoTableView.tableHeaderView?.isHidden = true
        messageInputContainerView.isHidden = true
        sendButton.isHidden = true
        messageTextField.isHidden = true
        
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
        
        if selectedPost.joined == true {
            // If in group, load messages & hide join button
            joinButton.isHidden = true
            tableView.isHidden = false
            tableView.tableHeaderView?.isHidden = false
            createRatingButton.isHidden = false
            loadContacts()
            
        } else {
            // If not in group, load join group button
            joinButton.isHidden = false
            tableView.isHidden = true
            tableView.tableHeaderView?.isHidden = true
            createRatingButton.isHidden = true

        }
            
    }
    
    private func loadContacts() {
        
        let specification = PostViewSpecification(token: self.userToken, post_id: self.postID, username_header: nil, rating: nil)
        
        APIManager.shared.loadContacts(specification: specification) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if response?.valid == true {
                    self.contacts = response?.contacts ?? []
                    self.tableView.reloadData()
                } else {
                    self.showAlert(message: "Invalid Token.")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func sendButtonTapped() {
        
        guard let message = messageTextField.text, !message.isEmpty else {
            showAlert(message: "Please type a message!")
            return
        }
        
        let specification = MessageSpecification(token: self.userToken, conversation_id: self.currentConvoID, message: message)
        
        APIManager.shared.sendMessage(specification: specification) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if response?.valid == true {
                    self.messageTextField.text = nil // clear message box
                    self.updateMessages() // update messages after sending one
                } else {
                    self.showAlert(message: "Invalid Token.")
                }
            }
        }
        
    }
    
    @objc private func addContactTapped() {
        
        let specification = PostViewSpecification(token: self.userToken, post_id: self.postID, username_header: nil, rating: nil)
        
        APIManager.shared.searchUsers(specification: specification) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if response?.valid == true {
                    self.usersInPost = response?.users ?? []
                    self.postUsersTableView.reloadData()
                    
                    // Display postUsersTableView, hide tableView
                    self.postUsersTableView.isHidden = false
                    self.postUsersTableView.tableHeaderView?.isHidden = false
                    self.tableView.isHidden = true
                    self.tableView.tableHeaderView?.isHidden = true
                    
                } else {
                    self.showAlert(message: "Invalid Token.")
                }
            }
        }
        
    }
    
    func startTimer(convoID: Int) {
        timer?.invalidate() // Stop old timer
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(updateMessages), userInfo: nil, repeats: true)
    }
    
    @objc func updateMessages() {
        if (convoTableView.isHidden == false && isVisible) {
            // Load messages from convo id:
            APIManager.shared.loadConvo(convo_header: currentConvoID) { [weak self] response in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let convo = response?.convo {
                        self.convo = convo
                        self.convoTableView.reloadData()
                        print("Updated Messages")
                    }
                }
            }
        }
        
    }
    
    @objc private func backButtonTapped() {
        
        timer?.invalidate()
        timer = nil
        convoTableView.isHidden = true
        convoTableView.tableHeaderView?.isHidden = true
        tableView.reloadData()
        tableView.isHidden = false
        tableView.tableHeaderView?.isHidden = false
        messageInputContainerView.isHidden = true
        messageTextField.isHidden = true
        sendButton.isHidden = true
        loadContacts()
        
    }
    
    @objc private func createMeetingButtonTapped() {
        
        let specification = ConversationSpecification(conversation_id: currentConvoID)
        
        APIManager.shared.createMeeting(specification: specification) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if response?.meeting_link != nil {
                    self.showAlert(message: "Created meeting successfully!")
                    // Hide create meeting button
                    self.createMeetingButton.isHidden = true
                    // Show load meeting link button now
                    self.loadMeetingButton.isHidden = false
                    
                } else {
                    self.showAlert(message: "Error creating meeting.")
                }
            }
        }
        
    }
    
    @objc private func checkIfMeetingExists() {
        
        APIManager.shared.loadMeeting(convo_header: currentConvoID) { [weak self] response in
            guard let self = self else { return }
            print("trying to check if meeting exists")
                        
            DispatchQueue.main.async {
                if let meeting_link = response?.meeting_link, !meeting_link.isEmpty {
                    print("showing load meeting button")
                    self.loadMeetingButton.isHidden = false
                    self.createMeetingButton.isHidden = true
                } else {
                    print("showing create meeting button")
                    self.loadMeetingButton.isHidden = true
                    self.createMeetingButton.isHidden = false
                }
            }
        }
        
    }
    
    @objc private func loadMeetingButtonTapped() {
        
        APIManager.shared.loadMeeting(convo_header: currentConvoID) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if let meeting_link = response?.meeting_link {
                    // if option is true, open browser with link
                    if let url = URL(string: meeting_link) {
                        UIApplication.shared.open(url)
                    }
                    
                } else {
                    self.showAlert(message: "Error loading meeting.")
                }
            }
        }
        
    }
    
    @objc private func createGroupButtonTapped() {
        if (selectedUsers.count == 0) {
            showAlert(message: "Must select at least 1 user!")
            return
        } else {
            let specification = AddConversationSpecification(token: self.userToken, convo_partners: selectedUsers, post_id: postID)
            
            APIManager.shared.addConvo(specification: specification) { [weak self] response in
                guard let self = self else { return }
                            
                DispatchQueue.main.async {
                    if response?.valid == true {
                        // Display postUsersTableView, hide tableView
                        self.postUsersTableView.isHidden = true
                        self.postUsersTableView.tableHeaderView?.isHidden = true
                        // Go to messages table view for new group
                        if let convoID = response?.conversation_id {
                            self.goToConvo(convoID: convoID)
                        }
                    } else {
                        self.showAlert(message: "Invalid Token.")
                    }
                }
            }
        }
    }

    @objc private func joinGroup() {
        
        let specification = PostViewSpecification (token: self.userToken, post_id: postID, username_header: nil, rating: nil)
        
        APIManager.shared.joinPost(specification: specification) { [weak self] response in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if response?.valid == true {
                    self.showAlert(message: "Joined group successfully!")
                    self.joinButton.isHidden = true
                    self.createRatingButton.isHidden = false
                    self.tableView.isHidden = false
                    self.tableView.tableHeaderView?.isHidden = false
                } else {
                    self.showAlert(message: "Failed to join group.")
                }
            }
        }
        
    }
    
    @objc private func showRatingAlert() {
        let alert = UIAlertController(title: "Create rating", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Rating: 0.0 - 5.0"
        }

        let addAction = UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let self = self,
                  let rating = alert.textFields?[0].text else { return }
            
            self.createRating(with: PostViewSpecification(token: userToken, post_id: postID, username_header: nil, rating: (rating as NSString).floatValue))
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func createRating(with specification: PostViewSpecification) {
                
        APIManager.shared.createRating(specification: specification) { [weak self] response in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if response?.valid == true {
                    self.showAlert(message: "Rating created successfully!")
                } else {
                    self.showAlert(message: "Failed to join group.")
                }
            }
        }
        
    }
    
    // Goes to actual convo messages
    private func goToConvo(convoID: Int) {
        
        // Load messages from convo id:
        APIManager.shared.loadConvo(convo_header: convoID) { [weak self] response in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let convo = response?.convo {
                    self.convo = convo
                    self.convoTableView.reloadData()
                    self.startTimer(convoID: convoID)
                    self.currentConvoID = convoID
                    print(convo)
                } else {
                    self.showAlert(message: "Failed to load messages.")
                }
            }
        }
        
        createMeetingButton.isHidden = true
        loadMeetingButton.isHidden = true
        checkIfMeetingExists()
        tableView.isHidden = true
        tableView.tableHeaderView?.isHidden = true
        postUsersTableView.isHidden = true
        postUsersTableView.tableHeaderView?.isHidden = true
        convoTableView.isHidden = false
        convoTableView.tableFooterView?.isHidden = false
        convoTableView.tableHeaderView?.isHidden = false
        messageInputContainerView.isHidden = false
        messageTextField.isHidden = false
        sendButton.isHidden = false
        view.bringSubviewToFront(messageInputContainerView)
        view.layoutIfNeeded()
        
    }

}

extension PostViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return contacts.count
        } else if tableView == self.postUsersTableView {
            return usersInPost.count
        } else if tableView == self.convoTableView {
            return convo.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.identifier, for: indexPath) as! ContactsTableViewCell
            cell.configure(with: contacts[indexPath.row])
            return cell
        } else if tableView == self.postUsersTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: PostUsersTableViewCell.identifier, for: indexPath) as! PostUsersTableViewCell
            cell.selectionStyle = .none
            cell.configure(with: usersInPost[indexPath.row])
            return cell
        } else if tableView == self.convoTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConvoTableViewCell.identifier, for: indexPath) as! ConvoTableViewCell
            cell.selectionStyle = .none
            let message = convo[indexPath.row]
            cell.configure(with: message)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            let convo_id = contacts[indexPath.row].conversation_id
            let users = contacts[indexPath.row].names
            goToConvo(convoID: convo_id)
            self.currentConvoID = convo_id
            checkIfMeetingExists()
        } else if tableView == self.postUsersTableView {
            let cell = tableView.cellForRow(at: indexPath)
            if (!selectedUsers.contains(usersInPost[indexPath.row])) { // If user not selected, add it
                selectedUsers.append(usersInPost[indexPath.row])
                cell?.backgroundColor = UIColor.systemMint
            } else {
                if let index = selectedUsers.firstIndex(of: usersInPost[indexPath.row]) { // If user already was, remove it
                    selectedUsers.remove(at: index)
                    cell?.backgroundColor = UIColor.clear
                }
            }
        }
        
    }
    
    class ContactsTableViewCell: UITableViewCell {
        static let identifier = "ContactsTableViewCell"
        let profileImageStack = UIStackView()
        private let namesLabel = UILabel()
        private let horizontalStack = UIStackView()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
            horizontalStack.axis = .horizontal
            horizontalStack.spacing = 12
            horizontalStack.alignment = .center
            horizontalStack.translatesAutoresizingMaskIntoConstraints = false
            
            profileImageStack.axis = .horizontal
            profileImageStack.spacing = -15
            profileImageStack.alignment = .center
            profileImageStack.translatesAutoresizingMaskIntoConstraints = false
            
            namesLabel.font = UIFont.systemFont(ofSize: 16)
            namesLabel.textColor = .black
            namesLabel.numberOfLines = 1
            namesLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            namesLabel.translatesAutoresizingMaskIntoConstraints = false
            
            horizontalStack.addArrangedSubview(profileImageStack)
            horizontalStack.addArrangedSubview(namesLabel)
            
            contentView.addSubview(horizontalStack)
            
            NSLayoutConstraint.activate([
                horizontalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                horizontalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                horizontalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                horizontalStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
                
                profileImageStack.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
            ])
        }
        
        func configure(with convoPreview: ConvoPreview) {
            // clear existing image
            profileImageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            // add new image views for each profile picture
            for pfp in convoPreview.pfps {
                let imageView = UIImageView()
                imageView.layer.cornerRadius = 15
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
                imageView.widthAnchor.constraint(equalToConstant: 45).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
                
                // If they have a pfp use it, else use placeholder
                if let urlString = pfp, let url = URL(string: urlString) {
                    imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle"))
                } else {
                    imageView.image = UIImage(systemName: "person.crop.circle")
                }
                
                profileImageStack.addArrangedSubview(imageView)
            }
            
            // set names
            namesLabel.text = convoPreview.names.joined(separator: ", ")
        }
    }
    
    
    class PostUsersTableViewCell: UITableViewCell {
        static let identifier = "PostUsersTableViewCell"
        private let nameLabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
            
            nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(nameLabel)
            
            NSLayoutConstraint.activate([
                nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        }
        
        func configure(with userItem: String) {
            nameLabel.text = userItem
        }
    }
    
    class ConvoTableViewCell: UITableViewCell {
        static let identifier = "ConvoTableViewCell"

        private let nameLabel = UILabel()
        private let messageLabel = UILabel()

        private var leadingConstraints: [NSLayoutConstraint] = []
        private var trailingConstraints: [NSLayoutConstraint] = []
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI() {
            nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
            messageLabel.font = UIFont.systemFont(ofSize: 16)
            messageLabel.numberOfLines = 0

            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(nameLabel)
            contentView.addSubview(messageLabel)
            
            leadingConstraints = [
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -100),
                messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -100)
            ]
            
            trailingConstraints = [
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 100),
                messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 100)
            ]

            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ])
        }

        func configure(with messageDict: [String: String]) {
            let isCurrentUser = messageDict["User"] == UserDefaults.standard.string(forKey: "username")
            nameLabel.text = messageDict["User"]
            messageLabel.text = messageDict["Message"]
            
            NSLayoutConstraint.deactivate(leadingConstraints + trailingConstraints)
            if isCurrentUser {
                NSLayoutConstraint.activate(trailingConstraints)
                nameLabel.textAlignment = .right
                messageLabel.textAlignment = .right
            } else {
                NSLayoutConstraint.activate(leadingConstraints)
                nameLabel.textAlignment = .left
                messageLabel.textAlignment = .left
            }

            messageLabel.layer.cornerRadius = 8
            messageLabel.layer.masksToBounds = true
        }
    }

    
}

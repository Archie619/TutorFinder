import UIKit

struct PostItem {
    let postId: Int
    let posterName: String
    let role: String // "Tutor" or "Study Buddy"
    let description: String
}

class ClassPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let selectedClass: Class
    private var posts: [PostItem] = []
    private var expandedIndex: Int? = nil

    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)

    // MARK: - Init
    init(classItem: Class) {
        self.selectedClass = classItem
        super.init(nibName: nil, bundle: nil)
        self.title = classItem.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupAddButton()
        loadDummyPosts()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCell.self, forCellReuseIdentifier: "postCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }

    private func setupAddButton() {
        addButton.setTitle("Add Post", for: .normal)
        addButton.backgroundColor = .systemPurple
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 25
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 4
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addPostTapped), for: .touchUpInside)

        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 150),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    @objc private func addPostTapped() {
        let alert = UIAlertController(title: "New Post", message: "Enter a description for your group.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Description" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Post", style: .default) { [weak self] _ in
            guard let self = self,
                  let desc = alert.textFields?.first?.text, !desc.isEmpty else { return }

            let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "Student"
            let role = userRole.lowercased() == "tutor" ? "Tutor" : "Study Buddy"

            let newPost = PostItem(postId: self.posts.count + 1,
                                   posterName: "You",
                                   role: role,
                                   description: desc)
            self.posts.append(newPost)
            self.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func loadDummyPosts() {
        posts = [
            PostItem(postId: 1, posterName: "Alice", role: "Tutor", description: "Available M/W/F 5-7pm, good with projects."),
            PostItem(postId: 2, posterName: "Bob", role: "Study Buddy", description: "Looking to meet weekly to review chapters."),
        ]
        tableView.reloadData()
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
        let isExpanded = expandedIndex == indexPath.row
        cell.configure(with: post, expanded: isExpanded)
        cell.joinButtonAction = { [weak self] in
            guard let self = self else { return }

            let postVC = PostViewController()
            postVC.postId = post.postId
            postVC.token = UserDefaults.standard.string(forKey: "userToken") ?? ""
            postVC.className = self.selectedClass.name

            let nav = UINavigationController(rootViewController: postVC)
            self.present(nav, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        expandedIndex = (expandedIndex == indexPath.row) ? nil : indexPath.row
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - Custom Cell for Posts

class PostCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let joinButton = UIButton(type: .system)
    
    var joinButtonAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 16)
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
        
        joinButton.setTitle("Join Group", for: .normal)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.backgroundColor = .systemBlue
        joinButton.layer.cornerRadius = 8
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        
        [titleLabel, descriptionLabel, joinButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            joinButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            joinButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            joinButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with post: PostItem, expanded: Bool) {
        titleLabel.text = "\(post.role) Post - \(post.posterName)"
        descriptionLabel.text = expanded ? post.description : ""
        joinButton.isHidden = !expanded
    }
    
    @objc private func joinTapped() {
        joinButtonAction?()
    }
}

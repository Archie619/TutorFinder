import UIKit
import SDWebImage

class ClassPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let selectedClass: Class
    private var posts: [PostPreview] = []
    private var expandedIndex: Int? = nil

    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    private var userToken: String

    // MARK: - Init
    init(classItem: Class) {
        self.selectedClass = classItem
        userToken = UserDefaults.standard.string(forKey: "userToken") ?? "No token found"
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
        loadClass()
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

            let specification = PostSpecification(
                token: userToken,
                class_id: selectedClass.class_id,
                post_description: desc
            )
            
            APIManager.shared.createPost(specification: specification) { [weak self] response in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if response?.valid == true {
                        self.showAlert(message: "Post added successfully!")
                        self.loadClass()
                    } else {
                        self.showAlert(message: "Failed to add post")
                    }
                }
            }
            
        })

        present(alert, animated: true)
    }

    private func loadClass() {
        APIManager.shared.loadClass(specification: selectedClass) { [weak self] response in
            guard let self = self else { return }
                        
            DispatchQueue.main.async {
                if let newPosts = response?.posts {
                    self.posts = newPosts
                    self.tableView.reloadData()
                } else {
                    self.showAlert(message: "No posts")
                    return
                }
            }
        }
        
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
            
            let specification = PostViewSpecification (token: userToken, post_id: post.post_id)
            APIManager.shared.loadPost(specification: specification) { [weak self] response in
            guard let self = self else { return }
                            
                DispatchQueue.main.async {
                    if let response = response, response.valid != false {
                        let post = PostDetails (pfp: response.pfp, name: response.name, rating: response.rating, post_type: response.post_type, desc: response.desc, joined: response.joined, valid: response.valid, errormsg: response.errormsg)
                        let postVC = PostViewController(post: post)
                        let nav = UINavigationController(rootViewController: postVC)
                        self.present(nav, animated: true)
                    } else {
                        self.showAlert(message: "Error retrieving post.")
                        return
                    }
                }
            }
            
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        expandedIndex = (expandedIndex == indexPath.row) ? nil : indexPath.row
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

// MARK: - Custom Cell for Posts

class PostCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let joinButton = UIButton(type: .system)
    private let profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()
    
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
        
        joinButton.setTitle("Go to Group", for: .normal)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.backgroundColor = .systemBlue
        joinButton.layer.cornerRadius = 8
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        
        [titleLabel, descriptionLabel, joinButton, profileImage].forEach {
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
            joinButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            profileImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalToConstant: 70)
            
        ])
    }
    
    func configure(with post: PostPreview, expanded: Bool) {
        
        titleLabel.text = "\(post.post_type) Post - \(post.name)"
        if post.rating != nil {
            descriptionLabel.text = post.rating.map { String(format: "%.1f", $0) } ?? "N/A"
        } else {
            descriptionLabel.text = "Rating: No Rating Yet"
        }
        
        if post.pfp != nil {
            // Show profile pic
            let url = URL(string: post.pfp!)
            profileImage.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle"))
        } else {
            // Placeholder pic
            profileImage.image = UIImage(systemName: "person.crop.circle")
        }
        
    }
    
    @objc private func joinTapped() {
        joinButtonAction?()
    }
}

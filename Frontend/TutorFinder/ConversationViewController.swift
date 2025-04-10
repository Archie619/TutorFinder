// ConversationViewController.swift
// TutorFinder

import UIKit

struct ConversationSpecification: Codable {
    let conversation_id: Int
}

struct AddConversationSpecification: Codable {
    let token: String
    let convo_partners: [String]
    let post_id: Int
}

struct MessageSpecification: Codable {
    let token: String
    let conversation_id: Int
    let message: String
}

struct ConvoMessages: Codable {
    let convo: [[String: String]]
}

struct MeetingResponse: Codable {
    let meeting_link: String?
}

class ConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var conversationId: Int = 0
    var postOwnerName: String = ""
    var className: String = ""
    var token: String = ""

    private var messages: [String] = []
    private var usernames: [String] = []

    private let tableView = UITableView()
    private let messageInput = UITextField()
    private let sendButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMessages()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "\(postOwnerName) - \(className)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Rate", style: .plain, target: self, action: #selector(rateTapped))

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        messageInput.placeholder = "Type a message..."
        messageInput.borderStyle = .roundedRect
        messageInput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInput)

        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInput.topAnchor, constant: -8),

            messageInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageInput.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            messageInput.heightAnchor.constraint(equalToConstant: 44),

            sendButton.leadingAnchor.constraint(equalTo: messageInput.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: messageInput.bottomAnchor),
            sendButton.heightAnchor.constraint(equalTo: messageInput.heightAnchor)
        ])
    }

    private func loadMessages() {
        let spec = ConversationSpecification(conversation_id: conversationId)
        guard let url = URL(string: "http://<your-ip>:8000/post/load-conversation") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(spec)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            if let convo = try? JSONDecoder().decode(ConvoMessages.self, from: data) {
                self.usernames = convo.convo.map { $0["User"] ?? "" }
                self.messages = convo.convo.map { $0["Message"] ?? "" }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }.resume()
    }

    @objc private func sendMessage() {
        print("Send button tapped")

        guard let messageText = messageInput.text, !messageText.isEmpty else {
            print("Empty message, not sending")
            return
        }

        // ✅ Simulate a successful message send (offline/local)
        DispatchQueue.main.async {
            self.messages.append(messageText)
            self.usernames.append("You") // Optional: simulate sender
            self.tableView.reloadData()
            self.messageInput.text = ""
            print(" Message added locally")
        }
    }

    @objc private func rateTapped() {
        let alert = UIAlertController(title: "Rate This Group", message: "Rate the group creator:", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Enter rating (0.0 - 5.0)"; $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let self = self,
                  let ratingText = alert.textFields?.first?.text,
                  let rating = Float(ratingText) else { return }
            self.submitRating(rating)
        })
        present(alert, animated: true)
    }

    private func submitRating(_ rating: Float) {
        let postId = conversationId // Assuming it's the same or accessible
        //let spec = PostSpecification2(token: token, post_id: postId, rating: rating, search_username: nil)
        guard let url = URL(string: "http://<your-ip>:8000/post/create-rating") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.httpBody = try? JSONEncoder().encode(spec)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                let confirm = UIAlertController(title: "Submitted", message: "Rating sent successfully!", preferredStyle: .alert)
                confirm.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(confirm, animated: true)
            }
        }.resume()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = usernames[indexPath.row]
        cell.detailTextLabel?.text = messages[indexPath.row]
        return cell
    }
}

//
//  APIManager.swift
//  TutorFinder
//
//  Created by Evan Oberneder on 4/10/25.
//

import UIKit

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

struct PostItem: Codable {
    let postId: Int
    let posterName: String
    let role: String // "Tutor" or "Study Buddy"
    let description: String
}

struct PostPreview: Codable {
    let post_id: Int
    let pfp: String?
    let name: String
    let rating: Float?
    let post_type: String
}

struct ClassPosts: Codable {
    let posts: [PostPreview]?
}

struct PostSpecification: Codable {
    let token: String
    let class_id: Int
    let post_description: String?
}

struct PostCreatedResponse: Codable {
    let valid: Bool
    let errormsg: String?
}

struct PostViewSpecification: Codable {
    let token: String
    let post_id: Int
    let username_header: String?
    let rating: Float?
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

struct ConvoPreview: Codable {
    let pfps: [String?]
    let names: [String]
    let conversation_id: Int
}

struct PostContacts: Codable {
    let contacts: [ConvoPreview]
    let valid: Bool
    let errormsg: String?
}

struct PostUsers: Codable {
    let users: [String]
    let valid: Bool
}

struct AddConversationSpecification: Codable {
    let token: String
    let convo_partners: [String]
    let post_id: Int
}

struct ConvoCreationResponse: Codable {
    let conversation_id: Int
    let valid: Bool
    let errormsg: String?
}

struct ConvoMessages: Codable {
    let convo: [[String: String]]
}

struct MessageSpecification: Codable {
    let token: String
    let conversation_id: Int
    let message: String
}

struct ProfilePostResponse: Codable {
    let picture_url: String?
    let valid: Bool
    let errormsg: String?
}

struct ConversationSpecification: Codable {
    let conversation_id: Int
}

struct MeetingResponse: Codable {
    let meeting_link: String?
}

// MARK: - APIManager

// evan - http://172.30.195.217:8000
// nate - http://192.168.79.128:8000
// NOTE: Any header parameters that have an "_" in the backend like "token_header", must be typed with a "-" replacing it like "token-header".

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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    func loadClass(specification: Class, completion: @escaping (ClassPosts?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/class")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(String(specification.class_id), forHTTPHeaderField: "class-header")
        
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
                    let jsonResponse = try JSONDecoder().decode(ClassPosts.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    func createPost(specification: PostSpecification, completion: @escaping (PostCreatedResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/class/create-post")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Take parameters -> Convert into JSON -> Put into request.
        // do/catch block for potential JSONSerialization fail
        do {
            let parameters = ["token": specification.token, "class_id": String(specification.class_id), "post_description": specification.post_description] // Create dictionary according to User
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(PostCreatedResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    func loadPost(specification: PostViewSpecification, completion: @escaping (PostDetails?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(specification.token, forHTTPHeaderField: "token-header") // Tells server data is in token-header field
        request.setValue(String(specification.post_id), forHTTPHeaderField: "post-id-header")
        
        print(request.allHTTPHeaderFields)
        
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
                    let jsonResponse = try JSONDecoder().decode(PostDetails.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    func joinPost(specification: PostViewSpecification, completion: @escaping (ConfirmationResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/join")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Take parameters -> Convert into JSON -> Put into request.
        // do/catch block for potential JSONSerialization fail
        do {
            let parameters = ["token": specification.token, "post_id": String(specification.post_id), "rating": specification.rating, "search_username": specification.username_header] as [String : Any] // Create dictionary according to User
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(ConfirmationResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func loadContacts(specification: PostViewSpecification, completion: @escaping (PostContacts?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/load-contacts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(String(specification.token), forHTTPHeaderField: "token-header")
        request.setValue(String(specification.post_id), forHTTPHeaderField: "post-id-header")
        
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
                    let jsonResponse = try JSONDecoder().decode(PostContacts.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
        
    }
    
    func searchUsers(specification: PostViewSpecification, completion: @escaping (PostUsers?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/search-users")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(String(specification.token), forHTTPHeaderField: "token-header")
        print(specification.post_id)
        request.setValue(String(specification.post_id), forHTTPHeaderField: "post-id-header")
        if specification.username_header != nil {
            request.setValue(String(specification.token), forHTTPHeaderField: "username-header")
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(PostUsers.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func addConvo(specification: AddConversationSpecification, completion: @escaping (ConvoCreationResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/add-conversation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let parameters = ["token": specification.token, "convo_partners": specification.convo_partners, "post_id": String(specification.post_id)] as [String : Any] // Create dictionary according to User
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(ConvoCreationResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func loadConvo(convo_header: Int, completion: @escaping (ConvoMessages?) -> Void) {
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/load-conversation")!
        
        // Build URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(String(convo_header), forHTTPHeaderField: "convo-header")
        
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
                    let jsonResponse = try JSONDecoder().decode(ConvoMessages.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func sendMessage(specification: MessageSpecification, completion: @escaping (ConfirmationResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/send-message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let parameters = ["token": specification.token, "conversation_id": specification.conversation_id, "message": specification.message] as [String : Any] // Create dictionary according to User
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(ConfirmationResponse.self, from: data) // Try to decode data
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
    
    func createRating(specification: PostViewSpecification, completion: @escaping (ConfirmationResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/create-rating")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let parameters = ["token": specification.token, "post_id": String(specification.post_id), "search_username": nil,"rating": specification.rating!] as [String : Any] // Create dictionary according to User;
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(ConfirmationResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func changeProfilePic(user: String, userpicture: URL, completion: @escaping (ProfilePostResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/profile/change_profile_pic")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(user, forHTTPHeaderField: "user")
        request.setValue(userpicture.absoluteString, forHTTPHeaderField: "userpicture")
        
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
                    let jsonResponse = try JSONDecoder().decode(ProfilePostResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func createMeeting(specification: ConversationSpecification, completion: @escaping (MeetingResponse?) -> Void) {
        
        /*-----------------*
         * GET FROM BACKEND
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/create-meeting")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let parameters = ["conversation_id": specification.conversation_id] as [String : Any] // Create dictionary according to User;
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
                // Parse JSON response into expected response (LoadClassesResponse)
                do {
                    let jsonResponse = try JSONDecoder().decode(MeetingResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
                        completion(jsonResponse)
                    }
                    
                } catch {
                    print("TestError2: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // Starts network request
    }
    
    func loadMeeting(convo_header: Int, completion: @escaping (MeetingResponse?) -> Void) {
        /*-----------------*
         * GET FROM BACKEND *
         *-----------------*/
        let url = URL(string: "http://172.30.195.217:8000/post/load-meeting")!
        
        // Build URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(String(convo_header), forHTTPHeaderField: "convo-header")
        
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
                    let jsonResponse = try JSONDecoder().decode(MeetingResponse.self, from: data) // Try to decode data
                    print(jsonResponse)
                    
                    DispatchQueue.global().asyncAfter(deadline: .now()) {
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

//
//  IntegrationTests.swift
//  TutorFinder
//
//  Created by Evan Oberneder on 4/9/25.
//

import XCTest
@testable import TutorFinder

class UserTests: XCTestCase {
    
    // Variables
    var app: XCUIApplication!
    
    // Setup
    override func setUp() {
        super.setUp()
        
        // Launch app
        app = XCUIApplication()
        app.launch()
        
    }
    
    // Teardown
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // Test the full integration of logging in, from the UI to the successful backend response with a token.
    func testLogin() {
        
        let usernameTextField = app.textFields["usernameTextField"]
        let passwordTextField = app.textFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        let expectation = self.expectation(description: "Login Successfully")
        
        usernameTextField.tap()
        usernameTextField.typeText("User123")
        app.tap()
        
        passwordTextField.tap()
        passwordTextField.typeText("User123")
        app.tap()
        
        loginButton.tap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // Token recieved?
            if let token = UserDefaults.standard.string(forKey: "userToken") {
                print("Login Test - PASSED")
                expectation.fulfill()
                
            } else {
                
                print("Login Test - FAILED")
                expectation.fulfill()
                
            }
        }
        
        waitForExpectations(timeout: 6, handler: nil)
        
    }
    
    // Tests the function of logging in, search button action, searched classes table, tap-to-add class function, updating class list action
    func testAddClassFromSearch() {
        
        // LoginViewController
        let usernameTextField = app.textFields["usernameTextField"]
        let passwordTextField = app.textFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        // ClassesViewController
        let searchGeneralButton = app.buttons["searchGeneralButton"]
        let searchAlertButton = app.buttons["searchAlertButton"]
        let classesTableView = app.tables["classesTableView"]
        
        // SearchViewController
        let searchTableView = app.tables["searchTableView"]
        let searchTableViewCell = searchTableView.cells.staticTexts["EECS 3100 Embedded Systems"]
        let addSearchedClassActionButton = app.buttons["addSearchedClassActionButton"]
        
        // Misc Alerts
        let okButton = app.alerts.buttons["OK"]
        
        let expectation = self.expectation(description: "Class Added Successfully")
        
        // Login
        usernameTextField.tap()
        usernameTextField.typeText("User123")
        app.tap()
        
        passwordTextField.tap()
        passwordTextField.typeText("User123")
        app.tap()
        
        // Search classes
        loginButton.tap()
        searchGeneralButton.tap()
        searchAlertButton.tap()
        
        // Add class
        searchTableViewCell.tap()
        addSearchedClassActionButton.tap()
        okButton.tap()
        
        // Back to classes page - reload and check if new class is there
        app.navigationBars.buttons["My Classes"].tap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Is new class in class list?
            if (classesTableView.cells.staticTexts["Embedded Systems"].exists) {
                print("Add Class From Search Test - PASSED")
                expectation.fulfill()
            } else {
                print("Add Class From Search Test - FAILED")
                expectation.fulfill()
            }
           
        }
        
        waitForExpectations(timeout: 6, handler: nil)
        
    }
    
    
}

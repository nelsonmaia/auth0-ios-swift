// ProfileViewController.swift
// Auth0Sample
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit
import SafariServices
import Auth0
import SimpleKeychain


class ProfileViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!

    var profile: UserInfo!
    

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        profile = SessionManager.shared.profile
        self.welcomeLabel.text = "Welcome, \(self.profile.name ?? "no  name")"
        guard let pictureURL = self.profile.picture else { return }
        let task = URLSession.shared.dataTask(with: pictureURL) { (data, response, error) in
            guard let data = data , error == nil else { return }
            DispatchQueue.main.async {
                self.avatarImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    @IBAction func logout(_ sender: UIBarButtonItem) {
        let auth0 = Auth0.webAuth()
        auth0.clearSession(federated: true) { outcome in
            print("Logout Called: \(outcome))")
            DispatchQueue.main.async {
                SessionManager.shared.logout()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    @IBAction func callAPIWithoutAuthentication(_ sender: UIButton) {
        self.callAPI(authenticated: false)
    }

    @IBAction func callAPIWithAuthentication(_ sender: UIButton) {
        self.callAPI(authenticated: true)
    }
    
    //Set SAML SP-Initiated Sign In URL End-point here:
    
    @IBAction func ssoExampleButton(sender: AnyObject) {
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return }
        let svc = SFSafariViewController(url: NSURL(string: "https://" + clientInfo.domain + "/samlp/gNhlQtJGz15VB0tdCHXRGGLpgV7skpGp")! as URL)
        self.present(svc, animated: true, completion: nil)
    }

    private func callAPI(authenticated shouldAuthenticate: Bool) {
        
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return }
        
        // Example API services is your Auth0 domain's Auth0 Mgmt API
        let url = URL(string: "https://" + clientInfo.domain + "/api/v2/users/" + profile.sub.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)! // Set to your Protected API URL
        var request = URLRequest(url: url)
        
        // Configure your request here (method, body, etc)
        if shouldAuthenticate {
            guard let token = A0SimpleKeychain(service: "Auth0").string(forKey: "access_token") else {
                return
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                let title = "Results"
                let message = "Error: \(String(describing: error?.localizedDescription))\n\nData: \(String(describing: data == nil ? "nil" : String(data: data!, encoding: String.Encoding.utf8) as String?))\n\nResponse: \(String(describing: response?.description))"
                let alert = UIAlertController.alertWithTitle(title, message: message, includeDoneButton: true)
                self.present(alert, animated: true, completion: nil)

            }
        })
        task.resume()
    }
   
    @IBAction func checkUserRole(sender: UIButton) {
        
        guard
            let roles = SessionManager.shared.userRoles(),
            roles.contains("CSA")
            else { return self.showAccessDeniedAlert() }
        
        self.showAdminPanel()
    }
    
    private func showAdminPanel() {
        self.performSegue(withIdentifier: "ShowAdminPanel", sender: nil)
    }
    
    private func showAccessDeniedAlert() {
        let alert = UIAlertController.alertWithTitle("Access denied", message: "You do not have privileges to access the admin panel", includeDoneButton: true)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showErrorRetrievingRolesAlert() {
        let alert = UIAlertController.alertWithTitle("Error", message: "Could not retrieve roles from server", includeDoneButton: true)
        self.present(alert, animated: true, completion: nil)
    }
}

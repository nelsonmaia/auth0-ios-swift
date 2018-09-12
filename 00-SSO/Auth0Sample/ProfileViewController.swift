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
 
    @IBOutlet var accessToken: UILabel!
    
    @IBOutlet var refreshToken: UILabel!
    var profile: UserInfo!
    

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        profile = SessionManager.shared.profile
        // let refreshToken = SessionManager.shared.credentials?.refreshToken;
        self.welcomeLabel.text = "Welcome, \(self.profile.name ?? "no  name")"
        self.refreshTokensLabel()
        guard let pictureURL = self.profile.picture else { return }
        let task = URLSession.shared.dataTask(with: pictureURL) { (data, response, error) in
            guard let data = data , error == nil else { return }
            DispatchQueue.main.async {
                self.avatarImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    private func refreshTokensLabel(){
        DispatchQueue.main.async {
            self.accessToken.text = "Access Token : \(SessionManager.shared.credentials?.accessToken ?? "No access token") "
            self.refreshToken.text = "Refresh Token : \(SessionManager.shared.credentials?.refreshToken ?? "No refresh token") "
        }
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

    // Don't use any token to invoke the API
    @IBAction func callAPIWithoutAuthentication(_ sender: UIButton) {
        self.callAPI(authenticated: false)
    }

    // Use the current access token stored in the credentials
    @IBAction func callAPIWithAuthentication(_ sender: UIButton) {
        self.callAPI(authenticated: true)
    }
    
    // Use refresh token to request a new token
    @IBAction func callAPIWithNewAcessToken(_ sender: UIButton) {
        self.callAPI(authenticated: true, useRefreshToken : true)
    }
    
    
    //Set SAML SP-Initiated Sign In URL End-point here:
    @IBAction func ssoExampleButton(sender: AnyObject) {
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return }
        let svc = SFSafariViewController(url: NSURL(string: "https://" + clientInfo.domain + "/samlp/gNhlQtJGz15VB0tdCHXRGGLpgV7skpGp")! as URL)
        self.present(svc, animated: true, completion: nil)
    }
    
    private func getUsers(request : URLRequest){
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                var title = "Results"
                
                do {
                    
                    guard let data = data, error == nil else { return }
                    
//                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
//                    let statusCode = json["error"] as? [[String: Any]] ?? []
//                    print("its here")
//                    print(statusCode)
//                    print(json)
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 401 {           // check for http errors
                        print("statusCode should be 200, but is ")
                        title = "Unauthorized"
                    }
                    

                    
                } catch let error as NSError {
                    print(error)
                }
                
                let message = "Message: \(String(describing: error?.localizedDescription))\n\nData: \(String(describing: data == nil ? "nil" : String(data: data!, encoding: String.Encoding.utf8) as String?))\n\nResponse: \(String(describing: response?.description))"
                let alert = UIAlertController.alertWithTitle(title, message: message, includeDoneButton: true)
                self.present(alert, animated: true, completion: nil)
                
            }
        })
        task.resume()
    }

    private func callAPI(authenticated shouldAuthenticate: Bool, useRefreshToken: Bool=false) {
        
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return }
        
        // Example API services is your Auth0 domain's Auth0 Mgmt API
        let url = URL(string: "https://" + clientInfo.domain + "/api/v2/users/" + profile.sub.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)! // Set to your Protected API URL
        var request = URLRequest(url: url)
        
        // Configure your request here (method, body, etc)
        if useRefreshToken {
            
            SessionManager.shared.renewAuth { error in
                
                self.refreshTokensLabel()
                print(SessionManager.shared.credentials?.accessToken)
                
                guard let token = SessionManager.shared.credentials?.accessToken else {
                    return
                }
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "GET"
                
                self.getUsers(request: request)
            }
            
            
            
        }else{
            
            if shouldAuthenticate {
                guard let token = SessionManager.shared.credentials?.accessToken else {
                    return
                }
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "GET"
            }
            
            
            self.getUsers(request: request)

        }
        
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
    
    fileprivate func checkToken(callback: @escaping () -> Void) {
        let loadingAlert = UIAlertController.loadingAlert()
        loadingAlert.presentInViewController(self)
        SessionManager.shared.renewAuth { error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    guard error == nil else {
                        print("Failed to retrieve credentials: \(String(describing: error))")
                        return callback()
                    }
                    SessionManager.shared.retrieveProfile { error in
                        DispatchQueue.main.async {
                            guard error == nil else {
                                print("Failed to retrieve profile: \(String(describing: error))")
                                return callback()
                            }
                            self.performSegue(withIdentifier: "ShowProfileNonAnimated", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
}

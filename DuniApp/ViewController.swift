//
//  ViewController.swift
//  DuniApp
//
//  Created by 파디오 on 2020/05/18.
//  Copyright © 2020 파디오. All rights reserved.
//
import UIKit
import WebKit


class ViewController: UIViewController,UIApplicationDelegate,WKScriptMessageHandler {
    
    @IBOutlet weak var webViewContainer: UIView!
    

     let requestURLString =  "https://duni.io/index.php"
    
    var webView: WKWebView!
    var backButton: UIButton!
    var forwadButton: UIButton!
    var checkInfoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "dunilogo")
        imageView.image = image
        navigationItem.titleView = imageView
        
        
        //a
        // Do any additional setup after loading the view.
        
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true;
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = preferences
        webConfiguration.applicationNameForUserAgent = "Version/8.0.2 Safari/600.2.5"
               
        
        let userController :WKUserContentController = WKUserContentController()
        userController.add(self, name: "nativeAction_1")
        userController.add(self, name: "nativeAction_2")
        
        
        webConfiguration.userContentController = userController
        
        let customFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 0.0, height: self.webViewContainer.frame.size.height))
        self.webView = WKWebView (frame: customFrame , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webViewContainer.addSubview(webView)
        webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: webViewContainer.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: webViewContainer.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        webView.heightAnchor.constraint(equalTo: webViewContainer.heightAnchor).isActive = true
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        self.openUrl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    
    }

    func openUrl() {
        
        
        let str_url = requestURLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL (string: str_url!)
        
        let request = URLRequest.init(url: url!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        webView.load(request)
    }
    
    @IBAction func BackBtnTap(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func ForwardBtnTap(_ sender: Any) {
        webView.goForward()
    }
    
    @IBAction func HomeBtnTap(_ sender: Any) {
        let str_url = requestURLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL(string: str_url!)
        let requestObj = URLRequest(url: url! as URL)
        webView.load(requestObj)
    }
    
    @IBAction func etcBtnTap(_ sender: Any) {
        /*let registerString = "https://home.duni.io/partner_application.html"
        let str_url = registerString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL(string: str_url!)
        let requestObj = URLRequest(url: url! as URL)
        webView.load(requestObj)*/
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
        
        self.navigationController?.pushViewController(controller, animated: true)
        //self.present(controller, animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("padio case mon \(message)")
        switch message.name {
        case "padio nativeAction_1" :
            
            guard let body = message.body as? NSDictionary else { NSLog("error body type"); return }
            
        case "padio nativeAction_2" : return
            
        case "callbackHandler":
            print("padio callback handler \(message.body)")
            return
        default:
            NSLog("padio undefined message = %s", message.name)
        }
    }

}


extension ViewController: WKUIDelegate{
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController =
            UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction =
            UIAlertAction(title: "OK", style: .default) { action in
                completionHandler()
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController =
            UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let cancelAction =
            UIAlertAction(title: "Cancel", style: .cancel) { action in
                completionHandler(false)
        }
        
        let okAction =
            UIAlertAction(title: "OK", style: .default) {
                action in completionHandler(true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    
}

extension ViewController:WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let param: String = "jsCallTest"
        
        let execJsFunc: String = "test(\"\(param)\");"
        print("padio finish url  \(webView.url)")
        webView.evaluateJavaScript(execJsFunc, completionHandler: { (object, error) -> Void in
            
        })
        
        webView.evaluateJavaScript("document.getElementById(\"header header-transparent\").removeAttribute(\"href\");") { (result, error) in
            if error == nil {
                // header is hide now
                print(result)
            }else{
                print(error)
                
            }
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        print("padio request \(navigationAction.request)")
        if navigationAction.targetFrame == nil {
            
            let popup = WKWebView(frame: webViewContainer.bounds, configuration: configuration)
            popup.navigationDelegate = self
            popup.uiDelegate = self
            webViewContainer.addSubview(popup)
            return popup
            
            //webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview();
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        print("이동할 URL1 : \(url)")
        print("이동할 URL2 : \(url.absoluteString)")
        
        if url.absoluteString.range(of: "//itunes.apple.com/") != nil {
            UIApplication.shared.open(url, options: [:]) { (re5sult) in
                return
            }
        }
        else if !url.absoluteString.hasPrefix("http://") && !url.absoluteString.hasPrefix("https://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                print("padio no url")
            }
        }
        
        webView.bringSubviewToFront(webViewContainer)
        decisionHandler(.allow)
    }
    
    
}


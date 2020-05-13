//
//  SantaluciaWebController.swift
//  Santalucia
//
//  Created by  on 02/04/2020.
//  Copyright © 2020 Julio Nieto Santiago. All rights reserved.
//

import UIKit
import WebKit

protocol SantaluciaWebPresenting: class {
    var webView: SantaluciaWebView? {get set}
    func exitPressed()
    func needsAuthentication()
    func didInitNavigationAction(_ action: WKNavigationAction) -> WKNavigationActionPolicy
    func didReceiveNavigationResponse(_ response: WKNavigationResponse) -> WKNavigationResponsePolicy
    func didChangeUrl(_ url: String)
}

protocol SantaluciaWebView: class {
    func present(alert: UIAlertController)
    func load(urlRequest: URLRequest)
}

class SantaluciaWebController: UIViewController {
    private let webView = WKWebView()
    private let loader = UIActivityIndicatorView(style: .gray)
    
    var presenter: SantaluciaWebPresenting?
    private var titleObserver: NSKeyValueObservation?
    private var progressObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    
    override func loadView() {
        self.view = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationItem.backBarButtonItem == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitButtonPressed))
        }
        observeTitle()
        observeProgress()
        observeUrl()
        presenter?.webView = self
    }
    
    private func observeTitle() {
        let handler = {(webView: WKWebView, change: NSKeyValueObservedChange<String?>) in
            self.navigationItem.title = webView.title?.capitalized
        }
        titleObserver = webView.observe(\WKWebView.title, changeHandler: handler)
    }
    
    private func observeUrl() {
        urlObserver = webView.observe(\WKWebView.url, changeHandler: {[weak self] (webView: WKWebView, change: NSKeyValueObservedChange<URL?>) in
            self?.presenter?.didChangeUrl(webView.url?.absoluteString ?? "")
        })
    }
    
    private func observeProgress() {
        let handler = {(webView: WKWebView, change: NSKeyValueObservedChange<Double>) in
            switch webView.estimatedProgress {
            case let x where x < 1.0: self.showLoading()
            default: self.hideLoading()
            }
        }
        progressObserver = webView.observe(\WKWebView.estimatedProgress, changeHandler: handler)
    }
    
    private func showLoading() {
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loader), animated: true)
        loader.startAnimating()
    }
    
    private func hideLoading() {
        loader.startAnimating()
        navigationItem.rightBarButtonItem = nil
    }
    
    @objc func exitButtonPressed() {
        presenter?.exitPressed()
    }
}

extension SantaluciaWebController: SantaluciaWebView {
    func present(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func load(urlRequest: URLRequest) {
        webView.load(urlRequest)
    }
}

extension SantaluciaWebController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let presenter = presenter else {
            decisionHandler(.allow)
            return
        }
        
        let decision: WKNavigationActionPolicy = presenter.didInitNavigationAction(navigationAction)
        decisionHandler(decision)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let presenter = presenter else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(presenter.didReceiveNavigationResponse(navigationResponse))
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        presenter?.needsAuthentication()
        completionHandler(.performDefaultHandling, nil)
    }
}

extension SantaluciaWebController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        present(alert: .webAlert(with: message))
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        present(alert: .webAlert(with: message))
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        present(alert: .promptWebAlert(with: prompt, placeholder: defaultText, completionHandler))
    }
}

fileprivate extension UIAlertController {
    static func webAlert(with message: String) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.ok)
        return alert
    }
    
    static func promptWebAlert(with message: String, placeholder: String?, _ completion: @escaping (String?) -> ()) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addTextField { (textFiled) in
            textFiled.text = placeholder
        }
        alert.addAction(.ok {
            completion(alert.textFields?.first?.text)
        })
        return alert
    }
}

extension UIAlertAction {
    static var ok = UIAlertAction(title: "OK", style: .default, handler: nil)
    static func ok(_ completion: @escaping () -> ()) -> UIAlertAction {
        UIAlertAction(title: "OK", style: .default) { (_) in
            completion()
        }
    }
}

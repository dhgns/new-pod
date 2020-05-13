//
//  SantaluciaWebPresenter.swift
//  Santalucia
//
//  Created by  on 02/04/2020.
//  Copyright © 2020 Julio Nieto Santiago. All rights reserved.
//

import Foundation
import WebKit

protocol SantaluciaWebRouting {
    func exit()
    func unauthorized()
    func error(_ error: Error)
}

class SantaluciaWebPresenter {
    private let url: String
    private let extraHeaders: [String: String]
    private let queryParamas: [String: String]
    private let delegate: SantaluciaWebViewDelegate?
    
    init(url: String, extraHeaders: [String: String], queryParamas: [String: String], delegate: SantaluciaWebViewDelegate?) {
        self.url = url
        self.extraHeaders = extraHeaders
        self.queryParamas = queryParamas
        self.delegate = delegate
    }
    
    weak var webView: SantaluciaWebView? {
        didSet {
            loadWebView()
        }
    }
    
    private func loadWebView() {
        do {
            webView?.load(urlRequest: try buildRequest())
        } catch let error {
            delegate?.didFail(with: error)
        }
    }
    
    private func buildRequest() throws -> URLRequest {
        guard let url = URL(string: url), var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw SantaluciaWebViewError.couldNotParseUrl
        }
        
        if !queryParamas.isEmpty {
            let queryItems = queryParamas.map({URLQueryItem(name: $0, value: $1)})
            urlComponents.queryItems = queryItems
        }
        guard let finalUrl = urlComponents.url else {
            throw SantaluciaWebViewError.couldNotParseUrl
        }
        var request = URLRequest(url: finalUrl)
        extraHeaders.forEach({
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        })
        
        return request
    }
}

extension SantaluciaWebPresenter: SantaluciaWebPresenting {
    func didChangeUrl(_ url: String) {
        delegate?.didChangeUrl(url)
    }
    
    func exitPressed() {
        delegate?.didSelectExit()
    }
    
    func needsAuthentication() {
        delegate?.didAskForCredentials()
    }
    
    func didInitNavigationAction(_ action: WKNavigationAction) -> WKNavigationActionPolicy {
        return delegate?.didInitNavigationAction(action) ?? .allow
    }
    
    func didReceiveNavigationResponse(_ response: WKNavigationResponse) -> WKNavigationResponsePolicy {
        guard let httpResponse = response.response as? HTTPURLResponse else {return .allow}
        switch httpResponse.statusCode {
        case let x where x >= 400:
            delegate?.didFail(with: SantaluciaWebViewError.httpError(x))
            return .cancel
        default: return delegate?.didReceiveNavigationResponse(response) ?? .allow
        }
    }
    
    func didReceive(response: HTTPURLResponse) {
        switch response.statusCode {
        case let x where x >= 400: delegate?.didFail(with: SantaluciaWebViewError.httpError(x))
        default: break
        }
    }
}

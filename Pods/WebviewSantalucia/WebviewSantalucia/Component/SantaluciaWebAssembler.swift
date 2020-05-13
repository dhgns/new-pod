//
//  ModalSantaluciaWebAssembler.swift
//  Santalucia
//
//  Created by  on 02/04/2020.
//  Copyright © 2020 Julio Nieto Santiago. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public enum SantaluciaWebViewError: Error {
    case couldNotParseUrl, httpError(Int)
}

public protocol SantaluciaWebViewDelegate {
    func didSelectExit()
    func didAskForCredentials()
    func didFail(with error: Error)
    func didChangeUrl(_ url: String)
    func didInitNavigationAction(_ action: WKNavigationAction) -> WKNavigationActionPolicy
    func didReceiveNavigationResponse(_ response: WKNavigationResponse) -> WKNavigationResponsePolicy
}

public extension SantaluciaWebViewDelegate {
    func didInitNavigationAction(_ action: WKNavigationAction) -> WKNavigationActionPolicy {.allow}
    func didReceiveNavigationResponse(_ response: WKNavigationResponse) -> WKNavigationResponsePolicy {.allow}
}

public class SantaluciaWebViewFactory {
    public static func create(url: String, queryParams: [String: String] = [:], extraHeaders: [String: String] = [:], delegate: SantaluciaWebViewDelegate?) -> UIViewController {
        SantaluciaWebAssembler().resolve(url: url, queryParams: queryParams, extraHeaders: extraHeaders, delegate: delegate)
    }
}

protocol SantaluciaWebAssembling {
    func resolve(url: String, queryParams: [String: String], extraHeaders: [String: String], delegate: SantaluciaWebViewDelegate?) -> SantaluciaWebController
    func resolve(url: String, queryParams: [String: String], extraHeaders: [String: String], delegate: SantaluciaWebViewDelegate?) -> SantaluciaWebPresenting
}

class SantaluciaWebAssembler: SantaluciaWebAssembling {
    func resolve(url: String, queryParams: [String: String], extraHeaders: [String: String], delegate: SantaluciaWebViewDelegate?) -> SantaluciaWebController {
        let vc = SantaluciaWebController()
        vc.presenter = resolve(url: url, queryParams: queryParams, extraHeaders: extraHeaders, delegate: delegate)
        return vc
    }
    
    func resolve(url: String, queryParams: [String: String], extraHeaders: [String: String], delegate: SantaluciaWebViewDelegate?) -> SantaluciaWebPresenting {
        return SantaluciaWebPresenter(url: url, extraHeaders: extraHeaders, queryParamas: queryParams, delegate: delegate)
    }
}

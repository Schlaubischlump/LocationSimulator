//
//  DonateMethod.swift
//  LocationSimulator
//
//  Created by David Klopp on 18.04.22.
//  Copyright © 2022 David Klopp. All rights reserved.
//

import Foundation
import AppKit

enum DonateMethod: CaseIterable {
    case payPal
    case githubSponsors
    case ethereum

    static var enabledCases: [DonateMethod] = [
        // TODO: Add github sponsors
        .payPal,
        .ethereum
    ]

    var name: String {
        switch self {
        case .payPal:           return "PayPal"
        case .githubSponsors:   return "Github Sponsors"
        case .ethereum:         return "Ethereum"
        }
    }

    var icon: NSImage {
        switch self {
        case .payPal:           return .payPalImage
        case .githubSponsors:   return .githubImage
        case .ethereum:         return .ethImage
        }
    }

    var value: String {
        switch self {
        case .payPal:           return "https://www.paypal.com/donate/?hosted_button_id=9NR3CLRUG22SJ"
        // TODO: Replace this with the actual URL
        case .githubSponsors:   return "https://github.com/Schlaubischlump/LocationSimulator"
        case .ethereum:         return "0xCF8bbB8A4437abCC53025736bE5a9b83D0c26843"
        }
    }

    var linkURL: URL? {
        switch self {
        case .ethereum: return nil
        default:        return URL(string: self.value)
        }
    }

    var actionTitle: String {
        switch self {
        case .ethereum: return "COPY_BUTTON".localized
        default:        return "OPEN_BUTTON".localized
        }
    }

    func performAction() {
        switch self {
        case .ethereum:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(self.value, forType: .string)
        default:
            if let link = self.linkURL {
                NSWorkspace.shared.open(link)
            }
        }
    }
}

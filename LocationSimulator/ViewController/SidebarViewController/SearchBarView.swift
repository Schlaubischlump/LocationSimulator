//
//  SearchBarView.swift
//  LocationSimulator
//
//  Created by David Klopp on 14.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit

class SearchbarView: NSView {
    /// Main searchField.
    let searchField = NSSearchField(frame: .zero)

    /// BackgroundView stretches to titlebar.
    let effectView = NSVisualEffectView(frame: .zero)

    /// Enable or disable the user interaction.
    var userInteractionEnabled: Bool = true {
        didSet {
            self.searchField.isEnabled = self.userInteractionEnabled
        }
    }

    /// Show a shadow separator shadow below this view.
    var showSeparatorShadow: Bool = false {
        didSet {
            guard oldValue != self.showSeparatorShadow else { return }

            if self.showSeparatorShadow {
                let shadow = NSShadow()
                shadow.shadowOffset = .zero
                shadow.shadowBlurRadius = 1.0
                self.animator().shadow = shadow
            } else {
                self.animator().shadow = nil
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.addSubview(self.effectView)
        self.effectView.addSubview(self.searchField)

        self.wantsLayer = true
        self.layer?.masksToBounds = false
    }

    override func layout() {
        super.layout()

        // Draw the effectView outside of the bounds up to the titlebar.
        let titlebarHeight = self.window?.titlebarHeight ?? 0
        self.effectView.frame = self.bounds
        self.effectView.frame.size.height += titlebarHeight

        // Layout the searchBar with a padding of 10 on the left and right.
        let xOff = 10.0
        let viewWidth = self.frame.width
        let viewHeight = self.frame.height
        let searchFieldHeight = 28.0
        let yOff = (viewHeight - searchFieldHeight)
        self.searchField.frame = CGRect(x: xOff, y: yOff, width: viewWidth - xOff * 2, height: searchFieldHeight)
    }
}

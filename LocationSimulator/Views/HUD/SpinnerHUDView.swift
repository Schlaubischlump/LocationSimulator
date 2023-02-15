//
//  SpinnerContainerView.swift
//  LocationSimulator2
//
//  Created by David Klopp on 17.08.20.
//

import AppKit

class SpinnerHUDView: HUDView {
    // The main spinner view.
    private lazy var spinner: NSProgressIndicator = {
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        return spinner
    }()

    // MARK: - Constructor

    private func setup() {
        // Add the spinner to the HUD with half of the HUD size
        let parentSize = self.bounds.size
        let size = 1/2*parentSize.width
        let xOff = (parentSize.width-size)/2
        let yOff = (parentSize.height-size)/2
        self.spinner.frame = CGRect(x: xOff, y: yOff, width: size, height: size)
        self.spinner.autoresizingMask = [.minXMargin, .maxYMargin]
        self.contentView.addSubview(self.spinner)
        // Hide the spinner on default
        self.isHidden = true
        self.activeEffectStateFollowsWindow = false
    }

    override init() {
        super.init()
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    // MARK: - Spinner

    func startSpinning() {
        self.isHidden = false
        self.spinner.startAnimation(self)
    }

    func stopSpinning() {
        self.spinner.stopAnimation(self)
        self.isHidden = true
    }
}

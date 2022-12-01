//
//  ChangeLogViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 25.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import AppKit

let kLastAppVersion: String = "com.schlaubischlump.locationsimulator.lastappversion"

// Extend the UserDefaults with all keys relevant for this tab.
extension UserDefaults {
    @objc dynamic var lastAppVersion: String? {
        get { return self.string(forKey: kLastAppVersion) }
        set { self.setValue(newValue, forKey: kLastAppVersion) }
    }

    /// Register the default NSUserDefault values.
    func registerInfoDefaultValues() {
        // Nothing to do here yet, since nil is a valid lastAppVersion value
    }
}

struct DonateInfo: Codable {
    var supporter: Int
    var donations: Float
    var donationTarget: Float
    var targetName: String
}

class InfoViewController: PreferenceViewControllerBase {
    let donateProgress = DonateProgress()

    var progressData: DonateInfo? {
        didSet {
            DispatchQueue.main.async {
                self.applyProgressData()
            }
        }
    }

    var isProgressLoaded: Bool = false
    var progressLock = NSLock()

    override func loadView() {
        let padX = 15.0
        let padY = 10.0
        let spacingY = 15.0

        // Setup donate button
        let donateButton = DonateButton()
        donateButton.title = "DONATE_BUTTON".localized
        donateButton.target = self
        donateButton.action = #selector(openDonateWindow(_:))
        donateButton.frame.origin.y = padY

        // Setup donate progress.
        self.donateProgress.sizeToFit()
        self.donateProgress.frame.origin.y = donateButton.frame.maxY + spacingY

        // Setup info field
        let infoField = NSTextField(frame: .zero)
        infoField.isEditable = false
        infoField.isEnabled = false
        infoField.drawsBackground = false
        infoField.textColor = .secondaryLabelColor
        infoField.font = .labelFont(ofSize: NSFont.systemFontSize)
        infoField.alignment = .center
        infoField.isBezeled = false
        infoField.preferredMaxLayoutWidth = kMaxPreferenceViewWidth - padX*2

        infoField.stringValue = "WELCOME".localized
        infoField.frame.size = infoField.fittingSize
        infoField.frame.origin.x = padX
        infoField.frame.origin.y = self.donateProgress.frame.maxY + spacingY * 2

        donateButton.frame.origin.x = (infoField.frame.width - donateButton.frame.width)/2 + padX
        self.donateProgress.frame.size.width = infoField.frame.width
        self.donateProgress.frame.origin.x = padX

        // Container
        let container = NSView()
        container.addSubview(infoField)
        container.addSubview(donateButton)
        container.addSubview(self.donateProgress)
        container.frame.size.width = infoField.frame.width + padX*2
        container.frame.size.height = infoField.frame.maxY + padY*2

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadProgressData()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.applyProgressData()
    }

    private func loadProgressData() {
        self.donateProgress.hasAmount = 0

        URLSession.shared.dataTask(with: URL(string: kDonationInfo)!) { (data, _, _) in
            guard let data = data else { return }
            self.progressData = try? JSONDecoder().decode(DonateInfo.self, from: data)
        }.resume()
    }

    private func applyProgressData() {
        self.progressLock.lock()
        defer {
            self.progressLock.unlock()
        }

        guard let data = self.progressData, !self.isProgressLoaded, self.isViewLoaded else { return }

        self.isProgressLoaded = true
        self.donateProgress.hasAmount = data.donations
        self.donateProgress.goalAmount = data.donationTarget
        self.donateProgress.goal = data.targetName
    }

    @objc private func openDonateWindow(_ sender: NSButton) {
        // FIXME: This should work.... but it doesn't
        // self.performSegue(withIdentifier: "ShowDonateWindow", sender: nil)
        // Manually trigger the donate menu item
        HelpMenubarItem.donate.triggerAction()
    }
}

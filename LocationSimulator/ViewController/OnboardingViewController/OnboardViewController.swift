//
//  OnboardingViewController.swift
//  LocationSimulator
//
//  Created by David Klopp on 01.02.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

import Foundation
import AppKit

private let kButtonWidth = 60.0
private let kPageControlHeight = 40.0

class OnboardViewController: NSViewController {
    private var pageView = NSView(frame: .zero)

    public var pages: [OnboardPageViewController] = [] {
        didSet {
            self.updatePages()
        }
    }

    private let pageControl = PageControl()
    private let pageController: NSPageController!
    private let leftArrow = ArrowView(direction: .left)
    private let rightArrow = ArrowView(direction: .right)

    init(pages: [OnboardPageViewController]) {
        self.pages = pages
        self.pageController = NSPageController()

        super.init(nibName: nil, bundle: nil)

        self.pageController.transitionStyle = .horizontalStrip
        self.pageController.delegate = self

        self.addChild(self.pageController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: .zero)

        // Fix weird layout bugs on macOS 14
        self.pageControl.clipsToBounds = true
        self.leftArrow.clipsToBounds = true
        self.rightArrow.clipsToBounds = true

        self.pageController.view = pageView

        self.doLayout()
        self.updatePages()

        self.leftArrow.action = { [weak self] in
            self?.pageController?.navigateBack(nil)
            self?.updateArrows()
        }
        self.rightArrow.action = { [weak self] in
            self?.pageController?.navigateForward(nil)
            self?.updateArrows()
        }
        self.pageControl.action = { [weak self] pageIndex in
            self?.pageController.animator().selectedIndex = pageIndex
            self?.updateArrows()
        }

        self.view.addSubview(pageView)
        self.view.addSubview(self.leftArrow)
        self.view.addSubview(self.rightArrow)
        self.view.addSubview(self.pageControl)
    }

    private func updatePages() {
        let titlebarHeight = 20.0
        self.pages.forEach {
            $0.contentInset = NSEdgeInsets(
                top: titlebarHeight, left: kButtonWidth, bottom: kPageControlHeight, right: kButtonWidth
            )
        }
        self.pageController.arrangedObjects = self.pages.indices.map { String($0) }
        self.pageControl.numberOfPages = self.pages.count
        self.updateArrows()
    }

    private func updateArrows() {
        let isOnFirstPage = self.pageController.selectedIndex == 0
        let isOnLastPage = self.pageController.selectedIndex == self.pages.count - 1

        self.leftArrow.isUserInteractionEnabled = !isOnFirstPage
        self.rightArrow.isUserInteractionEnabled = !isOnLastPage
    }

    private func doLayout() {
        let bounds = self.view.bounds

        self.pageView.frame = bounds
        self.leftArrow.frame.origin = CGPoint(x: 0, y: 0)
        self.leftArrow.frame.size = CGSize(width: kButtonWidth, height: bounds.height)

        self.rightArrow.frame.size = CGSize(width: kButtonWidth, height: bounds.height)
        self.rightArrow.frame.origin = CGPoint(x: bounds.width - kButtonWidth, y: 0)

        self.pageControl.frame = CGRect(x: 0, y: 0, width: bounds.width, height: kPageControlHeight)

        self.pageController.view.frame = bounds
        self.updateArrows()

        // Set the initial frame size of the first page
        self.pageController.view.subviews.forEach {
            $0.frame = self.pageController.view.bounds
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        self.doLayout()
    }
}

extension OnboardViewController: NSPageControllerDelegate {
    public func pageController(_ pageController: NSPageController, frameFor object: Any?) -> NSRect {
        return pageController.view.bounds
    }

    public func pageController(_ pageController: NSPageController,
                               viewControllerForIdentifier identifier: String) -> NSViewController {
        guard let id = Int(identifier), id < self.pages.count else {
            fatalError("Unexpected view controller identifier, \(identifier)")
        }
        return self.pages[id]
    }

    public func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }

    public func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        self.pageControl.currentPage = pageController.selectedIndex
        self.updateArrows()
        pageController.completeTransition()
    }
}

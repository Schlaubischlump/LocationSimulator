//
 //  ContentView.swift
 //  LocationSimulator
 //
 //  Created by David Klopp on 14.08.20.
 //  Copyright © 2020 David Klopp. All rights reserved.
 //

 import AppKit

 class ContentView: NSView {
     /// This is an even uglier workaround to deliver the appearance change notification for macOS version greater. 11.0
     override func viewDidChangeEffectiveAppearance() {
         if #available(OSX 11.0, *) {
             NotificationCenter.default.post(name: .AppleInterfaceThemeChanged, object: nil)
         }
     }
 }

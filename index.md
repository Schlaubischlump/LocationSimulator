LocationSimulator is a macOS app (10.15.x / 11.x, 12.x) which allows spoofing the location of an iOS or iPhoneSimulator device. The target audience of this project are developers who want to test their location service based application. I do not encourage the use of this application to cheat in iOS games and I do not provide support for these games. If you use this application outside of the intended purposes, you are on your own.

![Screenshot](https://raw.githubusercontent.com/Schlaubischlump/LocationSimulator/master/Preview/screenshot.png)

# Install 

Click on `Download .zip`, extract the file and run `LocationSimulator.app` by right-clicking on `open` to grant a Gatekeeper exception.

Alternatively you can use homebrew to install LocationSimulator. The version can be slightly outdated, when installed this way.

1. Install [homebrew](https://brew.sh) by entering the following command in your terminal: 

	```shell
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	```
2. Install LocationSimulator with [homebrew](https://brew.sh) using:

	```shell
	brew install locationsimulator
	```

# Features

- Spoof the iOS device location without a jailbreak or installing an app on the device.
- Automatically try to download the DeveloperDiskImage files for your iOS Version.
- Set the device location with a long click on the map.
- Support 3 movement speeds (Walk/Cycle/Drive).
- Control the movement using the arrow keys.
- Navigate from the current location to a new location.
- Open GPX files.
- Support network devices.
- Search for locations.
- Support dark mode.

# Changelog

### v0.1.9
- Move when standing still
- Autoreverse navigation
- UI does not lock up anymore when uploading a DeveloperDiskImage
- Hovering a device in the sidebar reveals the full name
- Resizing the window if no device is connected is now possible
- New backend code for spoofing

### v0.1.8.4
- Fix Swedish localization thanks to @devmaximilian !
- Add a speed slider to the toolbar (Right click -> Customize toolbar)
- Decrease the location update interval for smoother movements

### v0.1.8.3
- Fix UI lockup if Xcode 13.3 is installed
- Xcode 13.3 support for iPhoneSimulator

### v0.1.8.2

- ⚠️ Language support other than english and german is partially incomplete
- Change the map type (satellite, hybrid, explore)
- Select the menubar items when changing the move type
- Add zoom-in and zoom-out menubar items
- Add pause / continue indicator to navigation
- Add a Log view to easier diagnose errors (Help -> Log...)
- Choose a custom DeveloperDiskImage directory (Preferences -> DeveloperDiskImages)
- Manage the DeveloperDiskImages from the preference window (Preferences -> DeveloperDiskImages)

### v0.1.8.1
- Italian support
- Add zoom control to map
- Fix support for macOS Catalina

### v0.1.8
- Support for iOS 15.x
- Fix DeveloperDiskImage fallback URL
- Swedish localization
- Sandbox support

### v0.1.7
- Drop official support for 10.13 / 10.14
- Confirm teleportation option
- New device sidebar
- New search Popup
- Code cleanup
- Bug fixes

### v0.1.6
- Add a fallback download URL, to support new iOS versions without updating LocationSimulator
- Use mac location button to set the spoofed location to your macOS location
- New movement control to better fit the macOS design language (macOS 11)
- Provide the foundation to support TvOS and WatchOS DevleoperDiskImages
- Move Licenses to preference window
- Open GPX files
- Bug fixes

### v0.1.5
- Fix macOS 10.13/10.14
- Wi-Fi / USB indicator
- Application settings
- UI fixes for Big Sur
- New device backend
- Bug fixes

### v0.1.4
- Fix search popup does not disappear when searchfield is cleared
- Fix searchField not working on Big Sur
- Fix dark mode not working on Big Sur
- Add iOS 14.1 download link

### v0.1.3
- Fix the iOS 12 download links
- Fix image mount error on iOS 14.0

### v0.1.2
- Fix a bug where the location search popup was not updated correctly or did not appear at all
- Update DeveloperDiskImage.plist to support versions up to iOS 13.7 and iOS 14.0
- Fix a bug where the speed was calculated incorrectly

### v0.1.1
- Initial version

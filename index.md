LocationSimulator is a macOS app (10.15.x / 11.x), licensed under the [GNU General Public License version 3](https://opensource.org/licenses/gpl-3.0), which allows spoofing the location of an iOS device. The main target audience of this project are developers who want to test their location service based application. Of course you might as well use this app to spoof your location inside [PokemonGo](https://www.pokemongo.com), but don't blame me if you get banned. The method used to spoof your location is basically the same used by [PokemonGo Webspoof](https://github.com/iam4x/pokemongo-webspoof) (except that Xcode is not required) or [iSpoofer](https://www.ispoofer.com).

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

### v0.1.7
- Drop official support for 10.13 / 10.14
- New device sidebar
- Confirm teleportation option
- New search Popup
- Code cleanup
- Bug fixes

### v0.1.6
- Open GPX files
- Provide the foundation to support TvOS and WatchOS DevleoperDiskImages
- New movement control to better fit the macOS design language (macOS 11)
- Use mac location button to set the spoofed location to your macOS location
- Add a fallback download URL, to support new iOS versions without updating LocationSimulator
- Move Licenses to preference window
- Bug fixes

### v0.1.5
- New device backend
- Wi-Fi / USB indicator
- Application settings
- Bug fixes
- UI fixes for Big Sur
- Fix macOS 10.13/10.14

### v0.1.4
- Fix search popup does not disappear when searchfield is cleared
- Fix searchField not working on Big Sur
- Fix dark mode not working on Big Sur
- Add iOS 14.1 download link

### v0.1.3
- Fix the iOS 12 download links
- Fix image mount error on iOS 14.0

### v0.1.2
- Fix a bug where the location search popup was not updated correctly or did not appear at all.
- Fix a bug where the speed was calculated incorrectly.
- Update DeveloperDiskImage.plist to support versions up to iOS 13.7 and iOS 14.0.

### v0.1.1
- Initial version

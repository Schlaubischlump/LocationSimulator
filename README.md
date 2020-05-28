<div align="center">
  <img src="LocationSimulator/Assets.xcassets/AppIcon.appiconset/AppIcon_256.png" width="128px">
  <h2 align="center">LocationSimulator</h2>
</div>

![LocationSimulator screenshot](Preview/screenshot.png)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

LocationSimulator is a macOS app which allows spoofing the location of an iOS device. The main target audience of this project are developers who want to test their location service based application. Of course you might as well use this app to spoof your location inside [PokemonGo](https://www.pokemongo.com), but don't blame me if you get banned. The method used to spoof your location is basically the same used by [PokemonGo Webspoof](https://github.com/iam4x/pokemongo-webspoof) (except that Xcode is not required) or [iSpoofer](https://www.ispoofer.com).

- [Background](#background)
- [Features](#features)
- [Build](#build)
    - [Requirements](#requirements)
    - [Build the app](#build-the-app)
- [Usage](#usage)
    - [Start spoofing](#start-spoofing)
    - [Moving](#moving)
    - [Stop spoofing](#stop-spoofing)
- [License](#license)
- [Contribute](#contribute)
- [Enhancement ideas](#enhancement-ideas)

## Background

While I originally planed to build upon the fantastic work of [Watanabe Toshinoris](https://github.com/watanabetoshinori) [LocationSimulator](https://github.com/watanabetoshinori/LocationSimulator/issues) I decided to recreate and change the whole project because of the projects (back then) missing [license](https://github.com/watanabetoshinori/LocationSimulator/issues/5). I created all necessary images and source code files and removed all dependencies except for [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice). Even [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) is not required anymore. You just need the `DeveloperDiskImage.dmg` and `DeveloperDiskImage.dmg.signature` files for your iOS Version.

## Features

- ✅ Spoof the iOS device location without a jailbreak or installing an app on the device.
- ✅ Automatically try to download the DeveloperDiskImage files for your iOS Version.
- ✅ Set the device location with a long click on the map.
- ✅ Support 3 movement speeds (Walk/Cycle/Drive).
- ✅ Control the movement using the arrow keys.
- ✅ Navigate from the current location to a new location.
- ✅ Support network devices.
- ✅ Search for locations.
- ✅ Support dark mode.

## Build

### Requirements

- macOS 10.13+
- Swift 5.0+
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
	- [libusbmuxd](https://github.com/libimobiledevice/libusbmuxd)
	- [libplist](https://github.com/libimobiledevice/libplist)
	- [libopenssl](https://github.com/openssl/openssl)
	- [libcrypto](https://github.com/openssl/openssl)

> **Note**:    
> LocationSimulator will try to download the corresponding `DeveloperDiskImage.dmg` and `DeveloperDiskImage.dmg.signature` for your iOS Version from github, because I can not legally distribute these files. If the download should not work, get the files by installing Xcode and copy or link them to:    
> ```~/Library/Application Support/LocationSimulator/{MAJOR_YOUR_IOS_VERSION}.{MINOR_YOUR_IOS_VERSION}/```

### Build the app

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install latest version of [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) (and thereby all it's dependencies as well) with [homebrew](https://brew.sh):

	```shell
	brew install libimobiledevice --HEAD
	```
> You might need a new version of `libusbmuxd` and `libplist` for `libimobiledevice` to install. Use ```brew install usbmuxd --HEAD``` and ```brew install libplist --HEAD``` to install the latest versions.
3. Clone this repository:    

	```shell
	git clone --recurse-submodules https://github.com/Schlaubischlump/LocationSimulator
	```
4. Open `LocationSimulator.xcodeproj` in Xcode.
5. Adjust the header search paths, library search paths ~~and the embedded~~ and linked libraries if required.
> If you checked out a different head for `libimobiledeive` or `libusbmuxd` than used in this project, you will need to change all of the above entries.
6. Tap Run to build and execute the app.

> **Note**:  
> If you want to build a standalone application which can be copied to another Mac without installing the dependencies choose the `LocationSimulator` scheme and switch the configuration to `Release` before running. If you do not want to bundle the dependencies, but want to create a release build choose the `Homebrew` scheme. When a new release of `libimobiledevice` is available, I will try to create a homebrew cask for this application. 

## Usage

### Start spoofing:
  1. Connect the iOS device to your computer via USB or Wi-Fi.
  2. Long click the point you want to set as the current location on the map.

### Moving:
  - Click the walk button at bottom left corner of the map. Drag the blue triangle to change the direction of movement.    
  	<img src="Preview/walk.png" height="60">
  - Long click the walk button to enabled auto move. Click again to disable auto move.    
  	<img src="Preview/automove.png" height="60">
  - Long click on a new point on the map while you are spoofing the location to show the navigation prompt or select the menu item to set the coordinates manually.    
    <img src="Preview/navprompt.png" width="200">
  - Use the left and right arrow keys to change the direction of movement. Use up and down to move. Press space to stop the navigation.

### Stop spoofing:
  - Click the reset button.    
    <img src="Preview/reset.png" height="60px">

## License

The whole project is licensed under the [MIT License](LICENSE) unless specified otherwise in the specific subdirectories.

## Contribute
Help is always appreciated, wether it are bug fixes or features! E.g accessibility support is still to be implemented, especially for the popup menu.

## Enhancement ideas
- Allow following a predefined route from a gpx file

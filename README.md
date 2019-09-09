<div align="center">
  <img src="LocationSimulator/Assets.xcassets/AppIcon.appiconset/AppIcon_256.png" width="128px">
  <h2 align="center">LocationSimulator</h2>
</div>

![LocationSimulator screenshot](Preview/screenshot.png)

## Description

LocationSimulator is a macOS app which allows spoofing the location of an iOS device. The main target audience of this project are developers who want to test their location service based application. Of course you might as well use this app to spoof your location inside [PokemonGo](https://www.pokemongo.com), but don't blame me if you get banned. The method used to spoof your location is basically the same used by [PokemonGo Webspoof](https://github.com/iam4x/pokemongo-webspoof) (except that Xcode is not required) or [iSpoofer](https://www.ispoofer.com).

## Background

While I originally planed to build upon the fantastic work of [Watanabe Toshinoris](https://github.com/watanabetoshinori) [LocationSimulator](https://github.com/watanabetoshinori/LocationSimulator/issues) I decided to recreate and change the whole project because of the projects missing [license](https://github.com/watanabetoshinori/LocationSimulator/issues/5). I created all necessary images and source code files and removed all dependencies except for [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice). Even [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) is not required anymore. You just need the `DeveloperDiskImage.dmg` and `DeveloperDiskImage.dmg.signature` files for your iOS Version.

## Features

- ✅ Spoof the iOS device location without a jailbreak or installing an app on the device.
- ✅ Automatically try to download the DeveloperDiskImage files for your iOS Version.
- ✅ Set the device location with a long click on the map.
- ✅ Supported 3 movement speeds (Walk/Cycle/Drive).
- ✅ Control the movement using the arrow keys.
- ✅ Navigate from the current location to a new location.
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
> ```~/Library/Application Support/LocationSimulator/{YOUR_IOS_VERSION}/```

### Build the app

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install latest version of [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) (and thereby all it's dependencies as well) with [homebrew](https://brew.sh):

	```shell
	brew install libimobiledevice --HEAD
	```
> You might need a new version of `libusbmuxd` for `libimobiledevice` to install. Use ```brew install usbmuxd --HEAD``` to install the latest version.
1. Clone this repository:    

	```shell
	git clone --recurse-submodules https://github.com/Schlaubischlump/LocationSimulator
	```
1. Open `LocationSimulator.xcodeproj` in Xcode.
1. Adjust the library search paths and the linked libraries if required.
1. Tap Run to build and execute the app.


## Usage

### Start spoofing:
  1. Connect the iOS device to your computer via USB.
  2. Long click the point you want to set as the current location on the map.

### Moving:
  - Click the walk button at bottom left corner of the map. Drag the blue triangle to change the direction of movement.    
  	<img src="Preview/walk.png" height="60">
  - Long click the walk button to enabled auto move. Click again to disable auto move.    
  	<img src="Preview/automove.png" height="60">
  - Long click on a new point on the map while you are spoofing the location to show the navigation prompt.    
    <img src="Preview/navprompt.png" width="200">
  - Use the left and right arrow keys to change the direction of movement. Use up and down to move. Press space to stop the navigation.

### Stop spoofing:
  - Click the reset button.    
    <img src="Preview/reset.png" height="60px">

## License

The whole project is licensed under the [MIT License](LICENSE) unless specified otherwise in the specific subdirectories.

## Contribute
Help is always appreciated, wether it are Bug fixes or features! E.g Accessibility support is still to be implemented, especially for the popup menu.

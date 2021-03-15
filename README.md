If you got an `Unable to install/mount DeveloperDiskImage.dmg` error, verify that you tried everything mentioned [here](https://github.com/Schlaubischlump/LocationSimulator/issues/76) before openening a new issue.

[![License: GNU General Public License version 3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://opensource.org/licenses/gpl-3.0)

<div align="center">
  <img src="LocationSimulator/Assets.xcassets/AppIcon.appiconset/AppIcon_256.png" width="128px">
  <h2 align="center">LocationSimulator</h2>
</div>

LocationSimulator is a macOS app (10.15.x / 11.x) which allows spoofing the location of an iOS or iPhoneSimulator device. The main target audience of this project are developers who want to test their location service based application. Of course you might as well use this app to spoof your location inside [PokemonGo](https://www.pokemongo.com), but don't blame me if you get banned. I do not provide support for PokemonGo related issues. I do not encourage anyone to use this for PokemonGo. According to one [report](https://github.com/Schlaubischlump/LocationSimulator/issues/70) using the navigation feature will get you banned. The method used to spoof your location is basically the same used by [PokemonGo Webspoof](https://github.com/iam4x/pokemongo-webspoof) (except that Xcode is not required) or [iSpoofer](https://www.ispoofer.com). That means, this application might have the same issues [[1]](https://github.com/iam4x/pokemongo-webspoof/issues/451), [[2]](https://www.reddit.com/r/PokemonGoSpoofing/comments/fg10ih/so_what_is_the_deal_with_ispoofer_and_bans/) as similar applications in regards to PokemonGo.

![LocationSimulator screenshot](Preview/screenshot.png)

- [Background](#background)
- [Features](#features)
- [Install](#install)
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

- [x] Spoof the iOS device location without a jailbreak or installing an app on the device.
- [x] Automatically try to download the DeveloperDiskImage files for your iOS Version.
- [x] Set the device location with a long click on the map.
- [x] Support 3 movement speeds (Walk/Cycle/Drive).
- [x] Control the movement using the arrow keys.
- [x] Navigate from the current location to a new location.
- [x] Support network devices.
- [x] Search for locations.
- [x] Support dark mode.

> **Note**:    
> LocationSimulator will try to download the corresponding `DeveloperDiskImage.dmg` and `DeveloperDiskImage.dmg.signature` for your iOS Version from github, since I can not legally distribute these files. If the download should not work, get the files by installing Xcode and copy or link them to:    
> 
>```
>~/Library/Application Support/LocationSimulator/{YOU_PLATFORM}/{MAJOR_YOUR_IOS_VERSION}.{MINOR_YOUR_IOS_VERSION}/
>```    
> `YOU_PLATFORM` might be `iPhone OS` (iPhone and iPad), `Watch OS` (Apple Watch) or `Tv OS` (Apple TV). `MAJOR_YOUR_IOS_VERSION` might `14` and `MINOR_YOUR_IOS_VERSION` might be `3` for a device running iOS 14.3.
>
> As of v0.1.8 this folder moved to: 
>```
>~/Library/Containers/com.schlaubi.LocationSimulator/Data/Library/Application Support/LocationSimulator/
>```

## Install

1. Install [homebrew](https://brew.sh) by entering the following command in your terminal: 

	```shell
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	```
2. Install LocationSimulator with [homebrew](https://brew.sh) using:

	```shell
	brew install locationsimulator
	```

## Build

### Requirements

- macOS 10.15+
- macOS 11.x+ SDK
- swift 5.0+
- swift-tools-version 5.2+
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice)
	- [libusbmuxd](https://github.com/libimobiledevice/libusbmuxd)
	- [libplist](https://github.com/libimobiledevice/libplist)
	- [libopenssl](https://github.com/openssl/openssl)
	- [libcrypto](https://github.com/openssl/openssl)

### Build the app

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple. (Using the AppStore is the easiest way)
2. Install the latest version of [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) (and thereby all it's dependencies as well) with [homebrew](https://brew.sh):

	```shell
	brew install libimobiledevice
	```
3. Clone this repository:    

	```shell
	git clone --recurse-submodules https://github.com/Schlaubischlump/LocationSimulator
	```
4. Open `LocationSimulator.xcodeproj` in Xcode.
5. Tap `Run` to build and execute the app.

> **Note**:  
> If you want to build a standalone application which can be copied to another Mac without installing the dependencies choose the `LocationSimulator` scheme and switch the configuration to `Release` before running. If you do not want to bundle the dependencies, but want to create a release build choose the `Homebrew` scheme.

## Usage

### Start spoofing:
  1. Connect the iOS device to your computer via USB or Wi-Fi.
  2. Select the device in the sidebar.
  3. Long click the point you want to set as the current location on the map.

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

The whole project is licensed under the [GNU General Public License version 3](LICENSE) unless specified otherwise in the specific subdirectories.

## Contribute
Since I maintain this project in my freetime, I always appreciate any help I get. Even if you are not a programmer and do not know anything about coding you can still help out. Currently this project is only available in English and German. It would be great if more languages were available. If you know any other language and you are willing to invest some time to help with the translation let me know [here](https://github.com/Schlaubischlump/LocationSimulator/issues/65)! I want this software to be as stable as possible, if you find any bug please report it by opening a new issue. If you are a programmer, feel free to contribute bug fixes or new features. It would be greate if you run swift-lint on your code before submitting pull requests.

While you are here, consider leaving a Github star. It keeps me motivated. 

## Enhancement ideas
Look at the [`Projects`](https://github.com/Schlaubischlump/LocationSimulator/projects) tab to see a list of planned features for the next releases. 

## Acknowledgement
Special thanks to [@bailaowai](https://github.com/bailaowai) and his son for the Spanish and Chinese translation.

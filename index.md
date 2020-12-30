LocationSimulator is a macOS app (10.15.x / 11.x), licensed under the [GNU General Public License version 3](https://opensource.org/licenses/gpl-3.0), which allows spoofing the location of an iOS device. The main target audience of this project are developers who want to test their location service based application. Of course you might as well use this app to spoof your location inside [PokemonGo](https://www.pokemongo.com), but don't blame me if you get banned. The method used to spoof your location is basically the same used by [PokemonGo Webspoof](https://github.com/iam4x/pokemongo-webspoof) (except that Xcode is not required) or [iSpoofer](https://www.ispoofer.com).

![Screenshot](https://raw.githubusercontent.com/Schlaubischlump/LocationSimulator/master/Preview/screenshot.png)

# Install 

Click on `Download .zip`, extract the file and run `LocationSimulator.app` by right-clicking on `open` to grant grant a Gatekeeper exception.

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

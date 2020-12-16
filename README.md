# WPA Bible Engagement App

This is an app aimed at digitizing the bible engagement experience at WPA.

# Getting Started
Some notes on things to install as a developer
## Mac OSX
Follow this guide if you are developing on a Mac
1. Download the code in this repository using `git clone git@bitbucket.org:wpa-tdd/wpa-be-app.git`
2. Open the resulting `wpa-be-app/ios` folder in Xcode
3. In Xcode, go to the left-hand side folder directory and click on `Runner`, then in the top navigation bar click on `Signing & Capabilites`, then sign in with your apple account to sign the application.
4. Download `flutter` and `dart` from [the flutter website](https://flutter.dev/docs/get-started/install/macos) to your `~/Downloads` folder by clicking the blue "flutter_macos_1.29.3-stable.zip" button.
5. Unzip the zip file to get a "flutter" folder
6. Move the flutter folder to somewhere on your system by running `mv ~/Downloads/flutter /usr/local/lib`
7. Create a symbolic link to the flutter executable and dart executable by running `ln -s /usr/local/lib/flutter/bin/flutter /usr/local/bin/flutter` and `ln -s /usr/local/lib/flutter/bin/dart /usr/local/bin/dart`
8. Ensure that your `PATH` variable includes `/usr/local/bin` by running `echo $PATH` (If it isn't listed, you can add it using `export PATH=$PATH:/usr/local/bin`)
9. Test that flutter and dart are found by running `which flutter` and `which dart`
10. Run `flutter clean` in the project directory (This can be done from the VSCode terminal)
### iOS
1. Ensure you have a clean output for the iOS relevant sections when you run `flutter doctor`. You most likely need to run the following commands:
    - `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
    - `sudo xcode-select -runFirstLaunch`
2. Make sure you have cocoapods installed by running `which pod`, otherwise download it with `sudo gem install cocoapods`
3. Run `flutter build ios` in the project directory
4. You need to have Simulator downloaded, which you should get automatically when you download [Xcode from the App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12).
5. If this is your first time running Xcode, you need to open it and accept the user license agreement.
6. Now you can close Xcode, and open the Simulator by using Spotlight Search (CMD + Space) and typing "Simulator" and opening the application.
7. With Simulator running and the device open on your screen, you can run `flutter run`.
### Android
1. TODO

# Notes to Developers 
## Suggested VS Code Extensions 
- Pubspec Assist
- bloc
- Dart
- dart-import
- Flutter
- TODO Highlight


## Setting up the dev environment 

1. Go to console.firebase.com
2. Click on wpa-be-ap-dev (you will need to request developer access to this project)
3. Go to settings - general 
4. Scroll to the "Your apps" section and download the `google-services.json` from the `wpa-be-app-dev-andriod` app 
and the `GoogleService-info.plist` from the `wpa-be-app-dev-ios` app. 

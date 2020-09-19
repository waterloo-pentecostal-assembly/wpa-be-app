# WPA Bible Engagement App

This is an app aimed at digitizing the bible engagement experience at WPA.

# Getting Started
Some notes on things to install as a developer
## Mac OSX
Follow this guide if you are developing on a Mac
1. Download the code in this repository using `git clone git@bitbucket.org:wpa-tdd/wpa-be-app.git`
2. Open the resulting `wpa-be-app/ios` folder in Xcode
3. In Xcode, go to the left-hand side folder directory and click on `Runner`, then in the top navigation bar click on `Signing & Capabilites`, then sign in with your apple account to sign the application.
1. Download `flutter` and `dart` from [the flutter website](https://flutter.dev/docs/get-started/install/macos) to your `~/Downloads` folder by clicking the blue "flutter_macos_1.29.3-stable.zip" button.
2. Unzip the zip file to get a "flutter" folder
3. Move the flutter folder to somewhere on your system by running `mv ~/Downloads/flutter /usr/local/lib`
4. Create a symbolic link to the flutter executable and dart executable by running `ln -s /usr/local/lib/flutter/bin/flutter /usr/local/bin/flutter` and `ln -s /usr/local/lib/flutter/bin/dart /usr/local/bin/dart`
5. Ensure that your `PATH` variable includes `/usr/local/bin` by running `echo $PATH` (If it isn't listed, you can add it using `export PATH=$PATH:/usr/local/bin`)
6. Test that flutter and dart are found by running `which flutter` and `which dart`
7. Run `flutter clean` in the project directory (This can be done from the VSCode terminal)
### iOS
1. Run `flutter build ios` in the project directory
2. Go to Xcode, open the `wpa-be-app/ios` folder, and now click the play button to run the app (You might have to download a Simulator (i.e. iPhone 11) and an iOS (i.e. iOS 10) before you can do this!)
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
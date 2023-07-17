# WPA Bible Engagement App

A mobile application aimed at taking the bible engagement and church community experience at WPA into the digital realm.

## Flutter Installation 

Follow instructions [here](https://flutter.dev/docs/get-started/install) for your operating system. If you are on Windows or Linux, ensure that you are able to run the Android Emulator. If you are on macOS, ensure that you are able to run both the Android Emulator and iOS Simulator. Once the installation is complete, run `flutter doctor` and ensure that there are no errors. 

### Test setup with the default Flutter app

1. Create a temporary folder somewhere on your system. 
2. In the terminal, run `flutter create default-app`. 
3. Once setup is complete, `cd default-app` and run `flutter run`. 
4. Ensure that you are able to run the default app on an Android Emulator (and iOS simulator if you are on macOS).
5. Delete the `default-app` once it runs as expected. 

## Setting up the dev environment 

1. Go to console.firebase.com
2. Click on wpa-be-ap-dev (you will need to request developer access to this project)
3. Go to settings - general 
4. Scroll to the "Your apps" section and download the `google-services.json` from the `wpa-be-app-dev-android` app 
and the `GoogleService-info.plist` from the `wpa-be-app-dev-ios` app. Save these for later.

### Android Configuration 

1. In the `android/app/src` folder, create folder called `dev` and place the `google-services.json` from step 4. in it. 


### iOS Configuration 

1. In Xcode, open the `ios/Runner.xcodeproj` project. 
2. In the root `Runner` project, create a folder called `config`. In there, create another folder called `dev`. 
3. Drag the `GoogleService-info.plist` from step 4. above into this folder. 

## Recommended Editor

It is recommended to use VSCode, with the following extensions for this project. 

- Pubspec Assist
- bloc
- Dart
- dart-import
- Flutter
- TODO Highlight

In the `.vscode/launch.json` file, add the following to be able to run and debug the app from within VSCode. 

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "wpa-be-app-dev",
            "request": "launch",
            "type": "dart",
            "program": "lib/app/flavors/main_dev.dart",
            "args": [
                "--flavor",
                "dev"
            ]
        },
        {
            "name": "wpa-be-app-local-dev",
            "request": "launch",
            "type": "dart",
            "program": "lib/app/flavors/main_local_dev.dart",
            "args": [
                "--flavor",
                "dev"
            ]
        }
    ]
}
```

## Starting the app

There are currently two ways we can run the application in the development environment. 

1. By connecting it to the remote Firebase instance (referred to as `dev` mode).

    To do this, either:
    
    * Run `flutter run -t lib/app/flavors/main_dev.dart --flavor dev` in the `wpa-be-app` folder.
    * Navigate to the run tab in VSCode, select the `wpa-be-app-dev` configuration and click the green run icon.

2. By connecting it to a local Firebase Emulator (referred to as `local_dev` mode).

    **N.B.** The local Firebase Emulator must be running. See instruction in the [wpa-be-firebase](https://github.com/waterloo-pentecostal-assembly/wpa-be-firebase) repository. 

    To do this, either:
    
    * Run `flutter run -t lib/app/flavors/main_local_dev.dart --flavor dev` in the `wpa-be-app` folder.
    * Navigate to the run tab in VSCode, select the `wpa-be-app-local-dev` configuration and click the green run icon.

## Building for release 
### Andriod 
* Build appbundle: `flutter build appbundle -t lib/app/flavors/main_prod.dart --flavor prod`

* Build APK: `flutter build apk -t lib/app/flavors/main_prod.dart --flavor prod`
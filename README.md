# RideCare — Motorcycle Maintenance Log

**Student:** Erika D. Dacula  
**Section:** BSINTE-2A

RideCare is a Flutter mobile app for motorcycle owners to record oil changes and repairs, track mileage and costs, and see when the next oil service is due. All data is stored locally on the device. **No Supabase is used.**

## Features
- Motorcycle profile: name, brand/model, current odometer, and oil interval
- Create, edit, and delete oil-change entries
- Create, edit, and delete repair entries
- Record service date, mileage, work/parts details, and costs
- Automatically calculate repair parts + labor totals
- Maintenance history and total spending dashboard
- Next oil-change mileage reminder
- Local persistence with SharedPreferences

## Built with
- Flutter and Dart
- Material 3
- SharedPreferences (on-device storage)
- intl (date and Philippine peso formatting)

## Requirements
- Flutter SDK (stable channel)
- Android Studio or VS Code with the Flutter extension
- Android emulator or Android phone with USB debugging

## Setup
Clone this repository, then generate the standard Flutter platform folders:

~~~bash
git clone https://github.com/erikadacula17-glitch/Vehicle-Maintenance-Log.git
cd Vehicle-Maintenance-Log
flutter create --platforms=android,web .
flutter pub get
flutter run
~~~

## Build an Android APK
~~~bash
flutter build apk --release
~~~
The APK will be at \`build/app/outputs/flutter-apk/app-release.apk\`.

## Data and privacy
Maintenance records and motorcycle profile settings are saved on the device using SharedPreferences. Uninstalling the app or clearing app data may erase locally stored records. There is no Supabase connection and no cloud sync.

## Student
Erika D. Dacula — BSINTE-2A

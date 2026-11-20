# Skyfur – Pet Care App

A cross-platform pet care app built with Flutter and Firebase Authentication. My first complete app, built during a student startup collaboration at the college incubation centre (Sept 2026).

## Features
- Email/password sign-up and login (Firebase Authentication)
- Home dashboard with cards linking to every feature
- Pet scan: image upload with preview
- Vet appointment booking form
- Insurance plan cards
- Pet certification (microchip verification) screen
- 3-step Pet Care flow with live dog breed photos (Dog CEO API)
- Responsive layout: drawer menu on phones, navigation rail on tablets and desktop

## Tech Stack
Flutter, Dart, Firebase Authentication, Material 3, Google Fonts

## Download and Documentation
APK and project documentation: https://drive.google.com/drive/folders/1UJKWCp_lgzAgJuGzERR5b8lJOrqkFHRN?usp=drive_link

## Run the app
    flutter pub get
    flutter run -d chrome

To build an Android APK:

    flutter build apk --release

## Known Limitations
- The scan feature only uploads and previews an image; it does not detect diseases
- Vet booking and insurance plans use sample data, not real providers
- Care recommendations are curated content

## My Contribution
I worked on the Flutter screens and Firebase login in this project, learning Flutter fundamentals with AI-assisted development tools.

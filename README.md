# Mosjid Finder

Mosjid Finder is a Flutter application that helps users discover mosques near their current location. The app uses Google Maps and the Google Places API to fetch and display nearby mosques on a map.

## Features

- **Home Screen**: A welcoming screen with a brief description and a button to find nearby mosques.
- **Map Screen**: Displays a map centered on the user's current location with markers for nearby mosques.
- **Mosque Details**: Shows a list of nearby mosques with their names and distances, and allows users to view their locations on the map.

## Screenshots
<img src="https://github.com/user-attachments/assets/ff6c7d16-c292-4995-8db5-4e0171b39062" alt="MuMu12-1" width="275"/>
<img src="https://github.com/user-attachments/assets/57dbebef-8311-4968-87b6-2082d2f70bdf" alt="MuMu12-2" width="275"/>
<img src="https://github.com/user-attachments/assets/791a846a-d71c-4af7-a5a3-f2539aa259b5" alt="MuMu12-3" width="275"/>


## Installation

1. **Clone the repository**:
    ```sh
    git clone https://github.com/yourusername/mosjid-finder.git
    cd mosjid-finder
    ```

2. **Install dependencies**:
    ```sh
    flutter pub get
    ```

3. **Run the app**:
    ```sh
    flutter run
    ```

## Configuration

1. **Google Maps API Key**:
    - Obtain an API key from the [Google Cloud Console](https://console.cloud.google.com/).
    - Replace the placeholder API key in `lib/services/mosque_service.dart` with your actual API key:
      ```dart
      static const String _googleApiKey = 'YOUR_API_KEY_HERE';
      ```

2. **Assets**:
    - Ensure the following assets are available in the `assets/images` directory:
      - `mosque512.png`
      - `mosque212.png`
    - Update the `pubspec.yaml` file to include these assets:
      ```yaml
      flutter:
        assets:
          - assets/images/mosque512.png
          - assets/images/mosque212.png
      ```

## Dependencies

- [Flutter](https://flutter.dev/)
- [google_maps_flutter](https://pub.dev/packages/google_maps_flutter)
- [geolocator](https://pub.dev/packages/geolocator)
- [http](https://pub.dev/packages/http)

## Project Structure

```plaintext
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   └── map_screen.dart
└── services/
    └── mosque_service.dart
assets/
└── images/
    ├── mosque512.png
    └── mosque212.png

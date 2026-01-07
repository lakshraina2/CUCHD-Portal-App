# CUCHD Portal App

A Flutter-based mobile application for Chandigarh University students, providing quick access to the university portal and useful academic calculators.

## Features

### 📱 Portal Access
- **WebView Integration**: Direct access to the CU student portal (students.cuchd.in) within the app
- **Seamless Navigation**: Stay logged in and navigate the portal without switching to a browser
- **Loading Indicators**: Visual feedback during page loads

### 🧮 Marks Calculator
- **Regular Course Support**: Calculate internal marks for regular courses
- **Hybrid Course Support**: Calculate internal marks for hybrid courses with:
  - Assignment marks
  - Attendance marks
  - Surprise tests
  - Quiz marks
  - MST 1 & 2 marks
  - Lab MST marks (for hybrid)
  - End semester practical marks (for hybrid)
  - Worksheets (10 worksheets for hybrid)
- **Real-time Calculation**: Instant results based on CUCHD marking scheme

### 📊 CGPA Calculator
- **Multi-Subject Support**: Add unlimited subjects
- **Credit System**: Support for 1-7 credit courses
- **Grade System**: Complete grade point mapping (A+, A, B+, B, C+, C, D, F)
- **Dynamic Interface**: Add/remove subjects on the fly
- **Accurate Calculations**: Weighted CGPA calculation based on credits

### 💰 Monetization
- Banner ads integration
- Rewarded ads support


## Tech Stack

- **Framework**: Flutter SDK (>=2.19.6 <3.0.0)
- **Language**: Dart
- **Key Dependencies**:
  - `webview_flutter`: ^4.8.0 - WebView implementation
  - `google_mobile_ads`: ^5.1.0 - Ad integration
  - `http`: ^1.4.0 - HTTP requests
  - `flutter_launcher_icons`: ^0.13.1 - App icon generation

## Getting Started

### Prerequisites

- Flutter SDK (>=2.19.6 <3.0.0)
- Android Studio / Xcode (for mobile development)
- A device or emulator to run the app

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cuchd_portal_app.git
   cd cuchd_portal_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure AdMob (Optional)**
   
   If you want to use ads, replace the ad unit IDs in `lib/main.dart`:
   - Banner Ad Unit ID
   - Rewarded Ad Unit ID
   
   Also update the AdMob App ID in:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/Info.plist`

4. **Generate app icons (Optional)**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Building for Production

### Android

1. **Configure signing**
   
   Create a `key.properties` file in the `android/` directory with your keystore details:
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=<your-key-alias>
   storeFile=<path-to-your-keystore>
   ```

2. **Build APK**
   ```bash
   flutter build apk --release
   ```

3. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

### iOS

1. Configure signing in Xcode
2. Build for release:
   ```bash
   flutter build ios --release
   ```

## Project Structure

```
lib/
├── main.dart              # Main application file
│   ├── HomeScreen         # Bottom navigation handler
│   ├── WebViewScreen      # Portal WebView screen
│   ├── MarksCalculator    # Marks calculation screen
│   └── CGPACalculator     # CGPA calculation screen
```

## Features in Detail

### Marks Calculator Logic

#### Regular Course
- Formula: `Assignment + Quiz + ((MST1 + MST2)/2) + Attendance + (SurpriseTest/12)*4`

#### Hybrid Course
- More complex calculation including:
  - Weighted surprise test scores
  - Lab MST component
  - Worksheet scores (10 worksheets)
  - End semester practical marks
- Final marks are normalized to 70% scale

### CGPA Calculator

Grade Point System:
- A+: 10.0
- A: 9.0
- B+: 8.0
- B: 7.0
- C+: 6.0
- C: 5.0
- D: 4.0
- F: 0.0

**Formula**: `CGPA = Σ(Credit × Grade Point) / Σ(Credits)`

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Chandigarh University for the student portal
- Flutter team for the amazing framework
- All contributors who help improve this app

## Disclaimer

This is an unofficial app and is not affiliated with or endorsed by Chandigarh University. The app is created for educational purposes to help students access the portal and perform academic calculations more conveniently.

## Support

If you encounter any issues or have suggestions, please open an issue on GitHub.

---

**Made with ❤️ for CU Students**

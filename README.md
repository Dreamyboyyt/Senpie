# Senpie - Anime Tracking & Download App

<p align="center">
  <img src="assets/images/senpie_logo.png" alt="Senpie Logo" width="200"/>
</p>

Senpie is a cross-platform mobile application for tracking and automatically downloading anime episodes from popular sources like Gogoanime and Animepahe. Built with Flutter, it provides a seamless experience for anime enthusiasts to manage their watchlist and keep up with their favorite series.

## Features

### 🎯 Core Features
- **Multi-Source Support**: Track anime from Gogoanime and Animepahe
- **Automatic Episode Checking**: Background service checks for new episodes at configurable intervals
- **Smart Downloads**: Automatic downloading of new episodes with quality selection
- **Episode Management**: Track watched/downloaded status for each episode
- **Offline Library**: Comprehensive anime library with search and filtering

### 📱 User Interface
- **Modern Design**: Beautiful gradient-based UI inspired by the Senpie logo
- **Dark/Light Themes**: Automatic theme switching based on system preferences
- **Responsive Layout**: Optimized for various screen sizes and orientations
- **Intuitive Navigation**: Bottom tab navigation with four main sections

### 🔧 Advanced Features
- **Background Processing**: Workmanager integration for periodic episode checking
- **Download Management**: Pause, resume, cancel, and retry downloads
- **Storage Management**: Configurable download paths and storage monitoring
- **Library Backup**: Export/import library data for backup and sharing
- **Notification System**: Alerts for new episodes and download completion
- **Settings Panel**: Comprehensive configuration options

## Screenshots

| Library | Downloads | Settings | Credits |
|---------|-----------|----------|---------|
| Track your anime collection | Manage active downloads | Configure app preferences | App information |

## Installation

### Prerequisites
- Android 5.0 (API level 21) or higher
- At least 100MB of free storage space
- Internet connection for anime tracking and downloads

### Download Options

#### From GitHub Releases
1. Go to the [Releases](../../releases) page
2. Download the appropriate APK for your device:
   - **app-release.apk** - Universal APK (recommended)
   - **app-arm64-v8a-release.apk** - For modern 64-bit devices
   - **app-armeabi-v7a-release.apk** - For older 32-bit devices
   - **app-x86_64-release.apk** - For emulators/x86 devices

#### Installation Steps
1. Enable "Install from unknown sources" in your device settings
2. Download and install the APK file
3. Grant necessary permissions when prompted
4. Launch the app and start tracking anime!

## Usage

### Getting Started
1. **Add Anime**: Use the search function to find and add anime to your library
2. **Configure Settings**: Set your preferred video quality, download path, and check intervals
3. **Enable Auto-Download**: Let Senpie automatically download new episodes
4. **Manage Downloads**: Monitor and control your downloads from the Downloads tab

### Key Workflows

#### Adding Anime to Library
1. Tap the search icon in the Library tab
2. Enter the anime title
3. Select the source (Gogoanime or Animepahe)
4. Choose from search results and add to library

#### Configuring Auto-Downloads
1. Go to Settings → Download Settings
2. Enable "Auto Download"
3. Set preferred video quality and language
4. Configure check interval (30 min, 1 hour, 6 hours)
5. Enable "WiFi Only" to save mobile data

#### Managing Storage
1. Go to Settings → Storage
2. View current storage usage
3. Change download path if needed
4. Clear cache to free up space

## Technical Details

### Architecture
- **Framework**: Flutter 3.24.5
- **State Management**: Riverpod
- **Local Storage**: SharedPreferences + SQLite
- **Background Tasks**: WorkManager
- **HTTP Client**: Dio with custom interceptors
- **HTML Parsing**: html package for web scraping

### Supported Sources
- **Gogoanime**: Full support for search, metadata, and episode downloads
- **Animepahe**: API-based integration with cookie handling

### Permissions Required
- **Internet Access**: For anime data and episode downloads
- **Storage Access**: To save downloaded episodes
- **Background Processing**: For automatic episode checking
- **Notifications**: To alert about new episodes and downloads

## Development

### Building from Source

#### Prerequisites
- Flutter SDK 3.24.5 or higher
- Android SDK with API level 34
- Java 17 or higher

#### Setup
```bash
# Clone the repository
git clone https://github.com/your-username/senpie.git
cd senpie

# Install dependencies
flutter pub get

# Generate code (if needed)
flutter packages pub run build_runner build

# Run the app
flutter run
```

#### Building APK
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Split APKs by architecture
flutter build apk --release --split-per-abi
```

### CI/CD
The project includes GitHub Actions workflows for:
- Automated building and testing
- APK generation for multiple architectures
- Security scanning with Trivy
- Automatic releases with GitHub Releases

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Guidelines
- Follow Flutter best practices
- Maintain code coverage above 80%
- Use conventional commit messages
- Test on multiple devices and Android versions

## Legal & Disclaimer

### Important Notice
Senpie is designed for personal use and educational purposes. Users are responsible for ensuring their use complies with local laws and the terms of service of the anime streaming sites.

### Disclaimer
- This app does not host any anime content
- All content is sourced from publicly available websites
- Users should support official anime distributors when possible
- The developers are not responsible for any misuse of this application

## Support

### Getting Help
- **Issues**: Report bugs and request features on [GitHub Issues](../../issues)
- **Discussions**: Join community discussions on [GitHub Discussions](../../discussions)
- **Documentation**: Check the [Wiki](../../wiki) for detailed guides

### Troubleshooting

#### Common Issues
1. **Downloads not starting**: Check storage permissions and available space
2. **Episodes not found**: Try switching between Gogoanime and Animepahe sources
3. **Background checking not working**: Ensure battery optimization is disabled for Senpie
4. **App crashes**: Clear app data and restart, or reinstall the latest version

#### Performance Tips
- Regularly clear cache in Settings → Storage
- Limit concurrent downloads to 2-3 for optimal performance
- Use WiFi for large downloads to avoid mobile data charges

## Acknowledgments

### Credits
- **Original Concept**: Based on [Senpwai](https://github.com/SenZmaKi/Senpwai) desktop application
- **Developer**: Created by Sleepy 😴
- **UI Design**: Inspired by modern anime aesthetics
- **Community**: Thanks to all beta testers and contributors

### Third-Party Libraries
- Flutter and Dart ecosystem
- Material Design Icons
- Dio HTTP client
- WorkManager for background tasks
- And many other open-source packages

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the anime community**

*Senpie - Your personal anime companion*


# 🎨 Colour Walk - Color Hunting Game

<div align="center">

**Turn your world into a colorful adventure!**  
A beautiful Flutter app that transforms color hunting into an engaging game experience.

![Flutter](https://img.shields.io/badge/Flutter-3.19-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

</div>

## ✨ Features

### 🎯 Core Functionality
- **Daily Color Challenges**: New color to hunt every day with smart color detection
- **Multiple Game Modes**: Time-limited challenges and collection quests
- **Smart Camera**: Real-time color recognition with AI-powered detection
- **Progress Tracking**: Monitor your color hunting journey with detailed stats

### 🏆 Social & Competitive
- **Leaderboards**: Compete with friends and global players
- **User Profiles**: Customize your profile and track achievements
- **Photo Gallery**: Browse your colorful collection with date grouping
- **Points System**: Earn rewards for successful color matches

### 🔧 Technical Features
- **Real-time Updates**: Live progress tracking and leaderboard updates
- **Location Tagging**: Automatic GPS tagging for all photos
- **Cross-Platform**: Works seamlessly on iOS and Android
- **Google Authentication**: Secure login with Google accounts

## 🎮 Game Modes

### Daily Hunt 🎯
- Capture today's featured color
- Simple point-and-shoot gameplay
- 1 point per successful capture

### Time Bloom ⏰  
- 5-minute timed challenges
- Capture 10 photos before time runs out
- 100 bonus points for completion

### Complete the Count 🔢
- Long-term collection quests
- Gather 50 photos of a specific color
- 500 points reward upon completion

### Coming Soon 🚧
- **Group Hunt**: Team up with friends for cooperative challenges
- **Shade vs Shade**: Competitive color matching battles

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.19+
- Firebase Project
- Supabase Account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/colourwalk.git
   cd colourwalk
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Google)
   - Enable Firestore Database
   - Add your configuration files

4. **Supabase Setup**
   - Create a new Supabase project
   - Set up storage bucket for photos
   - Configure database tables (see Database Schema)

5. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── home_page.dart           # Main dashboard
├── camera_screen.dart       # Daily color capture
├── profile_page.dart        # User profile management
├── gallery_page.dart        # Photo gallery
├── leaderboard_page.dart    # User rankings
│
├── services/
│   ├── daily_color_service.dart     # Color generation
│   ├── color_detection_service.dart # Image analysis
│   ├── points_service.dart          # Points system
│   ├── time_bloom_service.dart      # Time game mode
│   └── count_challenge_service.dart # Count game mode
│
├── game_modes/
│   ├── time_bloom_intro_screen.dart
│   ├── time_bloom_game_screen.dart
│   ├── time_bloom_camera_screen.dart
│   ├── time_bloom_results_screen.dart
│   ├── count_challenge_intro_screen.dart
│   ├── count_challenge_game_screen.dart
│   └── count_challenge_camera_screen.dart
│
└── config/
    ├── firebase_options.dart
    └── supabase_config.dart
```

## 🔥 Firebase & Supabase Setup

### Firebase Collections
- **users**: User profiles and points tracking
- **authentication**: Google and email authentication

### Supabase Tables
- **pics**: Photo storage with metadata
- **time_bloom_sessions**: Time-limited game sessions  
- **count_challenges**: Long-term collection challenges

## 🎨 Color Detection System

The app uses advanced HSL-based color matching:

```dart
// Smart color detection with configurable tolerance
Future<bool> doesImageContainColor(File image, Color targetColor, {
  double hueTolerance = 30.0,      // ±30° hue range
  double minSaturation = 0.2,      // 20% minimum saturation
  double minProminence = 0.1       // 10% color prominence
})
```

## 🏆 Points & Rewards System

| Action | Points | Description |
|--------|--------|-------------|
| Daily Photo | 1 | Each successful color match |
| Time Bloom Complete | 100 | Finish 10 photos in 5 minutes |
| Count Challenge | 500 | Complete 50-photo collection |

## 🛠️ Technologies Used

- **Frontend**: Flutter, Dart, Material Design 3
- **Backend**: Firebase Auth, Firestore, Supabase Storage
- **Computer Vision**: palette_generator, custom HSL algorithm
- **Location**: geolocator for photo tagging
- **Camera**: camera package for native device access

## 📱 How to Use

### Creating a Color Hunt
1. Log in to your account
2. Check today's featured color on the home screen
3. Use the camera to capture objects matching the color
4. Get instant feedback with color detection results

### Playing Game Modes
1. **Time Bloom**: Race against the clock to capture multiple photos
2. **Complete the Count**: Take your time to build a 50-photo collection
3. **Track Progress**: Monitor your stats and climb the leaderboards

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase and Supabase for backend services
- The color theory community
- All our beta testers and contributors

---

<div align="center">

**Made with ❤️ and 🎨 by the Colour Walk Team**

</div>

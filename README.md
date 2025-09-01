# Buildables Neu Todo

A modern, offline-first Flutter todo application with real-time collaboration features and neumorphic design. Built with Supabase backend for seamless cloud sync and file attachment support.

## 📱 Features

### Core Functionality
- **Offline-First Architecture**: Create and manage tasks even without internet connection
- **Real-time Synchronization**: Automatic sync with cloud when connectivity is restored
- **Task Management**: Create, update, delete, and organize tasks with categories
- **File Attachments**: Attach images and documents to your tasks
- **Task Sharing**: Collaborate by sharing tasks with other users
- **Neumorphic Design**: Modern, soft UI design with beautiful visual elements

### Advanced Features
- **Smart Connectivity Monitoring**: Automatic detection of online/offline status
- **Pending Upload Management**: Queues file uploads when offline
- **User Authentication**: Secure login and registration system
- **Profile Management**: User profiles with email-based identification
- **Category System**: Organize tasks with custom categories and colors
- **Real-time Collaboration**: Live updates when working with shared tasks

## 🛠️ Technologies Used

### Frontend
- **Flutter** - Cross-platform mobile development framework
- **Dart** - Programming language
- **Material Design 3** - UI components and theming

### Backend & Database
- **Supabase** - Backend-as-a-Service platform
  - Authentication
  - Real-time database
  - File storage
- **Drift** - Type-safe SQL database for offline storage
- **SQLite** - Local database engine

### Key Dependencies
- `supabase_flutter` - Supabase client for Flutter
- `drift` - Local database ORM
- `connectivity_plus` - Network connectivity monitoring
- `file_picker` & `image_picker` - File selection
- `path_provider` - File system paths
- `cached_network_image` - Image caching
- `flutter_dotenv` - Environment variables

## 🏗️ Architecture

The app follows a clean architecture pattern with the following layers:

```
lib/
├── core/                 # App-wide constants and utilities
│   └── app_colors.dart   # Color scheme definition
├── models/               # Data models
│   └── task.dart         # Task model with business logic
├── views/                # UI layer
│   ├── auth/            # Authentication screens
│   ├── home/            # Main app screens
│   └── widgets/         # Reusable UI components
├── controllers/         # Business logic controllers
├── repository/          # Data access layer
├── services/            # External services
├── database/            # Local database definitions
└── main.dart           # App entry point
```

### Key Components

- **TaskRepository**: Manages offline-first data sync between local and cloud storage
- **EnhancedFileService**: Handles file attachments with offline support
- **TaskController**: Manages task operations and real-time updates
- **AuthController**: Handles user authentication and session management

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Supabase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/LDrago-zae/buildables_neu_todo.git
   cd buildables_neu_todo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Generate database files** (if needed)
   ```bash
   flutter pub run build_runner build
   ```

### Supabase Setup

1. Create a new project on [Supabase](https://supabase.com)

2. Create the following table in your Supabase database:
   ```sql
   CREATE TABLE todos (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     title TEXT NOT NULL,
     done BOOLEAN DEFAULT false,
     category TEXT,
     color TEXT,
     icon TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
     created_by UUID REFERENCES auth.users(id),
     shared_with TEXT[],
     attachment_url TEXT
   );
   ```

3. Create profiles table:
   ```sql
   CREATE TABLE profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     email TEXT NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
   );
   ```

4. Set up storage bucket for file attachments:
   - Create a bucket named `task-files`
   - Set appropriate policies for authenticated users

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run for web
flutter run -d chrome

# Build for release
flutter build apk
flutter build ios
```

## 📱 Usage

1. **Sign Up/Login**: Create an account or login with existing credentials
2. **Create Tasks**: Tap the + button to add new tasks
3. **Add Attachments**: Use the attachment button when creating tasks
4. **Share Tasks**: Use the share feature to collaborate with others
5. **Offline Mode**: The app works seamlessly offline - changes sync when online

## 🎨 Design System

The app uses a neumorphic design system with:
- **Soft shadows and highlights** for depth
- **Rounded corners** throughout the UI
- **Pastel color palette** for a calm, modern look
- **Consistent spacing** using Material Design guidelines

### Color Palette
- Primary: Soft Blue (`#9CC5FF`)
- Accents: Yellow, Pink, Cyan, Green, Orange, Purple (all in pastel tones)
- Background: Light Gray (`#F7F7FB`)
- Surface: Pure White (`#FCFCFF`)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart best practices
- Maintain the existing architecture patterns
- Add tests for new features
- Update documentation for significant changes
- Ensure offline functionality works for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Backend powered by [Supabase](https://supabase.com/)
- Icons from Material Design Icons
- Inspired by neumorphic design principles

---

**Note**: This app demonstrates modern Flutter development practices including offline-first architecture, real-time synchronization, and collaborative features. It's an excellent example of building production-ready mobile applications with Flutter and Supabase.

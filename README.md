# Garage Service Platform

A comprehensive mobile application platform connecting customers with nearby garage services, built with Flutter frontend and Spring Boot backend.

## Features

### Customer Features
- **User Registration & Authentication**: Secure signup and login system
- **Location-Based Garage Discovery**: Find nearby garages using GPS location
- **Service Browsing**: View available services with prices and descriptions
- **Service Requests**: Request specific services from garages
- **Request Tracking**: Monitor the status of service requests
- **Real-time Updates**: Get notifications when garages respond to requests

### Garage Owner Features
- **Garage Registration**: Set up garage profile with location and details
- **Service Management**: Add, edit, and manage offered services
- **Request Management**: Receive and respond to customer service requests
- **Status Updates**: Update request status (accepted, in-progress, completed)
- **Customer Communication**: Send estimated arrival times and responses

## Technology Stack

### Backend (Spring Boot)
- **Framework**: Spring Boot 3.2.0
- **Security**: Spring Security with JWT authentication
- **Database**: H2 (development), easily configurable for PostgreSQL/MySQL
- **API**: RESTful API with comprehensive endpoints
- **Validation**: Bean validation for data integrity

### Frontend (Flutter)
- **Framework**: Flutter with Dart
- **State Management**: Provider pattern
- **HTTP Client**: HTTP package for API communication
- **Location Services**: Geolocator for GPS functionality
- **Maps Integration**: Google Maps Flutter plugin
- **Secure Storage**: Flutter Secure Storage for token management

## Project Structure

```
garage-service-platform/
├── backend/                    # Spring Boot backend
│   ├── src/main/java/com/garageservice/
│   │   ├── controller/        # REST controllers
│   │   ├── model/            # JPA entities
│   │   ├── repository/       # Data repositories
│   │   ├── dto/              # Data transfer objects
│   │   ├── security/         # Security configuration
│   │   └── service/          # Business logic services
│   └── src/main/resources/
│       └── application.properties
├── flutter_app/              # Flutter mobile app
│   ├── lib/
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management
│   │   ├── screens/          # UI screens
│   │   └── services/         # API services
│   └── pubspec.yaml
└── README.md
```

## API Endpoints

### Authentication
- `POST /api/auth/signin` - User login
- `POST /api/auth/signup` - User registration

### Garages
- `GET /api/garages/nearby` - Find nearby garages
- `POST /api/garages` - Create garage (garage owners)
- `GET /api/garages/my-garage` - Get own garage
- `GET /api/garages/{id}/services` - Get garage services

### Services
- `POST /api/services` - Add service (garage owners)
- `GET /api/services/my-services` - Get own services
- `DELETE /api/services/{id}` - Delete service

### Service Requests
- `POST /api/service-requests` - Create service request (customers)
- `GET /api/service-requests/my-requests` - Get customer requests
- `GET /api/service-requests/garage-requests` - Get garage requests
- `PUT /api/service-requests/{id}/respond` - Respond to request (garage owners)

## Setup Instructions

### Backend Setup

1. **Prerequisites**
   - Java 17 or higher
   - Maven 3.6+

2. **Run the Backend**
   ```bash
   cd backend
   mvn spring-boot:run
   ```

3. **Database**
   - H2 in-memory database (development)
   - Access H2 console: http://localhost:8080/h2-console
   - JDBC URL: `jdbc:h2:mem:testdb`
   - Username: `sa`, Password: `password`

### Frontend Setup

1. **Prerequisites**
   - Flutter SDK 3.0+
   - Android Studio / VS Code
   - Android/iOS development setup

2. **Install Dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

3. **Configure Google Maps**
   - Get Google Maps API key
   - Add to `android/app/src/main/AndroidManifest.xml`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual key

4. **Run the App**
   ```bash
   flutter run
   ```

## Configuration

### Backend Configuration
Edit `backend/src/main/resources/application.properties`:

```properties
# Database Configuration
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.username=sa
spring.datasource.password=password

# JWT Configuration
app.jwtSecret=mySecretKey
app.jwtExpirationMs=86400000

# Server Configuration
server.port=8080
```

#### Firebase Cloud Messaging (Server)
To enable server-side push notifications, provide your Firebase Admin SDK service account credentials to the backend.

Options:
- File path:
   - Set `fcm.serviceAccountPath` to an absolute/relative path to the JSON file
   - Or package the JSON on the classpath and use `fcm.serviceAccountPath=classpath:firebase-service-account.json`
- Base64:
   - Set `fcm.serviceAccountBase64` to the Base64-encoded contents of the JSON

PowerShell example to produce Base64 from a file:

```powershell
$bytes = [IO.File]::ReadAllBytes('C:\secrets\firebase-service-account.json')
$b64 = [Convert]::ToBase64String($bytes)
Write-Output $b64
```

Then either paste it into `application.properties` or, preferably, provide it via an environment variable and start the app normally (no extra arguments needed, properties are bound from env):

```powershell
$env:FCM_SERVICEACCOUNTBASE64 = $b64
mvn -f backend\pom.xml spring-boot:run
```

Dotenv option (local convenience on Windows):
- Create `backend/.env` (auto-loaded by spring-dotenv) with either:
   - FCM_SERVICEACCOUNTBASE64=... (Base64 string)  ← recommended
   - or FCM_SERVICEACCOUNTPATH=C:\path\to\service-account.json
   - optional: SPRING_PROFILES_ACTIVE=dev
- Start the backend as usual; no script needed:
   - `mvn -f backend\pom.xml spring-boot:run`

Note: The PowerShell runner at `backend/scripts/run-with-dotenv.ps1` is now optional for local use and not required when using spring-dotenv. You can keep it for convenience or ignore it and rely solely on `.env`/environment variables.

Verification:
1. Start the backend with credentials configured
2. Log into the mobile app so it registers your device token
3. Call `POST /api/notifications/test-push` or use the in-app test dialog; you should receive a notification
4. For custom channel/sound, call `POST /api/notifications/test-push-custom` with JSON body:
    `{ "title":"Hi", "message":"Custom", "channelId":"garage_service_urgent", "sound":"urgent" }`


### Frontend Configuration
Edit `flutter_app/lib/services/api_service.dart`:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:8080/api';

// For iOS Simulator
// static const String baseUrl = 'http://localhost:8080/api';

// For Physical Device
// static const String baseUrl = 'http://YOUR_IP_ADDRESS:8080/api';
```

## User Flows

### Customer Flow
1. Register/Login as Customer
2. Allow location permissions
3. View nearby garages on map/list
4. Browse garage services
5. Request specific service
6. Track request status
7. Receive garage responses

### Garage Owner Flow
1. Register/Login as Garage Owner
2. Set up garage profile with location
3. Add services with prices
4. Receive customer requests
5. Accept/reject requests
6. Provide estimated arrival times
7. Update request status

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-based Access**: Different permissions for customers and garage owners
- **Password Encryption**: BCrypt password hashing
- **CORS Configuration**: Proper cross-origin resource sharing setup
- **Input Validation**: Comprehensive validation on all endpoints

## Testing

### Backend Testing
```bash
cd backend
mvn test
```

### Frontend Testing
```bash
cd flutter_app
flutter test
```

## Deployment

### Backend Deployment
1. Build JAR file: `mvn clean package`
2. Deploy to cloud platform (AWS, Heroku, etc.)
3. Configure production database
4. Set environment variables for JWT secret

### Frontend Deployment
1. Build APK: `flutter build apk`
2. Build iOS: `flutter build ios`
3. Deploy to app stores

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team

## Future Enhancements

- Real-time chat between customers and garages
- Payment integration
- Rating and review system
- Push notifications
- Advanced search and filtering
- Multi-language support
- Garage analytics dashboard

## Environment configuration for Flutter (frontend)

For flexible per-environment settings without committing secrets, pass environment values at run/build time.

Option A: Individual defines
- Use `--dart-define` flags for single values (already supported by the app via `String.fromEnvironment`).
- Examples (Windows PowerShell):
   - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api`
   - `flutter run -d chrome --dart-define=GOOGLE_DIRECTIONS_API_KEY=YOUR_KEY`

Option B: JSON file (bulk)
- Place JSON files in `flutter_app` (these are git-ignored):
   - `.env.dev.json`
   - `.env.prod.json`
- Example contents:
   - `.env.dev.json`
      ```json
      {
         "API_BASE_URL": "http://10.0.2.2:8080/api",
         "GOOGLE_DIRECTIONS_API_KEY": "REPLACE_WITH_DEV_DIRECTIONS_KEY",
         "FIREBASE_VAPID_KEY": "REPLACE_WITH_DEV_VAPID_IF_USED"
      }
      ```
   - `.env.prod.json`
      ```json
      {
         "API_BASE_URL": "https://garage-service-platform.onrender.com/api",
         "GOOGLE_DIRECTIONS_API_KEY": "REPLACE_WITH_PROD_DIRECTIONS_KEY",
         "FIREBASE_VAPID_KEY": "REPLACE_WITH_PROD_VAPID_IF_USED"
      }
      ```
- Run/build with the file (Windows PowerShell):
   - `flutter run -d chrome --dart-define-from-file=.env.dev.json`
   - `flutter build apk --dart-define-from-file=.env.prod.json`

Notes
- Native Maps keys in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` are left as-is and used automatically by the app.
- On web, the Google Maps JS loader reads a meta tag named `google_maps_api_key` in `flutter_app/web/index.html`. Keep real keys out of git; inject the meta locally or via CI/CD.
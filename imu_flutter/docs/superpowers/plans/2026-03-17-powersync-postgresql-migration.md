# PowerSync + PostgreSQL Migration - Vertical Slices

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan.

**Goal:** Migrate from PocketBase to PowerSync + PostgreSQL with custom JWT auth for offline-first mobile app.

**Methodology:** Elephant Carpaccio v2.0 - Vertical Slicing
- Each slice: 2-4 hours max
- Complete vertical cut (UI → API → Data)
- Observable, testable, reversible
- More valuable than previous slice

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│              Target: PowerSync + PostgreSQL                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Flutter App ──→ PowerSync (SQLite) ──→ PostgreSQL         │
│                         │                                   │
│                         └── Custom JWT Auth                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Complete PocketBase Removal (Foundation)

> **Goal:** Remove all PocketBase dependencies before adding PowerSync

### Slice 0.1: Remove PocketBase Package
**Time:** 30 min | **Value:** Clean dependency tree

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove pocketbase from pubspec.yaml**
```yaml
# REMOVE this line:
# pocketbase: ^0.17.0
```

- [ ] **Step 2: Run flutter pub get**
```bash
cd mobile/imu_flutter && flutter pub get
```

- [ ] **Step 3: Commit**
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(phase0): remove pocketbase package dependency"
```

---

### Slice 0.2: Delete PocketBase Client
**Time:** 15 min | **Value:** Remove dead code

**Files:**
- Delete: `lib/services/api/pocketbase_client.dart`
- Delete: `lib/services/api/token_manager.dart`

- [ ] **Step 1: Delete PocketBase client files**
```bash
rm lib/services/api/pocketbase_client.dart
rm lib/services/api/token_manager.dart
```

- [ ] **Step 2: Commit**
```bash
git add -A
git commit -m "chore(phase0): delete pocketbase client and token manager"
```

---

### Slice 0.3: Update App Config
**Time:** 30 min | **Value:** New config structure

**Files:**
- Modify: `lib/core/config/app_config.dart`
- Modify: `.env.dev`

- [ ] **Step 1: Update app_config.dart**
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration for PowerSync + PostgreSQL
class AppConfig {
  AppConfig._();

  // PowerSync
  static late String _powerSyncUrl;

  // PostgreSQL API
  static late String _postgresApiUrl;

  // JWT Auth
  static late String _jwtSecret;
  static late int _jwtExpiryHours;

  // General
  static late String _appName;
  static late bool _debugMode;
  static late String _logLevel;
  static String _environment = 'dev';

  static Future<void> initialize({String environment = 'dev'}) async {
    _environment = environment;
    final envFile = environment == 'prod' ? '.env.prod' : '.env.dev';

    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      debugPrint('Warning: Could not load $envFile: $e');
    }

    _powerSyncUrl = dotenv.env['POWERSYNC_URL'] ?? '';
    _postgresApiUrl = dotenv.env['POSTGRES_API_URL'] ?? 'http://localhost:3000/api';
    _jwtSecret = dotenv.env['JWT_SECRET'] ?? 'dev-secret';
    _jwtExpiryHours = int.tryParse(dotenv.env['JWT_EXPIRY_HOURS'] ?? '24') ?? 24;
    _appName = dotenv.env['APP_NAME'] ?? 'IMU';
    _debugMode = dotenv.env['DEBUG_MODE'] == 'true';
    _logLevel = dotenv.env['LOG_LEVEL'] ?? 'info';

    debugPrint('AppConfig initialized:');
    debugPrint('  Environment: $environment');
    debugPrint('  PowerSync URL: $_powerSyncUrl');
    debugPrint('  PostgreSQL API: $_postgresApiUrl');
  }

  // Getters
  static String get powerSyncUrl => _powerSyncUrl;
  static String get postgresApiUrl => _postgresApiUrl;
  static String get jwtSecret => _jwtSecret;
  static int get jwtExpiryHours => _jwtExpiryHours;
  static String get appName => _appName;
  static bool get debugMode => _debugMode;
  static String get logLevel => _logLevel;
  static String get environment => _environment;
  static bool get isProduction => !_debugMode;
  static bool get isDevelopment => _debugMode;
}
```

- [ ] **Step 2: Update .env.dev**
```env
# PowerSync Configuration
POWERSYNC_URL=https://your-instance.powersync.co

# PostgreSQL API
POSTGRES_API_URL=http://localhost:3000/api

# JWT Auth
JWT_SECRET=dev-jwt-secret-key
JWT_EXPIRY_HOURS=24

# App
APP_NAME=IMU Dev
DEBUG_MODE=true
LOG_LEVEL=debug
```

- [ ] **Step 3: Commit**
```bash
git add lib/core/config/app_config.dart .env.dev
git commit -m "feat(phase0): update app config for powersync and postgresql"
```

---

### Slice 0.4: Stub Auth Service
**Time:** 1 hour | **Value:** App compiles without PocketBase

**Files:**
- Modify: `lib/services/auth/auth_service.dart`

- [ ] **Step 1: Create stub auth service**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';

/// Stub user model (will be replaced with JWT user)
class StubUser {
  final String id;
  final String email;
  final String name;

  StubUser({required this.id, required this.email, required this.name});
}

/// Stub auth service (placeholder until JWT auth is implemented)
class AuthService {
  StubUser? _currentUser;

  Future<void> initialize() async {
    // TODO: Implement JWT auth
  }

  Future<StubUser?> login(String email, String password) async {
    // TODO: Implement login
    throw UnimplementedError('JWT auth not yet implemented');
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  bool get isAuthenticated => _currentUser != null;
  StubUser? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;
}

/// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final StubUser? user;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.user,
  });

  factory AuthState.initial() => const AuthState(
    isAuthenticated: false,
    isLoading: false,
  );

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    StubUser? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final isAuth = _authService.isAuthenticated;
    state = state.copyWith(
      isAuthenticated: isAuth,
      user: _authService.currentUser,
      isLoading: false,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.initial();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  notifier.checkAuthStatus();
  return notifier;
});
```

- [ ] **Step 2: Commit**
```bash
git add lib/services/auth/auth_service.dart
git commit -m "feat(phase0): create stub auth service replacing pocketbase"
```

---

### Slice 0.5: Update Main.dart
**Time:** 30 min | **Value:** App initializes without PocketBase

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Remove PocketBase initialization**
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'services/location/geolocation_service.dart';
import 'services/connectivity_service.dart';
import 'core/utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  await AppConfig.initialize(environment: 'dev');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  await _initializeServices();

  // Run app
  runApp(const ProviderScope(child: IMUApp()));
}

Future<void> _initializeServices() async {
  // Initialize connectivity
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Pre-warm geolocation (mobile only)
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final geoService = GeolocationService();
        final enabled = await geoService.isLocationServiceEnabled();
        if (enabled) {
          await geoService.requestPermission();
        }
      }
    } catch (e) {
      debugPrint('Geolocation init skipped: $e');
    }
  }

  debugPrint('All services initialized (PowerSync pending)');
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/main.dart
git commit -m "feat(phase0): remove pocketbase from main.dart initialization"
```

---

### Slice 0.6: Clean PocketBase Imports
**Time:** 1 hour | **Value:** No PocketBase references remain

**Files:**
- Multiple files with PocketBase imports

- [ ] **Step 1: Find all PocketBase references**
```bash
cd mobile/imu_flutter
grep -r "pocketbase\|PocketBase" lib/ --include="*.dart" -l
```

- [ ] **Step 2: Remove imports and references**

For each file found:
1. Remove `import 'package:pocketbase/pocketbase.dart';`
2. Remove `import 'package:imu_flutter/services/api/pocketbase_client.dart';`
3. Comment out or stub PocketBase-related code

- [ ] **Step 3: Run flutter analyze**
```bash
flutter analyze
```

- [ ] **Step 4: Fix any remaining errors**

- [ ] **Step 5: Commit**
```bash
git add -A
git commit -m "chore(phase0): remove all pocketbase imports and references"
```

---

### Slice 0.7: Verify App Runs
**Time:** 30 min | **Value:** Confirmed clean state

- [ ] **Step 1: Run flutter pub get**
```bash
flutter pub get
```

- [ ] **Step 2: Run flutter analyze**
```bash
flutter analyze
```
Expected: 0 errors

- [ ] **Step 3: Run app**
```bash
flutter run -d chrome
```
Expected: App launches, login page shows (auth will fail - expected)

- [ ] **Step 4: Commit verification**
```bash
git add -A
git commit -m "chore(phase0): verify app runs without pocketbase"
```

---

## Phase 0 Progress

| Slice | Description | Status | Time |
|-------|-------------|--------|------|
| 0.1 | Remove PocketBase package | ⬜ | 30m |
| 0.2 | Delete PocketBase client | ⬜ | 15m |
| 0.3 | Update App Config | ⬜ | 30m |
| 0.4 | Stub Auth Service | ⬜ | 1h |
| 0.5 | Update Main.dart | ⬜ | 30m |
| 0.6 | Clean PocketBase imports | ⬜ | 1h |
| 0.7 | Verify App Runs | ⬜ | 30m |

**Phase 0 Total:** ~4 hours

---

## Phase 1: Custom JWT Authentication

### Slice 1.1: Create JWT Auth Service
**Time:** 2 hours | **Value:** Working auth with JWT tokens

**Files:**
- Create: `lib/services/auth/jwt_auth_service.dart`

- [ ] **Step 1: Create JWT auth service**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

class JwtUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? expiresAt;

  JwtUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.expiresAt,
  });

  factory JwtUser.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return JwtUser(
      id: decoded['sub'] ?? '',
      email: decoded['email'] ?? '',
      firstName: decoded['first_name'] ?? '',
      lastName: decoded['last_name'] ?? '',
      role: decoded['role'] ?? 'field_agent',
      expiresAt: decoded['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000)
          : null,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => !isExpired;
}

class JwtAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  JwtUser? _currentUser;

  JwtAuthService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.postgresApiUrl)),
        _storage = storage ?? const FlutterSecureStorage();

  String? get accessToken => _accessToken;
  JwtUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _currentUser?.isValid == true;

  Future<void> initialize() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    if (_accessToken != null) {
      _currentUser = JwtUser.fromToken(_accessToken!);
      if (_currentUser?.isExpired == true && _refreshToken != null) {
        await refreshTokens();
      }
    }
    logDebug('JwtAuthService initialized, authenticated: $isAuthenticated');
  }

  Future<JwtUser> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      _currentUser = JwtUser.fromToken(_accessToken!);

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);

      logDebug('Login successful for ${_currentUser!.id}');
      return _currentUser!;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    logDebug('Logout successful');
  }

  Future<void> refreshTokens() async {
    if (_refreshToken == null) throw Exception('No refresh token');
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': _refreshToken,
      });
      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      _currentUser = JwtUser.fromToken(_accessToken!);
      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
    } catch (e) {
      await logout();
      rethrow;
    }
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/services/auth/jwt_auth_service.dart
git commit -m "feat(phase1): add JWT authentication service"
```

---

### Slice 1.2: Integrate JWT Auth into Auth Service
**Time:** 1 hour | **Value:** Complete auth flow

**Files:**
- Modify: `lib/services/auth/auth_service.dart`

- [ ] **Step 1: Update auth_service.dart to use JWT**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'jwt_auth_service.dart';

export 'jwt_auth_service.dart' show JwtUser;

class AuthService {
  final JwtAuthService _jwtAuth;

  AuthService({JwtAuthService? jwtAuth}) : _jwtAuth = jwtAuth ?? JwtAuthService();

  Future<void> initialize() => _jwtAuth.initialize();
  Future<JwtUser> login(String email, String password) =>
      _jwtAuth.login(email: email, password: password);
  Future<void> logout() => _jwtAuth.logout();
  Future<void> refreshToken() => _jwtAuth.refreshTokens();

  bool get isAuthenticated => _jwtAuth.isAuthenticated;
  JwtUser? get currentUser => _jwtAuth.currentUser;
  String? get currentUserId => _jwtAuth.currentUser?.id;
  String? get currentUserEmail => _jwtAuth.currentUser?.email;
  String? get currentUserName => _jwtAuth.currentUser?.fullName;
}

final jwtAuthProvider = Provider<JwtAuthService>((ref) => JwtAuthService());
final authServiceProvider = Provider<AuthService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return AuthService(jwtAuth: jwtAuth);
});

// AuthNotifier and AuthState remain the same, but use JwtUser
```

- [ ] **Step 2: Commit**
```bash
git add lib/services/auth/auth_service.dart
git commit -m "feat(phase1): integrate JWT auth into auth service"
```

---

### Slice 1.3: Test Auth Flow
**Time:** 1 hour | **Value:** Verified auth works

- [ ] **Step 1: Run app and test login page shows**
- [ ] **Step 2: Verify token storage works**
- [ ] **Step 3: Verify session restoration on app restart**
- [ ] **Step 4: Commit**
```bash
git add -A
git commit -m "test(phase1): verify JWT auth flow works"
```

---

## Phase 1 Progress

| Slice | Description | Status | Time |
|-------|-------------|--------|------|
| 1.1 | Create JWT Auth Service | ⬜ | 2h |
| 1.2 | Integrate into Auth Service | ⬜ | 1h |
| 1.3 | Test Auth Flow | ⬜ | 1h |

**Phase 1 Total:** ~4 hours

---

## Phase 2: PowerSync Integration

### Slice 2.1: Create PowerSync Connector
**Time:** 2 hours | **Value:** PowerSync connects to backend

**Files:**
- Create: `lib/services/sync/powersync_connector.dart`

- [ ] **Step 1: Create connector**

```dart
import 'package:dio/dio.dart';
import 'package:powersync/powersync.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../auth/jwt_auth_service.dart';

class PowerSyncConnector {
  final Dio _dio;
  final JwtAuthService _authService;

  PowerSyncConnector({JwtAuthService? authService, Dio? dio})
      : _authService = authService ?? JwtAuthService(),
        _dio = dio ?? Dio();

  Future<String?> fetchCredentials() async {
    final token = _authService.accessToken;
    if (token == null) {
      logDebug('No access token for PowerSync');
      return null;
    }
    return token;
  }

  Future<void> uploadData(PowerSyncDatabase database) async {
    final token = _authService.accessToken;
    if (token == null) return;

    final batch = await database.getCrudBatch();
    if (batch == null) return;

    try {
      await _dio.post(
        '${Config.postgresApiUrl}/upload',
        data: {'operations': batch.crud.map((op) => {
          'table': op.table,
          'op': op.op,
          'id': op.id,
          'data': op.opData,
        }).toList()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await batch.complete();
      logDebug('Upload completed');
    } catch (e) {
      logError('Upload failed', e);
      rethrow;
    }
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/services/sync/powersync_connector.dart
git commit -m "feat(phase2): add PowerSync PostgreSQL connector"
```

---

### Slice 2.2: Update PowerSync Service
**Time:** 2 hours | **Value:** Full PowerSync integration

**Files:**
- Modify: `lib/services/sync/powersync_service.dart`

- [ ] **Step 1: Update PowerSync service with connector**
- [ ] **Step 2: Initialize in main.dart**
- [ ] **Step 3: Commit**
```bash
git add lib/services/sync/powersync_service.dart lib/main.dart
git commit -m "feat(phase2): integrate PowerSync with connector"
```

---

### Slice 2.3: Update Client Repository
**Time:** 2 hours | **Value:** Clients work with PowerSync

**Files:**
- Modify: `lib/features/clients/data/repositories/client_repository.dart`

- [ ] **Step 1: Replace PocketBase with PowerSync queries**
- [ ] **Step 2: Test CRUD operations**
- [ ] **Step 3: Commit**
```bash
git add lib/features/clients/
git commit -m "feat(phase2): update client repository for PowerSync"
```

---

### Slice 2.4: Update Touchpoint Repository
**Time:** 2 hours | **Value:** Touchpoints work with PowerSync

**Files:**
- Modify: `lib/features/touchpoints/data/repositories/touchpoint_repository.dart`

- [ ] **Step 1: Replace with PowerSync queries**
- [ ] **Step 2: Test CRUD operations**
- [ ] **Step 3: Commit**
```bash
git add lib/features/touchpoints/
git commit -m "feat(phase2): update touchpoint repository for PowerSync"
```

---

### Slice 2.5: Update Itinerary Repository
**Time:** 1 hour | **Value:** Itineraries work with PowerSync

**Files:**
- Modify: `lib/features/itineraries/data/repositories/itinerary_repository.dart`

- [ ] **Step 1: Replace with PowerSync queries**
- [ ] **Step 2: Test CRUD operations**
- [ ] **Step 3: Commit**
```bash
git add lib/features/itineraries/
git commit -m "feat(phase2): update itinerary repository for PowerSync"
```

---

## Phase 2 Progress

| Slice | Description | Status | Time |
|-------|-------------|--------|------|
| 2.1 | Create PowerSync Connector | ⬜ | 2h |
| 2.2 | Update PowerSync Service | ⬜ | 2h |
| 2.3 | Update Client Repository | ⬜ | 2h |
| 2.4 | Update Touchpoint Repository | ⬜ | 2h |
| 2.5 | Update Itinerary Repository | ⬜ | 1h |

**Phase 2 Total:** ~9 hours

---

## Phase 3: Sync & Testing

### Slice 3.1: Implement Sync Service
**Time:** 2 hours | **Value:** Full offline sync

**Files:**
- Modify: `lib/services/sync/sync_service.dart`

- [ ] **Step 1: Rewrite sync service for PowerSync**
- [ ] **Step 2: Test offline/online transitions**
- [ ] **Step 3: Commit**
```bash
git add lib/services/sync/sync_service.dart
git commit -m "feat(phase3): implement PowerSync sync service"
```

---

### Slice 3.2: Test Offline Sync
**Time:** 2 hours | **Value:** Verified offline works

- [ ] **Step 1: Create data offline**
- [ ] **Step 2: Verify persists after app restart**
- [ ] **Step 3: Go online and verify sync**
- [ ] **Step 4: Commit**
```bash
git add -A
git commit -m "test(phase3): verify offline sync works"
```

---

### Slice 3.3: Final Cleanup
**Time:** 1 hour | **Value:** Clean codebase

- [ ] **Step 1: Remove any remaining PocketBase references**
- [ ] **Step 2: Run flutter analyze**
- [ ] **Step 3: Fix all issues**
- [ ] **Step 4: Commit**
```bash
git add -A
git commit -m "chore(phase3): final cleanup and verification"
```

---

## Phase 3 Progress

| Slice | Description | Status | Time |
|-------|-------------|--------|------|
| 3.1 | Implement Sync Service | ⬜ | 2h |
| 3.2 | Test Offline Sync | ⬜ | 2h |
| 3.3 | Final Cleanup | ⬜ | 1h |

**Phase 3 Total:** ~5 hours

---

## Total Migration Summary

| Phase | Description | Slices | Time |
|-------|-------------|--------|------|
| **0** | PocketBase Removal | 7 | 4h |
| **1** | JWT Authentication | 3 | 4h |
| **2** | PowerSync Integration | 5 | 9h |
| **3** | Sync & Testing | 3 | 5h |
| **TOTAL** | | **18** | **~22h** |

---

## PostgreSQL Schema (Reference)

```sql
-- Run in your PostgreSQL database

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role TEXT DEFAULT 'field_agent',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    client_type TEXT DEFAULT 'POTENTIAL',
    caravan_id UUID REFERENCES users(id),
    is_starred BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE touchpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id),
    caravan_id UUID REFERENCES users(id),
    touchpoint_number INTEGER NOT NULL,
    type TEXT NOT NULL,
    date DATE NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caravan_id UUID REFERENCES users(id),
    client_id UUID REFERENCES clients(id),
    scheduled_date DATE NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Gap Analysis & Additions

### Critical Missing Items Identified

| # | Gap | Severity | Status |
|---|-----|----------|--------|
| G1 | Backend API implementation | **CRITICAL** | Missing |
| G2 | PowerSync cloud setup | **CRITICAL** | Missing |
| G3 | Dependencies not in pubspec.yaml | HIGH | Missing |
| G4 | Logger utility doesn't exist | HIGH | Missing |
| G5 | PIN/Biometric auth integration | HIGH | Missing |
| G6 | Hive to PowerSync data migration | MEDIUM | Missing |
| G7 | PowerSync local schema | MEDIUM | Missing |
| G8 | Error handling & retry strategies | MEDIUM | Missing |
| G9 | Testing strategy | MEDIUM | Missing |
| G10 | Environment configs (prod/staging) | LOW | Missing |

---

## Phase 0.5: Backend API Setup (NEW - CRITICAL)

> **Goal:** Create minimal Node.js/Hono API for JWT auth and PowerSync upload endpoint

### Slice 0.5.1: Initialize Backend Project
**Time:** 30 min | **Value:** Backend foundation

**Files:**
- Create: `backend/package.json`
- Create: `backend/src/index.ts`
- Create: `backend/.env`

- [ ] **Step 1: Create backend directory**
```bash
mkdir -p backend/src
cd backend
pnpm init
pnpm add hono @hono/node-server pg bcryptjs jsonwebtoken dotenv zod
pnpm add -D typescript @types/node @types/pg @types/bcryptjs @types/jsonwebtoken tsx
```

- [ ] **Step 2: Create package.json scripts**
```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

- [ ] **Step 3: Create .env**
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/imu
JWT_SECRET=your-256-bit-secret-key-here
JWT_EXPIRY_HOURS=24
PORT=3000
```

- [ ] **Step 4: Commit**
```bash
git add backend/
git commit -m "feat(backend): initialize Hono API project"
```

---

### Slice 0.5.2: Create Auth Endpoints
**Time:** 2 hours | **Value:** Working JWT authentication

**Files:**
- Create: `backend/src/routes/auth.ts`
- Create: `backend/src/middleware/auth.ts`

- [ ] **Step 1: Create auth routes**
```typescript
// backend/src/routes/auth.ts
import { Hono } from 'hono';
import { sign, verify } from 'jsonwebtoken';
import { hash, compare } from 'bcryptjs';
import { Pool } from 'pg';

const auth = new Hono();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

auth.post('/login', async (c) => {
  const { email, password } = await c.req.json();

  const result = await pool.query(
    'SELECT id, email, password_hash, first_name, last_name, role FROM users WHERE email = $1',
    [email]
  );

  if (result.rows.length === 0) {
    return c.json({ message: 'Invalid credentials' }, 401);
  }

  const user = result.rows[0];
  const valid = await compare(password, user.password_hash);

  if (!valid) {
    return c.json({ message: 'Invalid credentials' }, 401);
  }

  const accessToken = sign(
    { sub: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: `${process.env.JWT_EXPIRY_HOURS || 24}h` }
  );

  const refreshToken = sign(
    { sub: user.id, type: 'refresh' },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );

  return c.json({ access_token: accessToken, refresh_token: refreshToken });
});

auth.post('/refresh', async (c) => {
  const { refresh_token } = await c.req.json();

  try {
    const decoded = verify(refresh_token, process.env.JWT_SECRET!) as { sub: string };

    const result = await pool.query(
      'SELECT id, email, first_name, last_name, role FROM users WHERE id = $1',
      [decoded.sub]
    );

    if (result.rows.length === 0) {
      return c.json({ message: 'User not found' }, 401);
    }

    const user = result.rows[0];
    const accessToken = sign(
      { sub: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: `${process.env.JWT_EXPIRY_HOURS || 24}h` }
    );

    return c.json({ access_token: accessToken });
  } catch {
    return c.json({ message: 'Invalid refresh token' }, 401);
  }
});

export default auth;
```

- [ ] **Step 2: Create auth middleware**
```typescript
// backend/src/middleware/auth.ts
import { verify } from 'jsonwebtoken';

export const authMiddleware = async (c: any, next: any) => {
  const authHeader = c.req.header('Authorization');

  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ message: 'Unauthorized' }, 401);
  }

  const token = authHeader.slice(7);

  try {
    const decoded = verify(token, process.env.JWT_SECRET!);
    c.set('user', decoded);
    await next();
  } catch {
    return c.json({ message: 'Invalid token' }, 401);
  }
};
```

- [ ] **Step 3: Commit**
```bash
git add backend/src/routes backend/src/middleware
git commit -m "feat(backend): add JWT auth endpoints"
```

---

### Slice 0.5.3: Create Upload Endpoint
**Time:** 1 hour | **Value:** PowerSync data upload

**Files:**
- Create: `backend/src/routes/upload.ts`

- [ ] **Step 1: Create upload route**
```typescript
// backend/src/routes/upload.ts
import { Hono } from 'hono';
import { Pool } from 'pg';
import { authMiddleware } from '../middleware/auth';

const upload = new Hono();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

upload.use('/*', authMiddleware);

upload.post('/', async (c) => {
  const { operations } = await c.req.json();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    for (const op of operations) {
      const { table, op: operation, id, data } = op;

      if (operation === 'PUT') {
        const columns = Object.keys(data).join(', ');
        const values = Object.values(data);
        const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

        await client.query(
          `INSERT INTO ${table} (id, ${columns}) VALUES ($1, ${placeholders})
           ON CONFLICT (id) DO UPDATE SET ${columns.split(', ').map((c, i) => `${c} = $${i + 2}`).join(', ')}`,
          [id, ...values]
        );
      } else if (operation === 'DELETE') {
        await client.query(`DELETE FROM ${table} WHERE id = $1`, [id]);
      }
    }

    await client.query('COMMIT');
    return c.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Upload error:', error);
    return c.json({ message: 'Upload failed' }, 500);
  } finally {
    client.release();
  }
});

export default upload;
```

- [ ] **Step 2: Commit**
```bash
git add backend/src/routes/upload.ts
git commit -m "feat(backend): add PowerSync upload endpoint"
```

---

### Slice 0.5.4: Main API Entry Point
**Time:** 30 min | **Value:** Complete API server

**Files:**
- Create: `backend/src/index.ts`

- [ ] **Step 1: Create main entry**
```typescript
// backend/src/index.ts
import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { cors } from 'hono/cors';
import 'dotenv/config';

import authRoutes from './routes/auth';
import uploadRoutes from './routes/upload';

const app = new Hono();

// CORS for mobile app
app.use('*', cors({
  origin: ['http://localhost:*', 'capacitor://localhost', 'ionic://localhost'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check
app.get('/api/health', (c) => c.json({ status: 'ok', timestamp: new Date().toISOString() }));

// Routes
app.route('/api/auth', authRoutes);
app.route('/api/upload', uploadRoutes);

const port = parseInt(process.env.PORT || '3000');
console.log(`🚀 Server running on port ${port}`);

serve({ fetch: app.fetch, port });
```

- [ ] **Step 2: Test API**
```bash
cd backend
pnpm dev
curl http://localhost:3000/api/health
```

- [ ] **Step 3: Commit**
```bash
git add backend/src/index.ts
git commit -m "feat(backend): complete API server with health check"
```

---

## Phase 0.5 Progress

| Slice | Description | Status | Time |
|-------|-------------|--------|------|
| 0.5.1 | Initialize Backend | ⬜ | 30m |
| 0.5.2 | Auth Endpoints | ⬜ | 2h |
| 0.5.3 | Upload Endpoint | ⬜ | 1h |
| 0.5.4 | Main Entry Point | ⬜ | 30m |

**Phase 0.5 Total:** ~4 hours

---

## Additional Fixes to Existing Phases

### Fix: Add Missing Dependencies (Phase 0)

Add to `pubspec.yaml` before Slice 0.1:
```yaml
dependencies:
  dio: ^5.4.0
  jwt_decoder: ^2.0.1
```

### Fix: Create Logger Utility (Phase 0 - Add after Slice 0.3)

**File:** `lib/core/utils/logger.dart`
```dart
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

void logDebug(String message) {
  if (AppConfig.debugMode) {
    debugPrint('[DEBUG] $message');
  }
}

void logInfo(String message) {
  debugPrint('[INFO] $message');
}

void logWarning(String message) {
  debugPrint('[WARN] $message');
}

void logError(String message, [dynamic error]) {
  debugPrint('[ERROR] $message ${error ?? ''}');
}
```

### Fix: PowerSync Local Schema (Phase 2 - Add before Slice 2.1)

**File:** `lib/services/sync/powersync_schema.dart`
```dart
import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('clients', [
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('phone'),
    Column.text('email'),
    Column.text('client_type'),
    Column.text('caravan_id'),
    Column.integer('is_starred'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('touchpoints', [
    Column.text('client_id'),
    Column.text('caravan_id'),
    Column.integer('touchpoint_number'),
    Column.text('type'),
    Column.text('date'),
    Column.text('reason'),
    Column.text('photo_path'),
    Column.text('audio_path'),
    Column.text('location_data'),
    Column.text('created_at'),
  ]),
  Table('itineraries', [
    Column.text('caravan_id'),
    Column.text('client_id'),
    Column.text('scheduled_date'),
    Column.text('status'),
    Column.text('notes'),
    Column.text('created_at'),
  ]),
  Table('user_profiles', [
    Column.text('email'),
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('role'),
    Column.text('phone'),
    Column.text('profile_photo_url'),
    Column.text('updated_at'),
  ]),
]);
```

### Fix: PIN/Biometric Integration (Phase 1 - Add Slice 1.4)

**Slice 1.4: Integrate PIN/Biometric with JWT**
**Time:** 1.5 hours | **Value:** Complete auth flow matches existing UX

- [ ] **Step 1:** Keep existing PIN entry UI (`PinEntryPage`, `PinSetupPage`)
- [ ] **Step 2:** Store JWT tokens after successful PIN/biometric auth
- [ ] **Step 3:** Integrate `flutter_secure_storage` for tokens
- [ ] **Step 4:** Keep session timeout (15 min inactivity, 8 hour full)

### Fix: Error Handling & Retry (Phase 3 - Add Slice 3.4)

**Slice 3.4: Implement Retry Strategy**
**Time:** 1 hour | **Value:** Robust offline handling

```dart
// lib/services/sync/sync_retry_service.dart
class SyncRetryService {
  static const maxRetries = 3;
  static const baseDelay = Duration(seconds: 2);

  Future<void> retryUpload(Future<void> Function() uploadFn) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await uploadFn();
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(baseDelay * (i + 1));
      }
    }
  }
}
```

### Fix: Hive to PowerSync Migration (Phase 3 - Add Slice 3.5)

**Slice 3.5: Migrate Existing Hive Data**
**Time:** 1 hour | **Value:** No data loss during migration

- [ ] **Step 1:** Read existing Hive data on first PowerSync init
- [ ] **Step 2:** Insert into PowerSync SQLite
- [ ] **Step 3:** Clear Hive box after successful migration
- [ ] **Step 4:** Set migration flag in shared preferences

---

## PowerSync Cloud Setup Guide

### Prerequisites
1. Create account at https://powersync.co
2. Create new instance

### Configuration Steps

1. **Create PowerSync Instance**
   - Go to dashboard.powersync.co
   - Click "New Instance"
   - Select region closest to your users
   - Note the instance URL (e.g., `https://xyz.powersync.co`)

2. **Configure PostgreSQL Connection**
   ```yaml
   # In PowerSync dashboard
   database:
     host: your-postgres-host.com
     port: 5432
     database: imu
     user: powersync
     password: <your-password>
     ssl: required
   ```

3. **Define Sync Rules**
   ```yaml
   # powersync/sync_rules.yaml
   bucket_definitions:
     by_caravan:
       parameters: SELECT id FROM users WHERE id = token_parameters.user_id
       data:
         - SELECT * FROM clients WHERE caravan_id = bucket.id
         - SELECT * FROM touchpoints WHERE caravan_id = bucket.id
         - SELECT * FROM itineraries WHERE caravan_id = bucket.id
         - SELECT * FROM user_profiles WHERE id = bucket.id
   ```

4. **Get Connection Details**
   - Copy PowerSync URL to `.env.dev`: `POWERSYNC_URL=https://your-instance.powersync.co`

---

## Updated Total Migration Summary

| Phase | Description | Slices | Time |
|-------|-------------|--------|------|
| **0** | PocketBase Removal | 7 | 4h |
| **0.5** | Backend API Setup | 4 | 4h |
| **1** | JWT Authentication | 4 | 5.5h |
| **2** | PowerSync Integration | 5 | 9h |
| **3** | Sync & Testing | 5 | 6h |
| **TOTAL** | | **25** | **~28.5h** |

---

## Environment Configuration

### .env.dev (Development)
```env
POWERSYNC_URL=https://your-dev-instance.powersync.co
POSTGRES_API_URL=http://localhost:3000/api
JWT_SECRET=dev-jwt-secret-key-min-32-chars-long
JWT_EXPIRY_HOURS=24
APP_NAME=IMU Dev
DEBUG_MODE=true
LOG_LEVEL=debug
```

### .env.prod (Production)
```env
POWERSYNC_URL=https://your-prod-instance.powersync.co
POSTGRES_API_URL=https://api.imu-app.com/api
JWT_SECRET=<generate-secure-256-bit-key>
JWT_EXPIRY_HOURS=8
APP_NAME=IMU
DEBUG_MODE=false
LOG_LEVEL=error
```

### .env.staging (Staging)
```env
POWERSYNC_URL=https://your-staging-instance.powersync.co
POSTGRES_API_URL=https://staging-api.imu-app.com/api
JWT_SECRET=<staging-secret-key>
JWT_EXPIRY_HOURS=24
APP_NAME=IMU Staging
DEBUG_MODE=true
LOG_LEVEL=info
```

---

## Documentation Update Checklist

After migration completion:
- [ ] Update `CLAUDE.md` - Remove PocketBase references, add PowerSync/PostgreSQL
- [ ] Update `docs/deep-analysis-on-project.md` - Reflect new architecture
- [ ] Update `master_plan_mobile_tablet.md` - Mark sync as complete
- [ ] Create `backend/README.md` - API documentation
- [ ] Update `.env.example` - New environment variables

---

**Plan complete with gap analysis. Ready to execute when you say proceed.**

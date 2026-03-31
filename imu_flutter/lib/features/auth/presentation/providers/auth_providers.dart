import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/token_manager.dart';

/// Provider for the Dio HTTP client configured for auth API calls.
final authDioProvider = Provider<Dio>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return DioClient.create(tokenManager: tokenManager);
});

/// Provider for the auth interceptor (for dependency injection if needed).
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthInterceptor(tokenManager: tokenManager);
});

/// Provider for the auth remote data source.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(authDioProvider);
  return AuthRemoteDataSourceFactory.create(dio);
});

/// Provider for the token manager.
///
/// This is a singleton instance that manages secure token storage.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});

/// Provider for the auth repository.
///
/// This is the main interface for authentication operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenManager: tokenManager,
  );
});

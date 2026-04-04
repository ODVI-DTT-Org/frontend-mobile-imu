import 'package:flutter/material.dart';

/// Reusable loading state handler with consistent error handling
///
/// Usage:
/// ```dart
/// await SafeLoad.execute(
///   operation: () => loadData(),
///   onError: (error) => showErrorDialog(error),
/// );
/// ```
abstract class SafeLoad {
  /// Execute an operation with consistent error handling
  static Future<T?> execute<T>({
    required Future<T> Function() operation,
    String? loadingMessage,
    Function(T)? onSuccess,
    Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      onError?.call(e, stack);
      debugPrint('[SafeLoad] Error: $e\n$stack');
      return null;
    }
  }

  /// Execute and set loading state with automatic error handling
  static Future<T?> executeWithState<T>({
    required Future<T> Function() operation,
    required void Function(bool loading) setLoading,
    required void Function(T data) setData,
    required void Function(Object error) setError,
    String? loadingMessage,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      setData(result);
      return result;
    } catch (e, stack) {
      debugPrint('[SafeLoad] Error: $e\n$stack');
      setError(e);
      return null;
    } finally {
      setLoading(false);
    }
  }
}

/// Widget for displaying loading state with error handling
class LoadingStateBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final Widget Function(Object? error)? errorBuilder;
  final Widget? loadingWidget;
  final String? errorMessage;

  const LoadingStateBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return errorBuilder?.call(snapshot.error) ??
          _ErrorDisplay(error: snapshot.error!, errorMessage: errorMessage);
    }

    if (snapshot.hasData) {
      return builder(snapshot.data as T);
    }

    return const SizedBox.shrink();
  }
}

class _ErrorDisplay extends StatelessWidget {
  final Object error;
  final String? errorMessage;

  const _ErrorDisplay({required this.error, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? 'An error occurred';
    final errorText = error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to check if snapshot has specific error types
extension AsyncSnapshotExtension<T> on AsyncSnapshot<T> {
  bool get isLoading => connectionState == ConnectionState.waiting;
  bool get hasErrorSnapshot => hasError;
  bool get hasDataSnapshot => hasData;
}

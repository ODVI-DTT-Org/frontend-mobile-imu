import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// AWS S3 service for file uploads and deletions
///
/// Uses AWS Signature v4 for authentication with direct S3 API calls.
/// Supports uploading files (photos, audio) and deleting files from S3 buckets.
class S3Service {
  final String accessKey;
  final String secretKey;
  final String region;
  final String bucket;

  late final Dio _dio;

  /// Create S3 service instance
  ///
  /// Parameters:
  /// - [accessKey]: AWS access key ID
  /// - [secretKey]: AWS secret access key
  /// - [region]: AWS region (e.g., 'ap-southeast-1')
  /// - [bucket]: S3 bucket name
  S3Service({
    required this.accessKey,
    required this.secretKey,
    required this.region,
    required this.bucket,
  }) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Check if S3 is properly configured
  ///
  /// Returns true if all required credentials are provided
  bool get isConfigured {
    return accessKey.isNotEmpty &&
        secretKey.isNotEmpty &&
        region.isNotEmpty &&
        bucket.isNotEmpty;
  }

  /// Get the S3 endpoint URL for this bucket and region
  String get _endpoint => 'https://$bucket.s3.$region.amazonaws.com';

  /// Upload a file to S3
  ///
  /// Parameters:
  /// - [file]: The file to upload
  /// - [path]: The path prefix in the bucket (e.g., 'touchpoints/photos')
  /// - [fileName]: The name for the file in S3 (will be used as-is)
  ///
  /// Returns the full S3 URL of the uploaded file, or null if upload failed
  Future<String?> uploadFile(
    File file,
    String path,
    String fileName,
  ) async {
    if (!isConfigured) {
      debugPrint('S3Service: Not configured - missing credentials');
      return null;
    }

    try {
      // Read file bytes
      final bytes = await file.readAsBytes();

      // Determine content type based on file extension
      final contentType = _getContentType(fileName);

      // Build the object key (path + filename)
      final key = path.isEmpty ? fileName : '$path/$fileName';

      // Build the S3 URL
      final url = '$_endpoint/$key';

      // Get current time for signing
      final now = DateTime.now().toUtc();

      // Generate AWS Signature v4 headers
      final headers = _generateAuthHeaders(
        method: 'PUT',
        url: url,
        key: key,
        bytes: bytes,
        contentType: contentType,
        now: now,
      );

      // Make the PUT request
      final response = await _dio.put(
        url,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: headers,
          contentType: contentType,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('S3Service: Successfully uploaded $key');
        return url;
      } else {
        debugPrint('S3Service: Upload failed with status ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('S3Service: Upload error - ${e.message}');
      if (e.response != null) {
        debugPrint('S3Service: Response data - ${e.response?.data}');
      }
      return null;
    } catch (e) {
      debugPrint('S3Service: Upload error - $e');
      return null;
    }
  }

  /// Delete a file from S3
  ///
  /// Parameters:
  /// - [url]: The full S3 URL of the file to delete
  ///
  /// Returns void on success, throws on failure
  Future<void> deleteFile(String url) async {
    if (!isConfigured) {
      debugPrint('S3Service: Not configured - missing credentials');
      return;
    }

    try {
      // Extract the key from the URL
      final key = _extractKeyFromUrl(url);
      if (key == null) {
        debugPrint('S3Service: Could not extract key from URL: $url');
        return;
      }

      // Build the S3 URL
      final s3Url = '$_endpoint/$key';

      // Get current time for signing
      final now = DateTime.now().toUtc();

      // Generate AWS Signature v4 headers
      final headers = _generateAuthHeaders(
        method: 'DELETE',
        url: s3Url,
        key: key,
        bytes: Uint8List(0),
        contentType: '',
        now: now,
      );

      // Make the DELETE request
      final response = await _dio.delete(
        s3Url,
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('S3Service: Successfully deleted $key');
      } else {
        debugPrint('S3Service: Delete failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('S3Service: Delete error - ${e.message}');
    } catch (e) {
      debugPrint('S3Service: Delete error - $e');
    }
  }

  /// Generate AWS Signature v4 authorization headers
  ///
  /// This is a private method that implements the AWS Signature v4 signing process.
  /// Reference: https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
  Map<String, String> _generateAuthHeaders({
    required String method,
    required String url,
    required String key,
    required Uint8List bytes,
    required String contentType,
    required DateTime now,
  }) {
    // Format dates
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    // Create canonical request
    final payloadHash = _sha256Hex(bytes);

    // Parse URI for canonical URI
    final uri = Uri.parse(url);
    final canonicalUri = '/$key';
    final canonicalQueryString = uri.query.isEmpty ? '' : uri.query;

    // Build canonical headers
    final host = '$bucket.s3.$region.amazonaws.com';
    final canonicalHeaders = 'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    // Build canonical request
    final canonicalRequest = '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    // Create string to sign
    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final canonicalRequestHash = _sha256Hex(utf8.encode(canonicalRequest));
    final stringToSign = '$algorithm\n$amzDate\n$credentialScope\n$canonicalRequestHash';

    // Calculate signature
    final signingKey = _getSignatureKey(dateStamp);
    final signature = _hmacSha256Hex(signingKey, stringToSign);

    // Build authorization header
    final authorization = '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      'Host': host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Authorization': authorization,
      if (contentType.isNotEmpty) 'Content-Type': contentType,
    };
  }

  /// Extract the object key from a full S3 URL
  String? _extractKeyFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Remove leading slash from path
      String path = uri.path;
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      return path.isEmpty ? null : path;
    } catch (e) {
      return null;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    // Get extension without relying on the path package
    final lastDot = fileName.lastIndexOf('.');
    final extension = lastDot >= 0 ? fileName.substring(lastDot).toLowerCase() : '';
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.ogg':
        return 'audio/ogg';
      case '.aac':
        return 'audio/aac';
      case '.mp4':
        return 'video/mp4';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Format date in AWS AMZ date format (YYYYMMDDTHHMMSSZ)
  String _formatAmzDate(DateTime dateTime) {
    return '${_formatDateStamp(dateTime)}T${_formatTime(dateTime)}Z';
  }

  /// Format date stamp (YYYYMMDD)
  String _formatDateStamp(DateTime dateTime) {
    return '${dateTime.year}${_twoDigits(dateTime.month)}${_twoDigits(dateTime.day)}';
  }

  /// Format time (HHMMSS)
  String _formatTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.hour)}${_twoDigits(dateTime.minute)}${_twoDigits(dateTime.second)}';
  }

  /// Pad single digits with leading zero
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Compute SHA256 hash and return as hex string
  String _sha256Hex(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Compute HMAC-SHA256 and return as hex string
  String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Get the signing key for AWS Signature v4
  List<int> _getSignatureKey(String dateStamp) {
    final kSecret = utf8.encode('AWS4$secretKey');
    final kDate = _hmacSha256(kSecret, dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    return kSigning;
  }

  /// Compute HMAC-SHA256 and return bytes
  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }
}

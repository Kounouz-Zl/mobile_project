import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';


  // For iOS simulator: 'http://localhost:5000/api'
  // For real device: 'http://YOUR_COMPUTER_IP:5000/api'

  late final Dio _dio;
  late final dynamic _storage;

  // Allow injecting `Dio` and `FlutterSecureStorage` for easier testing.
  ApiService({Dio? dio, dynamic storage}) {
    _dio = dio ?? Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle them manually
        return status != null && status < 500;
      },
    ));
    _storage = storage ?? const FlutterSecureStorage();

    // Add interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print(' REQUEST: ${options.method} ${options.uri}');
        if (options.queryParameters.isNotEmpty) {
          print(' QUERY PARAMS: ${options.queryParameters}');
        }
        if (options.data != null) {
          print(' REQUEST BODY: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            ' RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        print(' RESPONSE DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print(
            ' ERROR: ${error.response?.statusCode} ${error.requestOptions.uri}');
        print(' ERROR DATA: ${error.response?.data}');
        print(' ERROR MESSAGE: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  // Storage helpers
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  // HTTP methods with better error handling
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleError(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleError(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleError(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleError(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Upload file (multipart/form-data)
  Future<Response> uploadFile(String path, String filePath,
      {String fieldName = 'image'}) async {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final parts = mimeType.split('/');

      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType(parts[0], parts[1]),
      );

      final formData = FormData.fromMap({
        fieldName: multipartFile,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleError(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling helpers
  Exception _handleError(Response response) {
    final data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('error')) {
      return Exception(data['error']);
    }

    return Exception('Request failed with status ${response.statusCode}');
  }

  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        return Exception(data['error']);
      }

      return Exception('Request failed: ${error.response!.statusCode}');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception(
          'Connection timeout. Please check your internet connection.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception(
          'Cannot connect to server. Please check your internet connection.');
    }

    return Exception('Network error: ${error.message}');
  }
}

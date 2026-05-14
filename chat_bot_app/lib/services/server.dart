import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';

enum ApiType { get, post, put, patch, delete }

class Server {
  Server._();

  static Future<Response> get(
    String url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return _call(
      url,
      apiType: ApiType.get,
      headers: headers,
      cancelToken: cancelToken,
    );
  }

  static Future<Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    return _call(url, apiType: ApiType.post, data: data, headers: headers);
  }

  static Future<Response> put(
    String url, {
    Map<String, String>? headers,
    dynamic data,
    Options? options,
  }) async {
    return _call(url, apiType: ApiType.put, data: data, headers: headers);
  }

  static Future<Response> patch(
    String url, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    return _call(url, apiType: ApiType.patch, data: data, headers: headers);
  }

  static Future<Response> delete(
    String url, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    return _call(url, apiType: ApiType.delete, data: data, headers: headers);
  }

  static Future<Response> _call(
    String url, {
    required ApiType apiType,
    dynamic data,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    if (await isInternetAvailable()) {
      String? token;

      try {
        final dio = Dio();

        dio.options.baseUrl = ApiConstants.devUrl;
        if (headers != null) {
          dio.options.headers.addAll(headers);
        }

        dio.options.headers['Accept'] = 'application/json';

        // Retrieve the Bearer token
        token = MyPrefs.getAuthToken() ?? MyPrefs.getUserToken();
        if (token?.isNotEmpty ?? false) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }

        final Response response;
        debugPrint('API Request: $apiType $url');

        switch (apiType) {
          case ApiType.get:
            response = await dio.get(url, cancelToken: cancelToken);
            break;
          case ApiType.post:
            response = await dio.post(url, data: data);
            break;
          case ApiType.put:
            response = await dio.put(url, data: data);
            break;
          case ApiType.patch:
            response = await dio.patch(url, data: data);
            break;
          case ApiType.delete:
            response = await dio.delete(url, data: data);
            break;
        }

        if (response.data is Map &&
            (response.data as Map)['status_code'] == 401) {
          throw 'Login to use application';
        }
        return response;
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401 && MyPrefs.getUserToken() == null) {
            throw e.response?.data['message'] ?? "Something went wrong ";
          }
        }
        rethrow;
      }
    } else {
      throw 'Check Your Internet Connection';
    }
  }
}

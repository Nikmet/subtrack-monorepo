import 'package:dio/dio.dart';

import '../../core/models/api_failure.dart';

class GeneratedApiClient {
  GeneratedApiClient(this._dio);

  final Dio _dio;

  static const _v1 = '/api/v1';

  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    return _send(
      () => _dio.get('$_v1$path', queryParameters: query),
    );
  }

  Future<dynamic> postData(String path, {dynamic body, Map<String, dynamic>? query}) async {
    return _send(
      () => _dio.post('$_v1$path', queryParameters: query, data: body),
    );
  }

  Future<dynamic> patchData(String path, {dynamic body, Map<String, dynamic>? query}) async {
    return _send(
      () => _dio.patch('$_v1$path', queryParameters: query, data: body),
    );
  }

  Future<dynamic> deleteData(String path, {dynamic body, Map<String, dynamic>? query}) async {
    return _send(
      () => _dio.delete('$_v1$path', queryParameters: query, data: body),
    );
  }

  Future<dynamic> uploadFile(String path, FormData formData) async {
    return _send(
      () => _dio.post(
        '$_v1$path',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<dynamic> authLogin({required String email, required String password}) {
    return postData('/auth/login', body: {
      'email': email,
      'password': password,
      'clientType': 'mobile',
    });
  }

  Future<dynamic> authRegister({required String name, required String email, required String password}) {
    return postData('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'clientType': 'mobile',
    });
  }

  Future<dynamic> authMe() => getData('/auth/me');

  Future<dynamic> authRefresh({required String refreshToken}) {
    return postData('/auth/refresh', body: {
      'refreshToken': refreshToken,
      'clientType': 'mobile',
    });
  }

  Future<dynamic> authLogout({required String refreshToken}) {
    return postData('/auth/logout', body: {'refreshToken': refreshToken});
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        throw ApiFailure.fromResponse(
          statusCode: response.statusCode ?? 500,
          data: response.data,
        );
      }

      throw ApiFailure(
        statusCode: 500,
        code: 'INTERNAL_ERROR',
        message: error.message ?? 'Сетевая ошибка',
      );
    }
  }
}

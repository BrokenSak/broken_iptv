import 'package:dio/dio.dart';

class XtreamAuthResult {
  const XtreamAuthResult({
    required this.success,
    required this.message,
    this.expiresAt,
    this.maxConnections,
  });

  final bool success;
  final String message;
  final DateTime? expiresAt;
  final int? maxConnections;
}

/// Talks to the Xtream Codes `player_api.php` endpoint.
/// JSON coming back from real-world Xtream panels is notoriously
/// inconsistent (numbers as strings, booleans as "0"/"1"), so every
/// field is parsed defensively.
class XtreamApiService {
  XtreamApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;

  static String normalizeHost(String host) {
    var h = host.trim();
    if (!h.startsWith('http://') && !h.startsWith('https://')) {
      h = 'http://$h';
    }
    while (h.endsWith('/')) {
      h = h.substring(0, h.length - 1);
    }
    return h;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<XtreamAuthResult> testConnection({
    required String host,
    required String username,
    required String password,
  }) async {
    final normalizedHost = normalizeHost(host);
    final url = '$normalizedHost/player_api.php';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {'username': username, 'password': password},
      );

      final data = response.data;
      if (data is! Map) {
        return const XtreamAuthResult(
          success: false,
          message: 'Risposta del server non valida.',
        );
      }

      final userInfo = data['user_info'];
      if (userInfo is! Map) {
        return const XtreamAuthResult(
          success: false,
          message: 'Credenziali non valide o server non Xtream Codes.',
        );
      }

      final auth = _asInt(userInfo['auth']) ?? 0;
      if (auth != 1) {
        return const XtreamAuthResult(
          success: false,
          message: 'Username o password errati.',
        );
      }

      final expTimestamp = _asInt(userInfo['exp_date']);
      final expiresAt = expTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000)
          : null;
      final maxConnections = _asInt(userInfo['max_connections']);

      return XtreamAuthResult(
        success: true,
        message: 'Connessione riuscita.',
        expiresAt: expiresAt,
        maxConnections: maxConnections,
      );
    } on DioException catch (e) {
      return XtreamAuthResult(success: false, message: _messageForDioError(e));
    } catch (_) {
      return const XtreamAuthResult(
        success: false,
        message: 'Errore imprevisto durante il test di connessione.',
      );
    }
  }

  String _messageForDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timeout: il server non ha risposto in tempo.';
      case DioExceptionType.connectionError:
        return 'Impossibile raggiungere il server. Controlla il link.';
      case DioExceptionType.badResponse:
        return 'Il server ha risposto con un errore (${e.response?.statusCode ?? '?'}).';
      default:
        return 'Errore di connessione: ${e.message}';
    }
  }
}

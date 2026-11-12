import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/barrier_model.dart';

/// Serviço de WebService REST utilizando obrigatoriamente o pacote `http` (Requisito 4).
/// Consome a API REST de barreiras urbanas da cidade de São Paulo (`barriers_sp.json`),
/// convertendo a resposta JSON em instâncias tipadas de [BarrierModel].
class BarrierApiService {
  /// Endpoint oficial da API de barreiras urbanas de São Paulo desenvolvida para o projeto
  /// (sem hash de revisão fixo para refletir imediatamente atualizações no Gist).
  static const String apiUrl =
      'https://gist.githubusercontent.com/GabrielJS2005/1299682cf15857deae0ebcb58494988f/raw/barriers_sp.json';

  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client? client;

  BarrierApiService({this.client});

  /// Retorna a [Uri] configurada para o endpoint oficial da API.
  static Uri buildApiUri() => Uri.parse(apiUrl);

  /// Busca a lista de barreiras georreferenciadas da cidade de São Paulo via HTTP GET.
  Future<List<BarrierModel>> fetchBarriers() async {
    final Uri uri = buildApiUri();
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
    };

    try {
      final http.Response response = client != null
          ? await client!.get(uri, headers: headers).timeout(_requestTimeout)
          : await http.get(uri, headers: headers).timeout(_requestTimeout);

      return _parseBarriersResponse(response);
    } on BarrierApiException {
      rethrow;
    } on TimeoutException {
      throw BarrierApiException(
        'Tempo limite excedido ao consultar a API de barreiras de São Paulo. '
        'Verifique sua conexão e tente novamente.',
      );
    } on FormatException {
      throw BarrierApiException(
        'Formato JSON inválido retornado pelo servidor da API.',
      );
    } on http.ClientException {
      throw BarrierApiException(
        'Não foi possível conectar ao servidor da API. Verifique sua internet.',
      );
    } catch (_) {
      throw BarrierApiException(
        'Falha ao sincronizar os dados de barreiras de São Paulo. Tente novamente.',
      );
    }
  }

  /// Decodifica o payload UTF-8 JSON da API (`barriers_sp.json`) em uma lista de [BarrierModel].
  List<BarrierModel> _parseBarriersResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw BarrierApiException(
        'O servidor da API retornou HTTP ${response.statusCode}. Tente novamente.',
      );
    }

    final Object? decoded = json.decode(utf8.decode(response.bodyBytes));
    final List<dynamic> rawItems;

    if (decoded is List<dynamic>) {
      rawItems = decoded;
    } else if (decoded is Map<String, dynamic>) {
      rawItems = (decoded['barriers'] ??
              decoded['data'] ??
              decoded['elements'] ??
              const <dynamic>[]) as List<dynamic>;
    } else {
      throw BarrierApiException(
        'Formato inesperado recebido do WebService de barreiras.',
      );
    }

    final List<BarrierModel> barriers = rawItems
        .whereType<Map<String, dynamic>>()
        .map(BarrierModel.fromJson)
        .toList();

    if (barriers.isEmpty) {
      throw BarrierApiException(
        'Nenhuma barreira urbana retornada pela API no momento.',
      );
    }

    return barriers;
  }
}

class BarrierApiException implements Exception {
  final String message;

  BarrierApiException(this.message);

  @override
  String toString() => message;
}

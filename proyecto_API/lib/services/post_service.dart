
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';
import '../models/valoracion_model.dart';

class PostService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<PostModel> agregarPost({
    required String titulo,
    required String descripcion,
    required XFile imagen,
    String? tags,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/blog'),
    );

    request.headers['Accept'] = 'application/json';

    request.fields['titulo'] = titulo.trim();
    request.fields['descripcion'] = descripcion.trim();

    if (tags != null && tags.trim().isNotEmpty) {
      request.fields['tags'] = tags.trim();
    }

    final bytes = await imagen.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: imagen.name,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final respuesta = await http.Response.fromStream(
      streamedResponse,
    );

    final dynamic resultado = respuesta.body.isNotEmpty
        ? jsonDecode(respuesta.body)
        : null;

    if ((respuesta.statusCode == 200 ||
            respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return PostModel.fromJson(resultado);
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudo guardar la publicación '
      '(HTTP ${respuesta.statusCode})',
    );
  }

  Future<List<PostModel>> obtenerPosts() async {
    final respuesta = await http.get(
      Uri.parse('$baseUrl/blog'),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar publicaciones');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => PostModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> enviarValoracion({
    required int idBlog,
    required int idUsr,
    required int puntuacion,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/valoraciones'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_blog': idBlog,
        'id_usr': idUsr,
        'puntuacion': puntuacion,
      }),
    );

    final dynamic resultado = respuesta.body.isNotEmpty
        ? jsonDecode(respuesta.body)
        : null;

    if ((respuesta.statusCode == 200 ||
            respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return resultado;
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudo enviar la valoración '
      '(HTTP ${respuesta.statusCode})',
    );
  }

  Future<ValoracionModel> obtenerValoraciones({
    required int idBlog,
    int? idUsr,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/blog/$idBlog/valoraciones',
    ).replace(
      queryParameters: idUsr != null
          ? {'id_usr': idUsr.toString()}
          : null,
    );

    final respuesta = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    final dynamic resultado = respuesta.body.isNotEmpty
        ? jsonDecode(respuesta.body)
        : null;

    if (respuesta.statusCode == 200 &&
    resultado is Map<String, dynamic>) {
      return ValoracionModel.fromJson(resultado);
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudieron consultar las valoraciones '
      '(HTTP ${respuesta.statusCode})',
    );
  }
}

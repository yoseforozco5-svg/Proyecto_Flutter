
import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../models/valoracion_model.dart';
import '../services/post_service.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final Map<String, dynamic> usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.usuario,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService postService = PostService();

  late Future<ValoracionModel> futureValoraciones;

  bool enviando = false;

  int? get idUsuario {
    final valor = widget.usuario['id_usr'];

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    futureValoraciones = cargarValoraciones();
  }

  Future<ValoracionModel> cargarValoraciones() {
    return postService.obtenerValoraciones(
      idBlog: widget.post.id,
      idUsr: idUsuario,
    );
  }

  Future<void> enviarValoracion(int puntuacion) async {
    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar al usuario.'),
        ),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await postService.enviarValoracion(
        idBlog: widget.post.id,
        idUsr: idUsuario!,
        puntuacion: puntuacion,
      );

      if (!mounted) return;

      setState(() {
        futureValoraciones = cargarValoraciones();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Valoración registrada correctamente!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al valorar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  Widget construirValoraciones() {
    return FutureBuilder<ValoracionModel>(
      future: futureValoraciones,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No se pudieron cargar las valoraciones.'),
              TextButton(
                onPressed: () {
                  setState(() {
                    futureValoraciones = cargarValoraciones();
                  });
                },
                child: const Text('Reintentar'),
              ),
            ],
          );
        }

        final valoracion = snapshot.data!;

        final miPuntuacion = valoracion.miPuntuacion ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valora esta publicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: List.generate(5, (index) {
                final puntuacion = index + 1;

                return IconButton(
                  onPressed: enviando
                      ? null
                      : () => enviarValoracion(puntuacion),
                  icon: Icon(
                    puntuacion <= miPuntuacion
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 34,
                  ),
                );
              }),
            ),

            if (enviando)
              const LinearProgressIndicator(),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  '${valoracion.promedio.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${valoracion.total} valoraciones',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecciona las estrellas para calificar. '
              'Puedes cambiar tu puntuación posteriormente.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de publicación'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.imagen.isNotEmpty)
              Image.network(
                widget.post.imagen.startsWith('http')
                    ? widget.post.imagen
                    : '${PostService.baseUrl}${widget.post.imagen}',
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.tags.isNotEmpty) ...[
                    Text(
                      widget.post.tags,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 0, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Text(
                    widget.post.titulo,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    widget.post.descripcion.isNotEmpty
                        ? widget.post.descripcion
                        : 'Esta publicación no tiene descripción.',
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 20),

                  construirValoraciones(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

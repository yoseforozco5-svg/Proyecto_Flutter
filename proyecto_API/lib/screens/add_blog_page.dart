
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/post_service.dart';
import '../widgets/admin_drawer.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _tags = TextEditingController();

  final _servicio = PostService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;

  bool _guardando = false; 
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource origen) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: origen,
        imageQuality: 85,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagenSeleccionada = imagen;
        _imagenBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _quitarImagen() {
    setState(() {
      _imagenSeleccionada = null;
      _imagenBytes = null;
    });
  }

  
Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  if (_imagenSeleccionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona una imagen para la publicación'),
      ),
    );
    return;
  }

  setState(() => _guardando = true);

  try {
    await _servicio.agregarPost(
      titulo: _titulo.text,
      descripcion: _descripcion.text,
      imagen: _imagenSeleccionada!,
      tags: _tags.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publicación agregada correctamente'),
      ),
    );

    _titulo.clear();
    _descripcion.clear();
    _tags.clear();

    setState(() {
      _imagenSeleccionada = null;
      _imagenBytes = null;
    });

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo guardar: $e'),
      ),
    );

  } finally {
    if (mounted) {
      setState(() => _guardando = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final nombre = _usuario['nom_usr']?.toString() ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar blog'),
      ),
      drawer: AdminDrawer(
        usuario: _usuario,
        rutaActual: '/add-blog',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 6),

                      Text('Administrador: $nombre'),

                      const SizedBox(height: 20),

                      // TÍTULO
                      TextFormField(
                        controller: _titulo,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Ingresa el título'
                                : null,
                      ),

                      const SizedBox(height: 14),

                      // DESCRIPCIÓN
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Ingresa la descripción'
                                : null,
                      ),

                      const SizedBox(height: 20),

                      // SELECCIÓN DE IMAGEN
                      const Text(
                        'Imagen de la publicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // VISTA PREVIA
                      if (_imagenBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imagenBytes!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _imagenSeleccionada!.name,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _quitarImagen,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Quitar imagen'),
                        ),
                      ] else ...[
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 55,
                              ),
                              SizedBox(height: 8),
                              Text('No has seleccionado una imagen'),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // BOTONES DE SELECCIÓN
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : () => _seleccionarImagen(
                                        ImageSource.gallery,
                                      ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galería'),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : () => _seleccionarImagen(
                                        ImageSource.camera,
                                      ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Cámara'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ETIQUETAS
                      TextFormField(
                        controller: _tags,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (opcional)',
                          hintText: 'flutter, tecnología, móvil',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // GUARDAR
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando
                              ? 'Guardando...'
                              : 'Guardar publicación',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

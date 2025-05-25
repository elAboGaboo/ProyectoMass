import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Promos extends StatefulWidget {
  const Promos({super.key});

  @override
  _PromosState createState() => _PromosState();
}

class _PromosState extends State<Promos> {
  final CollectionReference _coleccion =
      FirebaseFirestore.instance.collection('promos');

  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  File? _imagenSeleccionada;

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  String convertirEnlaceDriveADirecto(String enlaceDrive) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(enlaceDrive);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return enlaceDrive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Mensaje de bienvenida
          Card(
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '¡Bienvenido a Promos!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Ingrese los datos de los productos para gestionar la información de manera eficiente.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // CRUD de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _coleccion.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los productos'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay productos registrados.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imgUrl = convertirEnlaceDriveADirecto(data['img'] ?? '');
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 3,
                      child: ListTile(
                        leading: imgUrl.isNotEmpty
                            ? Image.network(
                                imgUrl,
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 50);
                                },
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                        title: Text(
                          data['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['descripcion'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Precio: \$${data['precio']}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetallesProducto(context, data, imgUrl),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Editar',
                              onPressed: () => _mostrarFormulario(context, doc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminarRegistro(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDetallesProducto(BuildContext context, Map<String, dynamic> data, String imgUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['nombre']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imgUrl.isNotEmpty)
                Image.network(
                  imgUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 150);
                  },
                ),
              const SizedBox(height: 10),
              Text(
                data['descripcion'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Precio: \$${data['precio']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFormulario(BuildContext context, {DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      nombreController.text = data['nombre'] ?? '';
      descripcionController.text = data['descripcion'] ?? '';
      precioController.text = data['precio'].toString();
    } else {
      nombreController.clear();
      descripcionController.clear();
      precioController.clear();
      _imagenSeleccionada = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? 'Agregar Producto' : 'Editar Producto'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: precioController,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _seleccionarImagen,
                    child: const Text('Seleccionar Imagen'),
                  ),
                  if (_imagenSeleccionada != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Image.file(
                        _imagenSeleccionada!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nombre': nombreController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'precio': double.parse(precioController.text.trim()),
                  };
                  if (doc == null) {
                    await _coleccion.add(data);
                  } else {
                    await _coleccion.doc(doc.id).update(data);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarRegistro(String id) async {
    await _coleccion.doc(id).delete();
  }
}
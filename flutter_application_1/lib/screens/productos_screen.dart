import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Función global para convertir enlaces de Google Drive a enlace directo
String convertirEnlaceDriveADirecto(String url) {
  final regex = RegExp(r'd/([a-zA-Z0-9_-]+)');
  final match = regex.firstMatch(url);
  if (match != null) {
    final id = match.group(1);
    return 'https://drive.google.com/uc?export=download&id=$id';
  }
  return url;
}

class ProductosScreen extends StatelessWidget {
  final String categoria;
  const ProductosScreen({super.key, required this.categoria});

  // Función para mostrar los detalles del producto en una ventana flotante
  void _mostrarDetallesProducto(BuildContext context, Map<String, dynamic> data, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['nombre'] ?? 'Sin nombre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 80);
                  },
                ),
              const SizedBox(height: 10),
              Text(
                data['descripcion'] ?? 'Sin descripción',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Precio: \$${data['precio']?.toString() ?? '0'}',
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

  @override
  Widget build(BuildContext context) {
    final productosRef = FirebaseFirestore.instance
        .collection('productos')
        .where('categoria', isEqualTo: categoria);

    return Scaffold(
      appBar: AppBar(title: Text('Productos de $categoria')),
      body: StreamBuilder<QuerySnapshot>(
        stream: productosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Error');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Sin productos'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rawImgUrl = data['img'] ?? '';
              final imageUrl = convertirEnlaceDriveADirecto(rawImgUrl);

              return ListTile(
                leading: rawImgUrl.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _mostrarDetallesProducto(context, data, imageUrl),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    : const Icon(Icons.image_not_supported, size: 40),
                title: Text(data['nombre'] ?? ''),
                subtitle: Text(
                  '${data['descripcion'] ?? ''}\nPrecio: \$${data['precio']?.toString() ?? '0'}',
                ),
                isThreeLine: true,
                onTap: () => _mostrarDetallesProducto(context, data, imageUrl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CrearEditarProductoDialog(
                            categoria: categoria,
                            productoId: doc.id,
                            nombre: data['nombre'] ?? '',
                            descripcion: data['descripcion'] ?? '',
                            precio: data['precio']?.toString() ?? '',
                            img: rawImgUrl,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await doc.reference.delete();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CrearEditarProductoDialog(categoria: categoria),
          );
        },
      ),
    );
  }
}

class CrearEditarProductoDialog extends StatefulWidget {
  final String categoria;
  final String? productoId;
  final String? nombre;
  final String? descripcion;
  final String? precio;
  final String? img;

  const CrearEditarProductoDialog({
    super.key,
    required this.categoria,
    this.productoId,
    this.nombre,
    this.descripcion,
    this.precio,
    this.img,
  });

  @override
  State<CrearEditarProductoDialog> createState() =>
      _CrearEditarProductoDialogState();
}

class _CrearEditarProductoDialogState extends State<CrearEditarProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late String nombre;
  late String descripcion;
  late String precio;

  @override
  void initState() {
    super.initState();
    nombre = widget.nombre ?? '';
    descripcion = widget.descripcion ?? '';
    precio = widget.precio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.productoId == null ? 'Nuevo producto' : 'Editar producto',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                onSaved: (value) => nombre = value ?? '',
              ),
              TextFormField(
                initialValue: descripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => descripcion = value ?? '',
              ),
              TextFormField(
                initialValue: precio,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un precio';
                  }
                  final n = num.tryParse(value);
                  if (n == null) return 'Ingrese un número válido';
                  if (n < 0) return 'El precio no puede ser negativo';
                  return null;
                },
                onSaved: (value) => precio = value ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Guardar'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final data = {
                'nombre': nombre,
                'descripcion': descripcion,
                'precio': double.tryParse(precio) ?? 0,
                'categoria': widget.categoria,
                'creado': FieldValue.serverTimestamp(),
              };

              if (widget.productoId == null) {
                await FirebaseFirestore.instance
                    .collection('productos')
                    .add(data);
              } else {
                await FirebaseFirestore.instance
                    .collection('productos')
                    .doc(widget.productoId)
                    .update(data);
              }
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
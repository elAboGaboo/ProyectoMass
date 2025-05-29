import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_global.dart';
import 'productos_screen.dart';

class Categoria extends StatefulWidget {
  const Categoria({super.key});

  @override
  State<Categoria> createState() => _CategoriaState();
}

class _CategoriaState extends State<Categoria>
    with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> productosFiltrados = [];

  late AnimationController _iconAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    obtenerProductos();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> obtenerProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();
      final lista =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      setState(() {
        productos = lista;
        productosFiltrados = [];
      });
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
    }
  }

  void filtrarProductos(String texto) {
    if (texto.isEmpty) {
      setState(() {
        productosFiltrados = [];
      });
      return;
    }
    final resultado =
        productos.where((producto) {
          final nombre = producto['nombre']?.toLowerCase() ?? '';
          return nombre.contains(texto.trim().toLowerCase());
        }).toList();
    setState(() {
      productosFiltrados = resultado;
    });
  }

  String getDirectImageUrl(String url) {
    if (url.contains('drive.google.com')) {
      final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final id = match.group(1);
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    return url;
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final index = carrito.indexWhere((item) => item['id'] == producto['id']);
      if (index != -1) {
        carrito[index]['cantidad'] = (carrito[index]['cantidad'] ?? 1) + 1;
      } else {
        final nuevoProducto = Map<String, dynamic>.from(producto);
        nuevoProducto['cantidad'] = 1;
        carrito.add(nuevoProducto);
      }
    });
    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse();
    });
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      content: Text('${producto['nombre']} añadido al carrito'),
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void eliminarDelCarrito(BuildContext context, int index) {
    setState(() {
      if ((carrito[index]['cantidad'] ?? 1) > 1) {
        carrito[index]['cantidad'] = carrito[index]['cantidad'] - 1;
      } else {
        carrito.removeAt(index);
        if (carrito.isEmpty) Navigator.of(context).pop();
      }
    });
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto eliminado del carrito'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int totalProductosEnCarrito() {
    return carrito.fold<int>(
      0,
      (sum, item) => sum + ((item['cantidad'] ?? 1) as int),
    );
  }

  void mostrarCarrito() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8F3FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: false,
      builder:
          (_) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child:
                carrito.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('El carrito está vacío'),
                      ),
                    )
                    : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Carrito (${totalProductosEnCarrito()})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: carrito.length,
                            itemBuilder: (context, index) {
                              final item = carrito[index];
                              final imageUrl = getDirectImageUrl(
                                item['img'] ?? '',
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading:
                                      imageUrl.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.shopping_bag,
                                            color: Colors.purple,
                                          ),
                                  title: Text(
                                    item['nombre'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Precio: \$${item['precio']}  |  Cantidad: ${item['cantidad']}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () =>
                                            eliminarDelCarrito(context, index),
                                    tooltip: 'Eliminar uno',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Cigarros y Vapes', 'icon': Icons.smoking_rooms},
      {'name': 'Cervezas', 'icon': Icons.local_drink},
      {'name': 'RTDs', 'icon': Icons.sports_bar},
      {'name': 'Licores', 'icon': Icons.wine_bar},
      {'name': 'Comidas', 'icon': Icons.fastfood},
      {'name': 'Bebidas', 'icon': Icons.local_cafe},
      {'name': 'Antojos', 'icon': Icons.icecream},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        centerTitle: true,
        actions: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: mostrarCarrito,
                ),
                if (carrito.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${totalProductosEnCarrito()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dirección',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: 'Selecciona una dirección',
                  items: const [
                    DropdownMenuItem(
                      value: 'Selecciona una dirección',
                      child: Text('Selecciona una dirección'),
                    ),
                    DropdownMenuItem(value: 'Casa', child: Text('Casa')),
                    DropdownMenuItem(value: 'Oficina', child: Text('Oficina')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: filtrarProductos,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                searchController.text.isNotEmpty
                    ? (productosFiltrados.isNotEmpty
                        ? ListView.builder(
                          itemCount: productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = productosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading:
                                    producto['img'] != null &&
                                            producto['img']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                          getDirectImageUrl(producto['img']),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.purple,
                                                  ),
                                        )
                                        : const Icon(
                                          Icons.shopping_bag,
                                          color: Colors.purple,
                                        ),
                                title: Text(
                                  producto['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(producto['descripcion'] ?? ''),
                                    Text(
                                      'Categoría: ${producto['categoria'] ?? ''}',
                                    ),
                                    Text(
                                      'Precio: \$${producto['precio'] ?? ''}',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.purple,
                                  ),
                                  onPressed: () => agregarAlCarrito(producto),
                                ),
                                onTap: () {},
                              ),
                            );
                          },
                        )
                        : const Center(
                          child: Text('No se encontraron productos'),
                        ))
                    : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: Icon(
                              category['icon'] as IconData,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(
                            category['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProductosScreen(
                                      categoria: category['name'] as String,
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
    );
  }
}

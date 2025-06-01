import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_global.dart';
import 'productos_screen.dart';
import 'map_display_screen.dart'; // Para mostrar el mapa con la ruta
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Definición de la clase AppAddress
class AppAddress {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const AppAddress({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAddress &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
// Fin de la clase AppAddress

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

  // Variables para la selección de dirección y mapa
  final List<AppAddress> _availableAddresses = const [
    AppAddress(id: 'tienda_mass_larco', name: 'Tienda Mass 1', latitude: -12.047102523091558, longitude: -75.1993390970959),
    AppAddress(id: 'tienda_mass_centro', name: 'Tienda Mass 2', latitude: -12.047327457002215, longitude: -75.19484170314458),
    // Agrega más direcciones de tiendas "Mass" aquí
  ];
  AppAddress? _selectedAddress;
  // Position? _currentUserPosition; // Ya no es necesario almacenarlo aquí si MapDisplayScreen lo obtiene

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
    // No es necesario obtener la ubicación del usuario aquí si MapDisplayScreen lo hará
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> obtenerProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();
      final lista =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (mounted) {
        setState(() {
          productos = lista;
          productosFiltrados = [];
        });
      }
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: ${e.toString()}')),
        );
      }
    }
  }

  void filtrarProductos(String texto) {
    if (texto.isEmpty) {
      if (mounted) {
        setState(() {
          productosFiltrados = [];
        });
      }
      return;
    }
    final resultado = productos.where((producto) {
      final nombre = producto['nombre']?.toString().toLowerCase() ?? '';
      return nombre.contains(texto.trim().toLowerCase());
    }).toList();
    if (mounted) {
      setState(() {
        productosFiltrados = resultado;
      });
    }
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

    if (mounted && ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        content: Text('${producto['nombre']} añadido al carrito'),
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
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
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void eliminarDelCarritoEnModal(int index) {
              if (index < carrito.length) {
                if ((carrito[index]['cantidad'] ?? 1) > 1) {
                  carrito[index]['cantidad'] = (carrito[index]['cantidad'] ?? 1) - 1;
                } else {
                  carrito.removeAt(index);
                }
                setModalState(() {});
                setState(() {}); // Para el badge del AppBar
                
                ScaffoldMessenger.of(modalContext).showSnackBar(
                    const SnackBar(
                        content: Text('Producto eliminado del carrito'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                    ),
                );

                if (carrito.isEmpty) {
                  Navigator.of(modalContext).pop();
                }
              }
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: carrito.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('El carrito está vacío', style: TextStyle(fontSize: 16)),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Carrito (${totalProductosEnCarrito()})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: carrito.length,
                            itemBuilder: (context, index) {
                              final item = carrito[index];
                              final imageUrl = getDirectImageUrl(
                                item['img']?.toString() ?? '',
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, st) =>
                                                  const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                            )
                                          : const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.purple),
                                    ),
                                  ),
                                  title: Text(
                                    item['nombre']?.toString() ?? 'Producto',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Precio: S/${item['precio']}  |  Cant: ${item['cantidad']}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => eliminarDelCarritoEnModal(index),
                                    tooltip: 'Eliminar uno',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          }
        );
      },
    ).then((_) {
      setState(() {}); // Refrescar badge al cerrar modal
    });
  }

  // --- FUNCIÓN LLAMADA AL SELECCIONAR UNA DIRECCIÓN EN EL DROPDOWN ---
  void _onAddressSelectedShowMap(AppAddress? newAddress) {
    if (newAddress == null) return;

    setState(() {
      _selectedAddress = newAddress; // Actualiza la selección para el Dropdown
    });

    // Navega a la pantalla del mapa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapDisplayScreen(
          initialStoreLocation: LatLng(newAddress.latitude, newAddress.longitude),
          initialStoreName: newAddress.name,
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
        title: const Text('Mi Tienda'),
        centerTitle: true,
        actions: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  iconSize: 28,
                  onPressed: mostrarCarrito,
                ),
                if (carrito.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '${totalProductosEnCarrito()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined, color: Colors.purple, size: 20), // Icono de tienda
                const SizedBox(width: 8),
                const Text(
                  'Ver ruta a:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AppAddress>(
                      value: _selectedAddress,
                      isExpanded: true,
                      hint: const Text('Selecciona una tienda', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      icon: const Icon(Icons.map_outlined, color: Colors.purple),
                      items: _availableAddresses.map<DropdownMenuItem<AppAddress>>((AppAddress address) {
                        return DropdownMenuItem<AppAddress>(
                          value: address,
                          child: Text(
                            address.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: _onAddressSelectedShowMap, // LLAMA A LA FUNCIÓN PARA MOSTRAR EL MAPA
                      style: const TextStyle(color: Colors.purple, fontSize: 16),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
                ),
              ),
              onChanged: filtrarProductos,
            ),
          ),
          Expanded(
            child: searchController.text.isNotEmpty
                ? (productosFiltrados.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = productosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: SizedBox(
                                width: 60, height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: producto['img'] != null &&
                                          producto['img']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.network(
                                        getDirectImageUrl(producto['img'].toString()),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey, size: 40,
                                                ),
                                      )
                                      : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.purple, size: 40,
                                      ),
                                ),
                              ),
                              title: Text(
                                producto['nombre']?.toString() ?? 'Producto',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(producto['descripcion']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(
                                    'Categoría: ${producto['categoria'] ?? ''}',
                                  ),
                                  Text(
                                    'Precio: S/${producto['precio'] ?? '0.00'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                  color: Colors.purple,
                                ),
                                onPressed: () => agregarAlCarrito(producto),
                                tooltip: "Añadir al carrito",
                              ),
                              onTap: () {
                                debugPrint("Producto tocado: ${producto['nombre']}");
                              },
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('No se encontraron productos para tu búsqueda.'),
                      ))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withOpacity(0.1),
                              child: Icon(
                                category['icon'] as IconData,
                                color: Colors.purple,
                              ),
                            ),
                            title: Text(
                              category['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
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
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
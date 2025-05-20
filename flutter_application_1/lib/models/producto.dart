class Producto {
  String id;
  String nombre;
  String descripcion;
  double precio;
  String tipo;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'tipo': tipo,
    };
  }

  static Producto fromMap(String id, Map<String, dynamic> map) {
    return Producto(
      id: id,
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      tipo: map['tipo'],
    );
  }
}
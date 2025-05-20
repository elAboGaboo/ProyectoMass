class Plato {
  String id;
  String nombre;
  String ingredientes;
  double precio;
  String tipo;

  Plato({
    required this.id,
    required this.nombre,
    required this.ingredientes,
    required this.precio,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ingredientes': ingredientes,
      'precio': precio,
      'tipo': tipo,
    };
  }

  static Plato fromMap(String id, Map<String, dynamic> map) {
    return Plato(
      id: id,
      nombre: map['nombre'],
      ingredientes: map['ingredientes'],
      precio: map['precio'],
      tipo: map['tipo'],
    );
  }
}
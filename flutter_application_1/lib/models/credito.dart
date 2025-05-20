class Credito {
  String id;
  String nombreCliente;
  double monto;
  int numeroCuotas;
  String estado;

  Credito({
    required this.id,
    required this.nombreCliente,
    required this.monto,
    required this.numeroCuotas,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombreCliente': nombreCliente,
      'monto': monto,
      'numeroCuotas': numeroCuotas,
      'estado': estado,
    };
  }

  static Credito fromMap(String id, Map<String, dynamic> map) {
    return Credito(
      id: id,
      nombreCliente: map['nombreCliente'],
      monto: map['monto'],
      numeroCuotas: map['numeroCuotas'],
      estado: map['estado'],
    );
  }
}
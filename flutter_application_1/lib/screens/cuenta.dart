import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cuenta extends StatefulWidget {
  const Cuenta({super.key});

  @override
  _CuentaState createState() => _CuentaState();
}

class _CuentaState extends State<Cuenta> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  bool _registroExitoso = false; // Variable para mostrar el mensaje de éxito

  void _registrarCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Guarda los datos en Firestore
        await FirebaseFirestore.instance.collection('clientes').add({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'dni': _dniController.text.trim(),
          'celular': _celularController.text.trim(),
          'fecha_registro': DateTime.now(),
        });

        // Actualiza el estado para mostrar el mensaje de éxito
        setState(() {
          _registroExitoso = true;
        });

        // Limpia los campos
        _nombreController.clear();
        _apellidoController.clear();
        _dniController.clear();
        _celularController.clear();

        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
      } catch (e) {
        // Muestra un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Cliente'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Mensaje de registro exitoso
              if (_registroExitoso)
                const Text(
                  '¡Registro exitoso!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 16),
              // Campo de nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de apellido
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de DNI
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su DNI';
                  }
                  if (value.length != 8) {
                    return 'El DNI debe tener 8 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de celular
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(
                  labelText: 'Número de celular',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su número de celular';
                  }
                  if (value.length != 9) {
                    return 'El número de celular debe tener 9 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botón de registrar
              ElevatedButton(
                onPressed: _registrarCliente,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
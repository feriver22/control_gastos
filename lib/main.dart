import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
//Fernando inicio parte del desarrollo del proyecto
class Gasto {
  final String categoria;
  final double monto;
  final DateTime fecha;

  Gasto({
    required this.categoria,
    required this.monto,
    required this.fecha,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Gasto> _gastos = [];

  double get totalGastos {
    return _gastos.fold(0, (sum, item) => sum + item.monto);
  }

  void _agregarGasto(String categoria, double monto) {
    setState(() {
      _gastos.add(
        Gasto(
          categoria: categoria,
          monto: monto,
          fecha: DateTime.now(),
        ),
      );
    });
  }

  void _eliminarGasto(int index) {
    setState(() {
      _gastos.removeAt(index);
    });
  }

  void _mostrarFormulario() {
    final categoriaController = TextEditingController();
    final montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Agregar Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(labelText: "Categoría"),
            ),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final categoria = categoriaController.text;
              final monto = double.tryParse(montoController.text);

              if (categoria.isEmpty || monto == null) return;

              _agregarGasto(categoria, monto);
              Navigator.of(ctx).pop();
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
//PARTE DE JUAN NO TOCAR
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Gastos"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blue.shade100,
            child: Text(
              "Total: L ${totalGastos.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _gastos.isEmpty
                ? const Center(child: Text("No hay gastos registrados"))
                : ListView.builder(
                    itemCount: _gastos.length,
                    itemBuilder: (ctx, index) {
                      final gasto = _gastos[index];
                      return Card(
                        child: ListTile(
                          title: Text(gasto.categoria),
                          subtitle: Text(
                              "L ${gasto.monto.toStringAsFixed(2)}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarGasto(index),
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

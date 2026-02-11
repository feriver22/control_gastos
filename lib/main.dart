import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

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

  double? _presupuesto;
  String? _nombreUsuario;

  double get totalGastos =>
      _gastos.fold(0, (sum, item) => sum + item.monto);

  double get disponible =>
      _presupuesto != null ? _presupuesto! - totalGastos : 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // =============================
  // CARGAR DATOS GUARDADOS
  // =============================
  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('nombre');
      _presupuesto = prefs.getDouble('presupuesto');
    });

    if (_nombreUsuario == null || _presupuesto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogoInicial();
      });
    }
  }

  // =============================
  // GUARDAR DATOS
  // =============================
  Future<void> _guardarDatos(String nombre, double presupuesto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setDouble('presupuesto', presupuesto);
  }

  // =============================
  // CERRAR SESIÓN
  // =============================
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      _nombreUsuario = null;
      _presupuesto = null;
      _gastos.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarDialogoInicial();
    });
  }

  // =============================
  // DIALOGO INICIAL / EDICIÓN
  // =============================
  void _mostrarDialogoInicial({bool esEdicion = false}) {
    final nombreController =
        TextEditingController(text: _nombreUsuario ?? "");
    final presupuestoController =
        TextEditingController(text: _presupuesto?.toString() ?? "");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
            esEdicion ? "Editar Presupuesto" : "Configuración Inicial"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!esEdicion)
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre de usuario",
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: presupuestoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: "Presupuesto mensual",
              ),
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
            onPressed: () async {
              final nombre = esEdicion
                  ? _nombreUsuario!
                  : nombreController.text.trim();

              final presupuesto =
                  double.tryParse(presupuestoController.text);

              if (nombre.isNotEmpty &&
                  presupuesto != null &&
                  presupuesto > 0) {
                setState(() {
                  _nombreUsuario = nombre;
                  _presupuesto = presupuesto;
                });

                await _guardarDatos(nombre, presupuesto);

                Navigator.of(ctx).pop();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // =============================
  // AGREGAR GASTO
  // =============================
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content:
            const Text("¿Seguro que desea eliminar este gasto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _gastos.removeAt(index);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
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
              decoration:
                  const InputDecoration(labelText: "Categoría"),
            ),
            TextField(
              controller: montoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration:
                  const InputDecoration(labelText: "Monto"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final categoria =
                  categoriaController.text.trim();
              final monto =
                  double.tryParse(montoController.text);

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

  @override
  Widget build(BuildContext context) {
    final bool excedido =
        _presupuesto != null && totalGastos > _presupuesto!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Gastos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar Presupuesto",
            onPressed: () =>
                _mostrarDialogoInicial(esEdicion: true),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _presupuesto == null ? null : _mostrarFormulario,
        child: const Icon(Icons.add),
      ),
      body: _presupuesto == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.blue.shade100,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bienvenido, $_nombreUsuario",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Presupuesto: L ${_presupuesto!.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Total Gastado: L ${totalGastos.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: excedido
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      Text(
                        "Disponible: L ${disponible.toStringAsFixed(2)}",
                      ),
                      if (excedido)
                        const Text(
                          "Has excedido tu presupuesto",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _gastos.isEmpty
                      ? const Center(
                          child:
                              Text("No hay gastos registrados"))
                      : ListView.builder(
                          itemCount: _gastos.length,
                          itemBuilder: (ctx, index) {
                            final gasto = _gastos[index];
                            return Card(
                              child: ListTile(
                                title:
                                    Text(gasto.categoria),
                                subtitle: Text(
                                    "L ${gasto.monto.toStringAsFixed(2)}"),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _eliminarGasto(index),
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

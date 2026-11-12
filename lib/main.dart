     import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const GestorMarbefApp());
}

class GestorMarbefApp extends StatelessWidget {
  const GestorMarbefApp({super.key});

  @override
  Widget build(BuildContext context) {
    const azulEscuro = Color(0xFF0D1B2A);
    const azulCartao = Color(0xFF1B263B);
    const dourado = Color(0xFFD4AF37);

    return MaterialApp(
      title: 'Gestor Marbef Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: azulEscuro,
        primaryColor: dourado,
        colorScheme: const ColorScheme.dark(
          primary: dourado,
          secondary: dourado,
          surface: azulCartao,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: azulEscuro,
          foregroundColor: dourado,
          elevation: 0,
        ),
        cardColor: azulCartao,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: dourado,
          foregroundColor: azulEscuro,
        ),
      ),
      home: const TelaPrincipal(),
    );
  }
}

// ==================== BASE DE DADOS OFFLINE (SQLITE) ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('marbef_services.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco REAL NOT NULL,
        stock INTEGER NOT NULL,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT,
        divida REAL DEFAULT 0,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_nome TEXT,
        produto_nome TEXT,
        quantidade INTEGER,
        total REAL,
        metodo_pagamento TEXT,
        data TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE funcionarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cargo TEXT NOT NULL,
        salario REAL NOT NULL
      )
    ''');
  }
}

// ==================== NAVEGAÇÃO PRINCIPAL ====================
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;

  final List<Widget> _telas = [
    const AbaResumoRelatorios(),
    const AbaVendas(),
    const AbaProdutos(),
    const AbaClientesEquipa(),
  ];

  void _sincronizarDados() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A verificar ligação e a sincronizar registos locais...'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestor Marbef Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar dados offline',
            onPressed: _sincronizarDados,
          ),
        ],
      ),
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0D1B2A),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Relatórios'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Vendas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes/Equipa'),
        ],
      ),
    );
  }
}

// ==================== 1. RELATÓRIOS, DESPESAS E LUCROS ====================
class AbaResumoRelatorios extends StatefulWidget {
  const AbaResumoRelatorios({super.key});

  @override
  State<AbaResumoRelatorios> createState() => _AbaResumoRelatoriosState();
}

class _AbaResumoRelatoriosState extends State<AbaResumoRelatorios> {
  double totalVendas = 0;
  double totalDespesas = 0;
  double totalDividas = 0;
  List> listaDespesas = [];

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    final db = await DatabaseHelper.instance.database;
    final vendas = await db.query('vendas');
    final despesas = await db.query('despesas', orderBy: 'id DESC');
    final clientes = await db.query('clientes');

    double somaV = 0;
    for (var v in vendas) {
      somaV += (v['total'] as num).toDouble();
    }
    double somaD = 0;
    for (var d in despesas) {
      somaD += (d['valor'] as num).toDouble();
    }
    double somaDiv = 0;
    for (var c in clientes) {
      somaDiv += (c['divida'] as num).toDouble();
    }

    setState(() {
      totalVendas = somaV;
      totalDespesas = somaD;
      totalDividas = somaDiv;
      listaDespesas = despesas;
    });
  }

  void _adicionarDespesa() {
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registar Despesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor (MT)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(valorCtrl.text) ?? 0;
              if (descCtrl.text.isNotEmpty && valor > 0) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('despesas', {
                  'descricao': descCtrl.text,
                  'valor': valor,
                  'data': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                });
                if (mounted) Navigator.pop(ctx);
                _carregarResumo();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lucro = totalVendas - totalDespesas;
    return RefreshIndicator(
      onRefresh: _carregarResumo,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardIndicador('Receita Total de Vendas', '${totalVendas.toStringAsFixed(2)} MT', Colors.greenAccent),
          _cardIndicador('Total de Despesas', '${totalDespesas.toStringAsFixed(2)} MT', Colors.redAccent),
          _cardIndicador('Lucro Líquido', '${lucro.toStringAsFixed(2)} MT', const Color(0xFFD4AF37)),
          _cardIndicador('Dívidas de Clientes a Receber', '${totalDividas.toStringAsFixed(2)} MT', Colors.orangeAccent),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Últimas Despesas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _adicionarDespesa,
                icon: const Icon(Icons.add),
                label: const Text('Nova Despesa'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...listaDespesas.map((d) => Card(
                child: ListTile(
                  title: Text(d['descricao']),
                  subtitle: Text(d['data']),
                  trailing: Text(
                    '- ${d['valor']} MT',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _cardIndicador(String titulo, String valor, Color cor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 15)),
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. VENDAS, PAGAMENTOS E RECIBOS ====================
class AbaVendas extends StatefulWidget {
  const AbaVendas({super.key});

  @override
  State<AbaVendas> createState() => _AbaVendasState();
}

class _AbaVendasState extends State<AbaVendas> {
  List> vendas = [];

  @override
  void initState() {
    super.initState();
    _carregarVendas();
  }

  Future<void> _carregarVendas() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('vendas', orderBy: 'id DESC');
    setState(() => vendas = res);
  }

  Future<void> _emitirReciboPDF(Map<String, dynamic> venda) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('GESTOR MARBEF SERVICES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Divider(),
            pw.Text('Recibo N.º: ${venda['id']}'),
            pw.Text('Data: ${venda['data']}'),
            pw.Text('Cliente: ${venda['cliente_nome']}'),
            pw.Divider(),
            pw.Text('Produto: ${venda['produto_nome']}'),
            pw.Text('Quantidade: ${venda['quantidade']}'),
            pw.Text('Pagamento: ${venda['metodo_pagamento']}'),
            pw.Divider(),
            pw.Text('TOTAL: ${venda['total']} MT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text('Obrigado pela preferência!'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _novaVenda() async {
    final db = await DatabaseHelper.instance.database;
    final produtos = await db.query('produtos', where: 'stock > 0');
    if (produtos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registe produtos com stock antes de vender.')),
        );
      }
      return;
    }

    int produtoId = produtos.first['id'] as int;
    String metodo = 'Numerário';
    final clienteCtrl = TextEditingController(text: 'Cliente Geral');
    final qtdCtrl = TextEditingController(text: '1');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Nova Venda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: produtoId,
                items: produtos.map((p) {
                  return DropdownMenuItem<int>(
                    value: p['id'] as int,
                    child: Text('${p['nome']} (${p['preco']} MT | Stock: ${p['stock']})'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => produtoId = val!),
                decoration: const InputDecoration(labelText: 'Produto'),
              ),
              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              TextField(
                controller: clienteCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Cliente'),
              ),
              DropdownButtonFormField<String>(
                value: metodo,
                items: ['Numerário', 'M-Pesa', 'e-Mola', 'Transferência', 'Crédito (Dívida)']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setModalState(() => metodo = val!),
                decoration: const InputDecoration(labelText: 'Método de Pagamento'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final prod = produtos.firstWhere((e) => e['id'] == produtoId);
                final qtd = int.tryParse(qtdCtrl.text) ?? 1;
                final stockAtual = prod['stock'] as int;

                if (qtd <= 0 || qtd > stockAtual) return;

                final total = (prod['preco'] as num).toDouble() * qtd;

                await db.insert('vendas', {
                  'cliente_nome': clienteCtrl.text,
                  'produto_nome': prod['nome'],
                  'quantidade': qtd,
                  'total': total,
                  'metodo_pagamento': metodo,
                  'data': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                });

                await db.update(
                  'produtos',
                  {'stock': stockAtual - qtd},
                  where: 'id = ?',
                  whereArgs: [produtoId],
                );

                if (metodo == 'Crédito (Dívida)') {
                  await db.insert('clientes', {
                    'nome': clienteCtrl.text,
                    'telefone': '',
                    'divida': total,
                  });
                }

                if (mounted) Navigator.pop(ctx);
                _carregarVendas();
              },
              child: const Text('Concluir Venda'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vendas.length,
        itemBuilder: (ctx, i) {
          final v = vendas[i];
          return Card(
            child: ListTile(
              title: Text('${v['produto_nome']} (x${v['quantidade']})'),
              subtitle: Text('${v['cliente_nome']} • ${v['metodo_pagamento']}\n${v['data']}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${v['total']} MT', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'Emitir Recibo PDF',
                    onPressed: () => _emitirReciboPDF(v),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaVenda,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nova Venda'),
      ),
    );
  }
}

// ==================== 3. PRODUTOS E CONTROLO DE STOCK ====================
class AbaProdutos extends StatefulWidget {
  const AbaProdutos({super.key});

  @override
  State<AbaProdutos> createState() => _AbaProdutosState();
}

class _AbaProdutosState extends State<AbaProdutos> {
  List> produtos = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('produtos', orderBy: 'nome ASC');
    setState(() => produtos = res);
  }

  void _adicionarProduto() {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto')),
            TextField(
              controller: precoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço Unitário (MT)'),
            ),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade em Stock'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final preco = double.tryParse(precoCtrl.text) ?? 0;
              final stock = int.tryParse(stockCtrl.text) ?? 0;
              if (nomeCtrl.text.isNotEmpty && preco > 0) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('produtos', {'nome': nomeCtrl.text, 'preco': preco, 'stock': stock});
                if (mounted) Navigator.pop(ctx);
                _carregarProdutos();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: produtos.length,
        itemBuilder: (ctx, i) {
          final p = produtos[i];
          final baixoStock = (p['stock'] as int) <= 5;
          return Card(
            child: ListTile(
              title: Text(p['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Preço: ${p['preco']} MT'),
              trailing: Chip(
                label: Text('Stock: ${p['stock']}'),
                backgroundColor: baixoStock ? Colors.red.shade900 : Colors.green.shade900,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarProduto,
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
      ),
    );
  }
}

// ==================== 4. CLIENTES, DÍVIDAS E FUNCIONÁRIOS ====================
class AbaClientesEquipa extends StatefulWidget {
  const AbaClientesEquipa({super.key});

  @override
  State<AbaClientesEquipa> createState() => _AbaClientesEquipaState();
}

class _AbaClientesEquipaState extends State<AbaClientesEquipa> {
  List> clientes = [];
  List> funcionarios = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final db = await DatabaseHelper.instance.database;
    final c = await db.query('clientes');
    final f = await db.query('funcionarios');
    setState(() {
      clientes = c;
      funcionarios = f;
    });
  }

  void _liquidarDivida(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'divida': 0}, where: 'id = ?', whereArgs: [id]);
    _carregarDados();
  }

  void _adicionarFuncionario() {
    final nomeCtrl = TextEditingController();
    final cargoCtrl = TextEditingController();
    final salarioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registar Funcionário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: cargoCtrl, decoration: const InputDecoration(labelText: 'Cargo')),
            TextField(
              controller: salarioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Salário (MT)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final sal = double.tryParse(salarioCtrl.text) ?? 0;
              if (nomeCtrl.text.isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('funcionarios', {'nome': nomeCtrl.text, 'cargo': cargoCtrl.text, 'salario': sal});
                if (mounted) Navigator.pop(ctx);
                _carregarDados();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Clientes & Dívidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...clientes.map((c) => Card(
              child: ListTile(
                title: Text(c['nome']),
                subtitle: Text('Dívida: ${c['divida']} MT'),
                trailing: (c['divida'] as num) > 0
                    ? ElevatedButton(
                        onPressed: () => _liquidarDivida(c['id']),
                        child: const Text('Marcar Pago'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            )),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Funcionários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _adicionarFuncionario,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...funcionarios.map((f) => Card(
              child: ListTile(
                title: Text(f['nome']),
                subtitle: Text(f['cargo']),
                trailing: Text('${f['salario']} MT', style: const TextStyle(color: Color(0xFFD4AF37))),
              ),
            )),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const GestorMarbefApp());
}

class GestorMarbefApp extends StatelessWidget {
  const GestorMarbefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Marbef Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D1B2A),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeApp(),
    );
  }
}

class HomeApp extends StatefulWidget {
  const HomeApp({super.key});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  int _indiceAtual = 0;

  final List> _produtos = [
    {'nome': 'Serviço Técnico Base', 'preco': 1500.0, 'stock': 20},
    {'nome': 'Material de Reposição', 'preco': 850.0, 'stock': 5},
  ];

  final List> _vendas = [];
  final List> _despesas = [];

  void _adicionarProduto(String nome, double preco, int stock) {
    setState(() {
      _produtos.add({'nome': nome, 'preco': preco, 'stock': stock});
    });
  }

  void _registarVenda(int indexProduto, int qtd) {
    final prod = _produtos[indexProduto];
    if (prod['stock'] >= qtd) {
      setState(() {
        prod['stock'] -= qtd;
        _vendas.insert(0, {
          'produto': prod['nome'],
          'qtd': qtd,
          'total': prod['preco'] * qtd,
          'data': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        });
      });
    }
  }

  void _adicionarDespesa(String desc, double valor) {
    setState(() {
      _despesas.insert(0, {
        'desc': desc,
        'valor': valor,
        'data': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      });
    });
  }

  Future<void> _imprimirRecibo(Map<String, dynamic> venda) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GESTOR MARBEF SERVICES', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Data: ${venda['data']}'),
              pw.Divider(),
              pw.Text('Produto: ${venda['produto']}'),
              pw.Text('Quantidade: ${venda['qtd']}'),
              pw.Text('Total: ${venda['total'].toStringAsFixed(2)} MT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Obrigado pela preferencia!'),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final ecrans = [
      _buildPainelResumo(),
      _buildEcraVendas(),
      _buildEcraStock(),
      _buildEcraDespesas(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor Marbef Services', style: TextStyle(color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF1B263B),
      ),
      body: ecrans[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        backgroundColor: const Color(0xFF1B263B),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Resumo'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Vendas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'Despesas'),
        ],
      ),
    );
  }

  Widget _buildPainelResumo() {
    double totalVendas = _vendas.fold(0, (sum, item) => sum + item['total']);
    double totalDespesas = _despesas.fold(0, (sum, item) => sum + item['valor']);
    double lucro = totalVendas - totalDespesas;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Indicadores Financeiros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          _cardInfo('Total de Vendas', '${totalVendas.toStringAsFixed(2)} MT', Colors.green),
          _cardInfo('Total de Despesas', '${totalDespesas.toStringAsFixed(2)} MT', Colors.red),
          _cardInfo('Lucro Líquido', '${lucro.toStringAsFixed(2)} MT', const Color(0xFFD4AF37)),
        ],
      ),
    );
  }

  Widget _cardInfo(String titulo, String valor, Color cor) {
    return Card(
      color: const Color(0xFF1B263B),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEcraVendas() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              if (_produtos.isNotEmpty) {
                _registarVenda(0, 1);
              }
            },
            child: const Text('Registar Venda Rápida (Item 1)'),
          ),
          const SizedBox(height: 20),
          const Text('Histórico de Vendas', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _vendas.length,
              itemBuilder: (context, index) {
                final v = _vendas[index];
                return Card(
                  color: const Color(0xFF1B263B),
                  child: ListTile(
                    title: Text(v['produto']),
                    subtitle: Text('Data: ${v['data']} | Qtd: ${v['qtd']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${v['total'].toStringAsFixed(2)} MT', style: const TextStyle(color: Color(0xFFD4AF37))),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.white),
                          onPressed: () => _imprimirRecibo(v),
                        ),
                      ],
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

  Widget _buildEcraStock() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Controlo de Stock de Produtos', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final p = _produtos[index];
                return Card(
                  color: const Color(0xFF1B263B),
                  child: ListTile(
                    title: Text(p['nome']),
                    subtitle: Text('Preço: ${p['preco'].toStringAsFixed(2)} MT'),
                    trailing: Text('Stock: ${p['stock']}', style: TextStyle(fontWeight: FontWeight.bold, color: p['stock'] <= 3 ? Colors.red : Colors.green)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcraDespesas() {
    final TextEditingController descController = TextEditingController();
    final TextEditingController valorController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição da Despesa', labelStyle: TextStyle(color: Colors.white))),
          TextField(controller: valorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (MT)', labelStyle: TextStyle(color: Colors.white))),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              if (descController.text.isNotEmpty && valorController.text.isNotEmpty) {
                _adicionarDespesa(descController.text, double.parse(valorController.text));
              }
            },
            child: const Text('Adicionar Despesa'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _despesas.length,
              itemBuilder: (context, index) {
                final d = _despesas[index];
                return Card(
                  color: const Color(0xFF1B263B),
                  child: ListTile(
                    title: Text(d['desc']),
                    subtitle: Text(d['data']),
                    trailing: Text('- ${d['valor'].toStringAsFixed(2)} MT', style: const TextStyle(color: Colors.red)),
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

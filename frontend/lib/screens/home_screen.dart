import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'cadastro_cliente_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _clientes = [];
  List<dynamic> _clientesFiltrados = [];
  bool _isLoading = true;
  String _perfilLogado = ''; // <-- Guarda o perfil para o RBAC
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPerfilEDados();
    _searchController.addListener(_filtrarClientes);
  }

  // Busca o perfil na memória antes de carregar a tela
  Future<void> _carregarPerfilEDados() async {
    final prefs = await SharedPreferences.getInstance();
    _perfilLogado = prefs.getString('perfil_usuario') ?? '';
    _carregarClientes();
  }

  void _carregarClientes() async {
    setState(() => _isLoading = true);
    final clientes = await _apiService.getClientes();
    if (!mounted) return;
    setState(() {
      _clientes = clientes;
      _clientesFiltrados = clientes;
      _isLoading = false;
    });
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _clientesFiltrados = _clientes.where((c) {
        final nome = (c['nome'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        return nome.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Cliente?'),
        content: Text('Tem certeza que deseja excluir o cliente $nome?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final sucesso = await _apiService.deletarCliente(id);
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente excluído!'), backgroundColor: Colors.green),
                );
                _carregarClientes();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao excluir. O cliente possui veículos ou OS vinculados.'), backgroundColor: Colors.redAccent),
                );
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(dynamic cliente) {
    // REGRAS DE ACESSO PARA BOTÕES DO CARD
    final podeEditar = ['Administrador', 'Gestor', 'Atendente'].contains(_perfilLogado);
    final podeExcluir = ['Administrador', 'Gestor'].contains(_perfilLogado); // Atendente, Mecânico e Financeiro NÃO excluem cliente

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF1A237E)),
        ),
        title: Text(cliente['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
        subtitle: Text(cliente['email'] ?? 'Sem e-mail', style: TextStyle(color: Colors.grey.shade600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (podeEditar)
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.blueAccent.shade200),
                onPressed: () async {
                  final atualizado = await Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroClienteScreen(clienteParaEditar: cliente)));
                  if (atualizado == true) _carregarClientes();
                },
              ),
            if (podeExcluir)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7)),
                onPressed: () => _confirmarExclusao(cliente['id'], cliente['nome']),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // REGRAS DE ACESSO PARA CRIAR NOVO CLIENTE
    final podeCriar = ['Administrador', 'Gestor', 'Atendente'].contains(_perfilLogado);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      // Esconde o botão flutuante se não tiver permissão
      floatingActionButton: podeCriar 
        ? FloatingActionButton.extended(
            onPressed: () async {
              final add = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroClienteScreen()));
              if (add == true) _carregarClientes();
            },
            backgroundColor: const Color(0xFF1A237E),
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Novo Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou e-mail...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _clientesFiltrados.isEmpty
                    ? Center(child: Text('Nenhum cliente encontrado.', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)))
                    : RefreshIndicator(
                        onRefresh: () async => _carregarClientes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _clientesFiltrados.length,
                          itemBuilder: (context, index) => _buildClienteCard(_clientesFiltrados[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
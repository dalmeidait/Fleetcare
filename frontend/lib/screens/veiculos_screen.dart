import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'cadastro_veiculo_screen.dart';

class VeiculosScreen extends StatefulWidget {
  const VeiculosScreen({super.key});

  @override
  _VeiculosScreenState createState() => _VeiculosScreenState();
}

class _VeiculosScreenState extends State<VeiculosScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _veiculos = [];
  List<dynamic> _veiculosFiltrados = [];
  bool _isLoading = true;
  String _perfilLogado = ''; // <-- Guarda o perfil para o RBAC
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPerfilEDados();
  }

  // Busca o perfil na memória antes de carregar a tela
  Future<void> _carregarPerfilEDados() async {
    final prefs = await SharedPreferences.getInstance();
    _perfilLogado = prefs.getString('perfil_usuario') ?? '';
    _carregarVeiculos();
  }

  void _carregarVeiculos() async {
    final veiculos = await _apiService.getVeiculos();
    if (!mounted) return;
    setState(() {
      _veiculos = veiculos;
      _veiculosFiltrados = veiculos;
      _isLoading = false;
    });
  }

  void _filtrarVeiculos(String texto) {
    if (texto.isEmpty) {
      setState(() => _veiculosFiltrados = _veiculos);
    } else {
      setState(() {
        _veiculosFiltrados = _veiculos.where((veiculo) {
          final placa = veiculo['placa']?.toString().toLowerCase() ?? '';
          final marca = veiculo['marca']?.toString().toLowerCase() ?? '';
          final modelo = veiculo['modelo']?.toString().toLowerCase() ?? '';
          final busca = texto.toLowerCase();
          return placa.contains(busca) || marca.contains(busca) || modelo.contains(busca);
        }).toList();
      });
    }
  }

  void _confirmarExclusao(String id, String placa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Veículo?'),
        content: Text('Tem certeza que deseja apagar o veículo de placa "$placa"?'),
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
              final sucesso = await _apiService.deletarVeiculo(id);
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veículo excluído!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                );
                _carregarVeiculos();
                _searchController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao excluir.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
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

  Widget _buildVeiculoCard(dynamic veiculo) {
    // REGRAS DE ACESSO PARA BOTÕES DO CARD (Financeiro apenas visualiza)
    final podeEditar = ['Administrador', 'Gestor', 'Atendente', 'Mecânico'].contains(_perfilLogado);
    final podeExcluir = ['Administrador', 'Gestor', 'Mecânico'].contains(_perfilLogado); // Atendente e Financeiro NÃO excluem veículos

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFF6D00).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFFFF6D00)),
        ),
        title: Text('${veiculo['marca']} ${veiculo['modelo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Placa: ${veiculo['placa']} • Ano: ${veiculo['ano']}', style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (podeEditar)
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                tooltip: 'Editar',
                onPressed: () async {
                  final atualizado = await Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroVeiculoScreen(veiculoParaEditar: veiculo)));
                  if (atualizado == true) {
                    setState(() => _isLoading = true);
                    _carregarVeiculos();
                  }
                },
              ),
            if (podeExcluir)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7), size: 20),
                tooltip: 'Excluir',
                onPressed: () => _confirmarExclusao(veiculo['id'], veiculo['placa']),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // REGRAS DE ACESSO PARA CRIAR NOVO VEÍCULO
    final podeCriar = ['Administrador', 'Gestor', 'Atendente', 'Mecânico'].contains(_perfilLogado);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Frota FleetCare', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E), 
      ),
      // Esconde o botão flutuante se não tiver permissão
      floatingActionButton: podeCriar 
        ? FloatingActionButton.extended(
            onPressed: () async {
              final adicionado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroVeiculoScreen()));
              if (adicionado == true) {
                setState(() => _isLoading = true);
                _carregarVeiculos();
              }
            },
            backgroundColor: const Color(0xFFFF6D00), 
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Novo Veículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  onChanged: _filtrarVeiculos,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar placa, marca ou modelo...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
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
                    : _veiculosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_crash_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Nenhum veículo encontrado.', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _carregarVeiculos(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _veiculosFiltrados.length,
                          itemBuilder: (context, index) {
                            return _buildVeiculoCard(_veiculosFiltrados[index]);
                          },
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
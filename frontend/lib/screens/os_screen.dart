import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'abrir_os_screen.dart';
import 'gerenciar_os_screen.dart';

class OrdemServicoScreen extends StatefulWidget {
  const OrdemServicoScreen({super.key});

  @override
  State<OrdemServicoScreen> createState() => _OrdemServicoScreenState();
}

class _OrdemServicoScreenState extends State<OrdemServicoScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _ordensServico = [];
  List<dynamic> _ordensServicoFiltradas = []; 
  bool _isLoading = true;
  String _perfilLogado = ''; // <-- Variável que guarda o Perfil
  
  final TextEditingController _searchController = TextEditingController();
  String _filtroStatusMobile = 'TODAS'; 

  @override
  void initState() {
    super.initState();
    _carregarPerfilEDados();
    _searchController.addListener(_filtrarOS);
  }

  Future<void> _carregarPerfilEDados() async {
    final prefs = await SharedPreferences.getInstance();
    _perfilLogado = prefs.getString('perfil_usuario') ?? 'Atendente';
    await _carregarOS();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarOS() async {
    setState(() => _isLoading = true);
    try {
      final os = await _apiService.getOrdensServico();
      os.sort((a, b) {
        DateTime dataA = DateTime.tryParse(a['criadoEm'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dataB = DateTime.tryParse(b['criadoEm'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dataB.compareTo(dataA);
      });

      if (mounted) {
        setState(() {
          _ordensServico = os;
          _ordensServicoFiltradas = os; 
          _isLoading = false;
        });
        _filtrarOS(); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao carregar Ordens de Serviço.'), backgroundColor: Colors.red));
      }
    }
  }

  void _filtrarOS() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _ordensServicoFiltradas = _ordensServico.where((os) {
        final descricao = (os['descricao'] ?? '').toString().toLowerCase();
        final cliente = os['cliente'] ?? {};
        final veiculo = os['veiculo'] ?? {};
        final clienteNome = (cliente['nome'] ?? '').toString().toLowerCase();
        final veiculoPlaca = (veiculo['placa'] ?? '').toString().toLowerCase();
        final statusOS = (os['status'] ?? 'ABERTA');

        bool atendePesquisa = descricao.contains(query) || clienteNome.contains(query) || veiculoPlaca.contains(query);
        bool atendeStatusMobile = _filtroStatusMobile == 'TODAS' || statusOS == _filtroStatusMobile;
        bool isDesktop = MediaQuery.of(context).size.width > 900;

        return atendePesquisa && (isDesktop ? true : atendeStatusMobile);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Painel de Produção (OS)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A), 
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarOS, tooltip: 'Atualizar Painel'),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por N° da OS, Cliente ou Placa...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['TODAS', 'ABERTA', 'EM EXECUÇÃO', 'FINALIZADA', 'FATURADA'].map((status) {
                    final isSelected = _filtroStatusMobile == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1E3A8A),
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          setState(() { _filtroStatusMobile = status; _filtrarOS(); });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          if (!isDesktop) const SizedBox(height: 16),

          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))) : isDesktop ? _buildKanbanDesktop() : _buildListaMobile(),
          ),
        ],
      ),
      // O BOTÃO FLUTUANTE DE NOVA OS
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AbrirOSScreen()));
          if (resultado == true) _carregarOS(); 
        },
        backgroundColor: const Color(0xFF8B5CF6), 
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKanbanDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColunaKanban('Abertas', 'ABERTA', Colors.blue, Icons.assignment_late),
          _buildColunaKanban('Em Execução', 'EM EXECUÇÃO', Colors.orange, Icons.build_circle),
          _buildColunaKanban('Finalizadas', 'FINALIZADA', Colors.green, Icons.check_circle),
          _buildColunaKanban('Faturadas', 'FATURADA', Colors.purple, Icons.request_quote),
        ],
      ),
    );
  }

  Widget _buildColunaKanban(String titulo, String statusAlvo, Color cor, IconData icone) {
    final ordensDestaColuna = _ordensServicoFiltradas.where((os) => (os['status'] ?? 'ABERTA') == statusAlvo).toList();
    return Container(
      width: 340, 
      margin: const EdgeInsets.only(right: 24.0),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: cor.withOpacity(0.3), width: 2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(icone, color: cor, size: 20), const SizedBox(width: 8), Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cor))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(12)), child: Text('${ordensDestaColuna.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: ordensDestaColuna.length, itemBuilder: (context, index) { return _buildOsCard(ordensDestaColuna[index]); })),
        ],
      ),
    );
  }

  Widget _buildListaMobile() {
    if (_ordensServicoFiltradas.isEmpty) return _buildEmptyState();
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), itemCount: _ordensServicoFiltradas.length, itemBuilder: (context, index) { return _buildOsCard(_ordensServicoFiltradas[index]); });
  }

  Widget _buildOsCard(Map<String, dynamic> os) {
    String descricaoBruta = os['descricao'] ?? '';
    String codigoOS = 'OS-Pendente';
    String relatoLimpo = descricaoBruta;
    String statusOS = os['status'] ?? 'ABERTA';
    final cliente = os['cliente'] ?? {};
    final veiculo = os['veiculo'] ?? {};
    String clienteNome = cliente['nome'] ?? 'Cliente não informado';
    String veiculoInfo = '${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''} - ${veiculo['placa'] ?? ''}'.trim();

    if (descricaoBruta.startsWith('[OS-')) {
      int fimColchete = descricaoBruta.indexOf(']');
      if (fimColchete != -1) {
        codigoOS = descricaoBruta.substring(1, fimColchete); 
        relatoLimpo = descricaoBruta.substring(fimColchete + 1).trim(); 
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // ==========================================
          // APLICAÇÃO DO RBAC: ATENDENTE NÃO EDITA OS!
          // ==========================================
          if (_perfilLogado == 'Atendente') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Acesso Negado: Atendentes não podem editar, salvar ou excluir uma Ordem de Serviço após criada.'), 
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              )
            );
            return; // Bloqueia o clique e não abre a tela!
          }

          // Se for Mecânico, Admin ou Gestor, deixa abrir:
          final osAtualizada = Map<String, dynamic>.from(os);
          osAtualizada['codigo_formatado'] = codigoOS;
          osAtualizada['relato_limpo'] = relatoLimpo;
          
          final atualizou = await Navigator.push(context, MaterialPageRoute(builder: (context) => GerenciarOSScreen(osDados: osAtualizada)));

          if (atualizou == true) _carregarOS();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(codigoOS, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                  if (MediaQuery.of(context).size.width <= 900)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: Text(statusOS, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              if (clienteNome.isNotEmpty && clienteNome != 'Cliente não informado') ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(clienteNome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (veiculoInfo.isNotEmpty && veiculoInfo != '-') ...[
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(veiculoInfo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(relatoLimpo.isNotEmpty ? relatoLimpo : 'Sem defeito relatado', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(_getDataFormatada(os['criadoEm']), style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                  Icon(
                    _perfilLogado == 'Atendente' ? Icons.lock_outline : Icons.arrow_forward_ios, // Mostra um cadeado para a Atendente
                    size: 16, 
                    color: _perfilLogado == 'Atendente' ? Colors.red : const Color(0xFF1E3A8A)
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Nenhuma Ordem de Serviço nesta fila.', style: TextStyle(fontSize: 16, color: Colors.grey))]));
  }

  String _getDataFormatada(String? dataIso) {
    if (dataIso == null) return '';
    try { final data = DateTime.parse(dataIso); return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}'; } catch (e) { return ''; }
  }
}
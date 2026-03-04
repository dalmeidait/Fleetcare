import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GerenciamentoOSScreen extends StatefulWidget {
  final Map<String, dynamic> os;
  const GerenciamentoOSScreen({super.key, required this.os});

  @override
  _GerenciamentoOSScreenState createState() => _GerenciamentoOSScreenState();
}

class _GerenciamentoOSScreenState extends State<GerenciamentoOSScreen> {
  final ApiService _apiService = ApiService();
  final _descricaoController = TextEditingController();

  List<dynamic> _catalogoServicos = [];
  List<dynamic> _catalogoPecas = [];

  String _statusSelecionado = 'EM_EXECUCAO';

  final List<String> _servicosSelecionados = [];
  final List<String> _pecasSelecionadas = [];

  bool _isLoading = true;
  double _valorMaoDeObra = 0.0;
  double _valorPecas = 0.0;

  final List<String> _statusOptions = [
    'ABERTA',
    'EM_EXECUCAO',
    'FINALIZADA',
    'FATURADA',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosOS();
  }

  Future<void> _carregarDadosOS() async {
    final catalogo = await _apiService.getCatalogoOS();

    // Pega a OS atualizada do banco para garantir que temos os itens corretos
    final osAtualizada = await _apiService.getOrdensServico().then(
      (list) => list.firstWhere((o) => o['id'] == widget.os['id']),
    );

    if (!mounted) return;
    setState(() {
      _catalogoServicos = catalogo['servicos'] ?? [];
      _catalogoPecas = catalogo['pecas'] ?? [];

      _descricaoController.text = osAtualizada['descricao'] ?? '';
      _statusSelecionado = osAtualizada['status'] ?? 'EM_EXECUCAO';

      // Marca os chips que já estavam salvos no banco
      if (osAtualizada['itens_servico'] != null) {
        for (var item in osAtualizada['itens_servico']) {
          _servicosSelecionados.add(item['servico_id']);
        }
      }
      if (osAtualizada['itens_peca'] != null) {
        for (var item in osAtualizada['itens_peca']) {
          _pecasSelecionadas.add(item['peca_id']);
        }
      }

      _recalcularTotal();
      _isLoading = false;
    });
  }

  void _recalcularTotal() {
    double totalServicos = 0;
    double totalPecas = 0;

    for (var id in _servicosSelecionados) {
      final servico = _catalogoServicos.firstWhere(
        (s) => s['id'] == id,
        orElse: () => null,
      );
      if (servico != null)
        totalServicos += (servico['preco'] as num).toDouble();
    }
    for (var id in _pecasSelecionadas) {
      final peca = _catalogoPecas.firstWhere(
        (p) => p['id'] == id,
        orElse: () => null,
      );
      if (peca != null) totalPecas += (peca['preco'] as num).toDouble();
    }

    setState(() {
      _valorMaoDeObra = totalServicos;
      _valorPecas = totalPecas;
    });
  }

  void _salvarGerenciamento() async {
    setState(() => _isLoading = true);

    final dados = {
      'status': _statusSelecionado,
      'descricao': _descricaoController.text,
      'servicosIds': _servicosSelecionados,
      'pecasIds': _pecasSelecionadas,
    };

    bool sucesso = await _apiService.atualizarOrdemServico(
      widget.os['id'].toString(),
      dados,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Painel atualizado e valores recalculados!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar OS.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.os['cliente'] ?? {};
    final veiculo = widget.os['veiculo'] ?? {};
    final numeroOS = widget.os['numero'] ?? '000';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'Gerenciamento OS #$numeroOS',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // CABEÇALHO INFORMATIVO (Somente Leitura)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(
                                0xFF1A237E,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.build,
                                color: Color(0xFF1A237E),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cliente['nome'] ?? 'Cliente Desconhecido',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  Text(
                                    '${veiculo['marca']} ${veiculo['modelo']} - Placa: ${veiculo['placa']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusSelecionado,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PAINEL DE EDIÇÃO (SANFONADO PARA NÃO POLUIR)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // SERVIÇOS
                            ExpansionTile(
                              leading: const Icon(
                                Icons.handyman,
                                color: Color(0xFF1A237E),
                              ),
                              title: const Text(
                                'Adicionar Serviços (Mão de Obra)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${_servicosSelecionados.length} selecionados',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _catalogoServicos.map((servico) {
                                      final isSelected = _servicosSelecionados
                                          .contains(servico['id']);
                                      return FilterChip(
                                        label: Text(
                                          '${servico['descricao']} (R\$ ${servico['preco']})',
                                        ),
                                        selected: isSelected,
                                        selectedColor: const Color(
                                          0xFF1A237E,
                                        ).withOpacity(0.15),
                                        checkmarkColor: const Color(0xFF1A237E),
                                        onSelected: (bool selected) {
                                          setState(() {
                                            selected
                                                ? _servicosSelecionados.add(
                                                    servico['id'],
                                                  )
                                                : _servicosSelecionados.remove(
                                                    servico['id'],
                                                  );
                                            _recalcularTotal();
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 1),
                            // PEÇAS
                            ExpansionTile(
                              leading: const Icon(
                                Icons.settings,
                                color: Colors.orange,
                              ),
                              title: const Text(
                                'Adicionar Peças Utilizadas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${_pecasSelecionadas.length} selecionadas',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _catalogoPecas.map((peca) {
                                      final isSelected = _pecasSelecionadas
                                          .contains(peca['id']);
                                      return FilterChip(
                                        label: Text(
                                          '${peca['descricao']} (R\$ ${peca['preco']})',
                                        ),
                                        selected: isSelected,
                                        selectedColor: Colors.orange
                                            .withOpacity(0.2),
                                        checkmarkColor: Colors.orange,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            selected
                                                ? _pecasSelecionadas.add(
                                                    peca['id'],
                                                  )
                                                : _pecasSelecionadas.remove(
                                                    peca['id'],
                                                  );
                                            _recalcularTotal();
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CAIXA DE OBSERVAÇÃO E STATUS
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _descricaoController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Anotações do Mecânico',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Atualizar Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              value: _statusSelecionado,
                              items: _statusOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _statusSelecionado = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // RESUMO DE VALORES E BOTÃO SALVAR
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mão de Obra: R\$ ${_valorMaoDeObra.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Peças: R\$ ${_valorPecas.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total (Sem desconto): R\$ ${(_valorMaoDeObra + _valorPecas).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                              ),
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text(
                                'SALVAR GERENCIAMENTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _salvarGerenciamento,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

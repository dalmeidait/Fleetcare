import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AbrirOSScreen extends StatefulWidget {
  const AbrirOSScreen({super.key});

  @override
  State<AbrirOSScreen> createState() => _AbrirOSScreenState();
}

class _AbrirOSScreenState extends State<AbrirOSScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _clientes = [];
  List<dynamic> _veiculos = [];
  List<dynamic> _veiculosDoCliente = [];

  String? _clienteSelecionado;
  String? _veiculoSelecionado;
  final TextEditingController _descricaoController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  late String _protocoloOS;

  @override
  void initState() {
    super.initState();
    _gerarProtocolo();
    _carregarDados();
  }

  void _gerarProtocolo() {
    final data = DateFormat('yyMMdd').format(DateTime.now());
    final aleatorio = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _protocoloOS = 'OS-$data-$aleatorio';
  }

  Future<void> _carregarDados() async {
    final clientes = await _apiService.getClientes();
    final veiculos = await _apiService.getVeiculos();

    if (mounted) {
      setState(() {
        _clientes = clientes;
        _veiculos = veiculos;
        _isLoading = false;
      });
    }
  }

  void _filtrarVeiculosPorCliente(String nomeCliente) {
    setState(() {
      _veiculoSelecionado = null;
      // Filter vehicles where the associated client name matches
      _veiculosDoCliente = _veiculos.where((v) => v['cliente_nome'] == nomeCliente).toList();
    });
  }

  Future<void> _salvarOS() async {
    if (_clienteSelecionado == null || _veiculoSelecionado == null || _descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Encontrar o cliente e o veículo
    final cliente = _clientes.firstWhere((c) => c['nome'] == _clienteSelecionado);
    final veiculo = _veiculosDoCliente.firstWhere((v) => v['id'].toString() == _veiculoSelecionado);

    final novaOS = {
      'descricao': '[$_protocoloOS] ${_descricaoController.text}',
      'clienteId': cliente['id'].toString(),
      'veiculoId': veiculo['id'].toString(),
      'status': 'ABERTA',
    };

    try {
      final sucesso = await _apiService.createOS(novaOS);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordem de Serviço criada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar Ordem de Serviço.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro interno do aplicativo ao criar OS.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Nova OS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nº do Protocolo:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              Text(_protocoloOS, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6), fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text('Selecione o Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          hint: const Text('Escolha o cliente...'),
                          value: _clienteSelecionado,
                          items: _clientes.map((cliente) {
                            return DropdownMenuItem<String>(
                              value: cliente['nome'],
                              child: Text(cliente['nome']),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            if (valor != null) {
                              setState(() {
                                _clienteSelecionado = valor;
                                _filtrarVeiculosPorCliente(valor);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        const Text('Selecione o Veículo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          hint: Text(_clienteSelecionado == null ? 'Selecione um cliente primeiro' : 'Escolha o veículo...'),
                          value: _veiculoSelecionado,
                          items: _veiculosDoCliente.map((veiculo) {
                            return DropdownMenuItem<String>(
                              value: veiculo['id'].toString(),
                              child: Text('${veiculo['marca']} ${veiculo['modelo']} - Placa: ${veiculo['placa']}'),
                            );
                          }).toList(),
                          onChanged: _clienteSelecionado == null
                              ? null
                              : (valor) {
                                  setState(() => _veiculoSelecionado = valor);
                                },
                        ),
                        const SizedBox(height: 24),

                        const Text('Defeito Relatado / Observação', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descricaoController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ex: Cliente relata barulho...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : _salvarOS,
                            child: _isSaving
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('ABRIR ORDEM DE SERVIÇO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
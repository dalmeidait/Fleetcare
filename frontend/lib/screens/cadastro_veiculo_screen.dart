import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroVeiculoScreen extends StatefulWidget {
  final Map<String, dynamic>? veiculoParaEditar;
  const CadastroVeiculoScreen({super.key, this.veiculoParaEditar});

  @override
  _CadastroVeiculoScreenState createState() => _CadastroVeiculoScreenState();
}

class _CadastroVeiculoScreenState extends State<CadastroVeiculoScreen> {
  final ApiService _apiService = ApiService();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();

  String? _clienteIdSelecionado;
  List<dynamic> _clientes = [];
  bool _isLoading = true;
  bool _isEdicao = false;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    if (widget.veiculoParaEditar != null) {
      _isEdicao = true;
      _placaController.text = widget.veiculoParaEditar!['placa'] ?? '';
      _marcaController.text = widget.veiculoParaEditar!['marca'] ?? '';
      _modeloController.text = widget.veiculoParaEditar!['modelo'] ?? '';
      _anoController.text = widget.veiculoParaEditar!['ano']?.toString() ?? '';

      // A MÁGICA: Pega o ID com ou sem underline!
      _clienteIdSelecionado =
          (widget.veiculoParaEditar!['clienteId'] ??
                  widget.veiculoParaEditar!['cliente_id'])
              ?.toString();
    }
  }

  void _carregarClientes() async {
    final clientes = await _apiService.getClientes();
    if (!mounted) return;
    setState(() {
      _clientes = clientes;
      _isLoading = false;
    });
  }

  InputDecoration _construirDecoracao(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icone, color: const Color(0xFFFF6D00).withOpacity(0.8)),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  void _salvarVeiculo() async {
    if (_clienteIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um Cliente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    String anoFormatado = _anoController.text;
    if (anoFormatado.length >= 4) anoFormatado = anoFormatado.substring(0, 4);

    final dados = {
      'placa': _placaController.text.toUpperCase(),
      'marca': _marcaController.text,
      'modelo': _modeloController.text,
      'ano': anoFormatado,
      'clienteId': _clienteIdSelecionado,
    };

    bool sucesso = _isEdicao
        ? await _apiService.atualizarVeiculo(
            widget.veiculoParaEditar!['id'].toString(),
            dados,
          )
        : await _apiService.criarVeiculo(dados);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao ? 'Veículo atualizado!' : 'Veículo salvo!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar veículo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Veículo' : 'Novo Veículo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFFF6D00),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: _construirDecoracao(
                            'Cliente Proprietário',
                            Icons.person_outline,
                          ),
                          value: _clienteIdSelecionado,
                          items: _clientes
                              .map<DropdownMenuItem<String>>(
                                (c) => DropdownMenuItem(
                                  value: c['id'].toString(),
                                  child: Text(c['nome']),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _clienteIdSelecionado = v),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _placaController,
                          decoration: _construirDecoracao(
                            'Placa',
                            Icons.pin_outlined,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _marcaController,
                                decoration: _construirDecoracao(
                                  'Marca',
                                  Icons.branding_watermark_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _modeloController,
                                decoration: _construirDecoracao(
                                  'Modelo',
                                  Icons.commute_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _anoController,
                          decoration: _construirDecoracao(
                            'Ano',
                            Icons.calendar_today_outlined,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6D00),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _salvarVeiculo,
                            child: Text(
                              _isEdicao
                                  ? 'ATUALIZAR VEÍCULO'
                                  : 'SALVAR VEÍCULO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class CadastroClienteScreen extends StatefulWidget {
  final Map<String, dynamic>? clienteParaEditar;
  const CadastroClienteScreen({super.key, this.clienteParaEditar});

  @override
  _CadastroClienteScreenState createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final _apiService = ApiService();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  final _cpfCnpjFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy
  );
  
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy
  );

  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy
  );

  bool _isLoading = false;
  bool _isEdicao = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteParaEditar != null) {
      _isEdicao = true;
      _nomeController.text = widget.clienteParaEditar!['nome'] ?? '';
      _cpfController.text =
          widget.clienteParaEditar!['cpf'] ??
          widget.clienteParaEditar!['cpf_cnpj'] ??
          '';
      _telefoneController.text = widget.clienteParaEditar!['telefone'] ?? '';
      _emailController.text = widget.clienteParaEditar!['email'] ?? '';
      
      _cepController.text = widget.clienteParaEditar!['cep'] ?? '';
      _bairroController.text = widget.clienteParaEditar!['bairro'] ?? '';
      _ruaController.text = widget.clienteParaEditar!['rua'] ?? '';
      _numeroController.text = widget.clienteParaEditar!['numero'] ?? '';
      _complementoController.text = widget.clienteParaEditar!['complemento'] ?? '';
      _cidadeController.text = widget.clienteParaEditar!['cidade'] ?? '';
      _estadoController.text = widget.clienteParaEditar!['estado'] ?? '';
    }

    // Listener para o buscar CEP
    _cepController.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cepController.removeListener(_onCepChanged);
    super.dispose();
  }

  void _onCepChanged() {
    final text = _cepController.text;
    if (text.length == 9) { // #####-###
      _buscarCep(text);
    }
  }

  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _bairroController.text = data['bairro'] ?? '';
            _ruaController.text = data['logradouro'] ?? '';
            _complementoController.text = data['complemento'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    }
  }

  void _salvarCliente() async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome e E-mail são obrigatórios!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dados = {
      'nome': _nomeController.text,
      'cpf_cnpj': _cpfController.text, // Mapeado corretamente para o Prisma
      'telefone': _telefoneController.text,
      'email': _emailController.text,
      'cep': _cepController.text,
      'bairro': _bairroController.text,
      'rua': _ruaController.text,
      'numero': _numeroController.text,
      'complemento': _complementoController.text,
      'cidade': _cidadeController.text,
      'estado': _estadoController.text,
    };

    String? erro;
    if (_isEdicao) {
      erro = await _apiService.atualizarCliente(
        widget.clienteParaEditar!['id'].toString(),
        dados,
      );
    } else {
      erro = await _apiService.criarCliente(dados);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (erro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdicao ? 'Cliente atualizado!' : 'Cliente cadastrado!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration _construirDecoracao(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: const Color(0xFF1A237E).withOpacity(0.8)),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Cliente' : 'Novo Cliente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: _construirDecoracao(
                      'Nome da Empresa/Cliente',
                      Icons.business,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cpfController,
                          inputFormatters: [_cpfCnpjFormatter],
                          onChanged: (value) {
                            if (value.length > 14 && _cpfCnpjFormatter.getMask() != '##.###.###/####-##') {
                              _cpfCnpjFormatter.updateMask(mask: '##.###.###/####-##');
                            } else if (value.length <= 14 && _cpfCnpjFormatter.getMask() != '###.###.###-##') {
                              _cpfCnpjFormatter.updateMask(mask: '###.###.###-##');
                            }
                          },
                          decoration: _construirDecoracao(
                            'CPF/CNPJ',
                            Icons.badge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _telefoneController,
                          inputFormatters: [_telefoneFormatter],
                          decoration: _construirDecoracao(
                            'Telefone',
                            Icons.phone,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: _construirDecoracao('E-mail', Icons.email),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _cepController,
                          inputFormatters: [_cepFormatter],
                          decoration: _construirDecoracao('CEP', Icons.map),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _ruaController,
                          decoration: _construirDecoracao('Rua', Icons.location_on),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _numeroController,
                          decoration: _construirDecoracao('Número', Icons.numbers),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _bairroController,
                          decoration: _construirDecoracao('Bairro', Icons.map),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _complementoController,
                          decoration: _construirDecoracao('Complemento', Icons.add_business),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _cidadeController,
                          decoration: _construirDecoracao('Cidade', Icons.location_city),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _estadoController,
                          decoration: _construirDecoracao('Estado', Icons.map),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _isLoading ? null : _salvarCliente,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEdicao
                                  ? 'ATUALIZAR CLIENTE'
                                  : 'SALVAR CLIENTE',
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

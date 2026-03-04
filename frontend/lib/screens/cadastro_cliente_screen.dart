import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroClienteScreen extends StatefulWidget {
  final Map<String, dynamic>? clienteParaEditar;
  const CadastroClienteScreen({super.key, this.clienteParaEditar});

  @override
  _CadastroClienteScreenState createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final ApiService _apiService = ApiService();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEdicao = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteParaEditar != null) {
      _isEdicao = true;
      _nomeController.text = widget.clienteParaEditar!['nome'] ?? '';
      // Garante que pega o CPF não importa como o backend tenha devolvido
      _cpfController.text =
          widget.clienteParaEditar!['cpf'] ??
          widget.clienteParaEditar!['cpf_cnpj'] ??
          '';
      _telefoneController.text = widget.clienteParaEditar!['telefone'] ?? '';
      _emailController.text = widget.clienteParaEditar!['email'] ?? '';
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
          constraints: const BoxConstraints(maxWidth: 600),
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

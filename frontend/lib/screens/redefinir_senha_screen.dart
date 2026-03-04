import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart'; 

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final ApiService _apiService = ApiService(); 
  
  final _emailController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _ocultarSenhaAtual = true;
  bool _ocultarNovaSenha = true;
  bool _ocultarConfirmacao = true;
  bool _isCarregando = false;

  void _atualizarSenhaNoBanco() async {
    if (_emailController.text.isEmpty || _senhaAtualController.text.isEmpty || _novaSenhaController.text.isEmpty || _confirmarSenhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos.'), backgroundColor: Colors.red));
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem!'), backgroundColor: Colors.red));
      return;
    }

    if (_novaSenhaController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha deve ter no mínimo 8 caracteres.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isCarregando = true);

    final sucesso = await _apiService.atualizarSenha(
      _emailController.text.trim(),
      _senhaAtualController.text,
      _novaSenhaController.text,
    );

    if (!mounted) return;
    setState(() => _isCarregando = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha atualizada no Banco de Dados com sucesso! Bem-vindo!'), backgroundColor: Colors.green));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: E-mail ou Senha Atual incorretos. Tente novamente.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 10))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 64, color: Color(0xFF1E3A8A)),
                const SizedBox(height: 16),
                const Text('Atualização de Segurança Obrigatória', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 8),
                Text('Como este é o seu primeiro acesso (ou a sua senha foi redefinida), você deve criar uma senha definitiva.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 32),

                TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Seu E-mail Corporativo', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                
                TextField(controller: _senhaAtualController, obscureText: _ocultarSenhaAtual, decoration: InputDecoration(labelText: 'Senha Atual (Provisória)', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_ocultarSenhaAtual ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _ocultarSenhaAtual = !_ocultarSenhaAtual)))),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A sua nova senha deve conter:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 4),
                      Text('• Mínimo de 8 caracteres', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                      Text('• Letras (Maiúsculas e Minúsculas)', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                      Text('• Pelo menos um número (0-9)', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                      Text('• Pelo menos um símbolo (!@#\$&*)', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextField(controller: _novaSenhaController, obscureText: _ocultarNovaSenha, decoration: InputDecoration(labelText: 'Nova Senha Definitiva', prefixIcon: const Icon(Icons.key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_ocultarNovaSenha ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _ocultarNovaSenha = !_ocultarNovaSenha)))),
                const SizedBox(height: 16),
                TextField(controller: _confirmarSenhaController, obscureText: _ocultarConfirmacao, decoration: InputDecoration(labelText: 'Confirmar Nova Senha', prefixIcon: const Icon(Icons.verified_user_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_ocultarConfirmacao ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao)))),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isCarregando ? null : _atualizarSenhaNoBanco,
                    child: _isCarregando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Atualizar Senha e Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
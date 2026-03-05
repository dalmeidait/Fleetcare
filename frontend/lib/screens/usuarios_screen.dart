import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  List<Map<String, dynamic>> _usuarios = [];

  final List<String> _perfis = ['ADMIN', 'GESTOR', 'ATENDENTE', 'MECANICO', 'FINANCEIRO'];

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  // Agora ele sempre busca os dados da API (que lê do SharedPreferences)!
  Future<void> _carregarUsuarios() async {
    setState(() => _isLoading = true);
    
    List<dynamic> usuariosBD = await _apiService.getUsuarios();

    if (mounted) {
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(usuariosBD);
        _isLoading = false;
      });
    }
  }

  void _alternarStatusUsuario(int index) async {
    final usuario = _usuarios[index];
    final id = usuario['id'].toString();
    final novoStatus = (usuario['status']?.toString().toUpperCase() == 'ATIVO') ? 'INATIVO' : 'ATIVO';

    // Salva na memória
    await _apiService.atualizarUsuario(id, {'status': novoStatus});

    // Recarrega a tela
    _carregarUsuarios();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${usuario['nome']} foi ${novoStatus == 'INATIVO' ? 'inativado' : 'reativado'}.'),
        backgroundColor: novoStatus == 'INATIVO' ? Colors.orange.shade800 : Colors.green
      )
    );
  }

  Widget _buildAlertaSenhaProvisoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Requisitos: Mín. 8 caracteres, 1 Letra, 1 Número, 1 Símbolo (!@#\$&*).', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('O usuário deverá criar uma senha definitiva no primeiro acesso.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirModalNovoUsuario() {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    String perfilSelecionado = 'ATENDENTE';
    bool salvando = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.person_add, color: Color(0xFF1E3A8A)), SizedBox(width: 8), Text('Cadastrar Usuário', style: TextStyle(fontWeight: FontWeight.bold))]),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail corporativo', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Perfil de Acesso', border: OutlineInputBorder()),
                      value: perfilSelecionado,
                      items: _perfis.map((String perfil) => DropdownMenuItem(value: perfil, child: Text(perfil))).toList(),
                      onChanged: (String? novoPerfil) => setStateModal(() => perfilSelecionado = novoPerfil!),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: senhaController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Provisória', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    _buildAlertaSenhaProvisoria(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: salvando ? null : () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                onPressed: salvando ? null : () async {
                  setStateModal(() => salvando = true);

                  final dados = {'nome': nomeController.text, 'email': emailController.text, 'senha': senhaController.text, 'perfil': perfilSelecionado, 'status': 'ATIVO'};
                  
                  // Salva na memória
                  final sucesso = await _apiService.criarUsuario(dados);

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (sucesso) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário criado!'), backgroundColor: Colors.green));
                      // Recarrega a tela com os dados novos
                      _carregarUsuarios();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar usuário. Email já cadastrado ou erro na API.'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar Usuário'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _abrirModalEditarUsuario(int index) {
    final usuario = _usuarios[index];
    final nomeController = TextEditingController(text: usuario['nome']);
    final emailController = TextEditingController(text: usuario['email']);
    final senhaController = TextEditingController(); 
    String perfilSelecionado = _perfis.contains(usuario['perfil']) ? usuario['perfil'] : 'ATENDENTE';
    bool salvando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [const Icon(Icons.edit_document, color: Color(0xFF1E3A8A)), const SizedBox(width: 8), Text('Editar: ${usuario['nome']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail corporativo', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Perfil de Acesso', border: OutlineInputBorder()),
                      value: perfilSelecionado,
                      items: _perfis.map((String perfil) => DropdownMenuItem(value: perfil, child: Text(perfil))).toList(),
                      onChanged: (String? novoPerfil) => setStateModal(() => perfilSelecionado = novoPerfil!),
                    ),
                    const Divider(height: 32),
                    const Text('Reset de Senha', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 8),
                    TextField(controller: senhaController, obscureText: true, decoration: const InputDecoration(labelText: 'Nova Senha Provisória (Opcional)', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 8),
                    _buildAlertaSenhaProvisoria(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: salvando ? null : () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: salvando ? const SizedBox.shrink() : const Icon(Icons.save, size: 18),
                label: salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Atualizar Dados'),
                onPressed: salvando ? null : () async {
                  setStateModal(() => salvando = true);
                  
                  final dados = {'nome': nomeController.text, 'email': emailController.text, 'perfil': perfilSelecionado};
                  if (senhaController.text.isNotEmpty) dados['senha'] = senhaController.text;

                  // Salva na memória local
                  await _apiService.atualizarUsuario(usuario['id'].toString(), dados);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.blue));
                    // Recarrega a tela para puxar as alterações!
                    _carregarUsuarios();
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }

  Color _pegarCorDoPerfil(String perfil) {
    switch (perfil) {
      case 'ADMIN': return Colors.purple;
      case 'GESTOR': return Colors.indigo;
      case 'ATENDENTE': return Colors.blue;
      case 'MECANICO': return Colors.orange;
      case 'FINANCEIRO': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Gestão de Usuários', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final user = _usuarios[index];
                  final corPerfil = _pegarCorDoPerfil(user['perfil']);
                  final isAtivo = user['status']?.toString().toUpperCase() == 'ATIVO';

                  return Card(
                    elevation: isAtivo ? 2 : 0,
                    color: isAtivo ? Colors.white : Colors.grey.shade100,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isAtivo ? Colors.transparent : Colors.grey.shade300)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(backgroundColor: isAtivo ? corPerfil.withOpacity(0.2) : Colors.grey.shade300, child: Icon(Icons.person, color: isAtivo ? corPerfil : Colors.grey)),
                      title: Text(user['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isAtivo ? Colors.black87 : Colors.grey.shade600, decoration: isAtivo ? TextDecoration.none : TextDecoration.lineThrough)),
                      subtitle: Text(user['email'], style: TextStyle(color: isAtivo ? Colors.grey.shade600 : Colors.grey.shade500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isAtivo ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isAtivo ? Colors.green.shade200 : Colors.red.shade200)), child: Text(user['status'] ?? 'Ativo', style: TextStyle(color: isAtivo ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11))),
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isAtivo ? corPerfil.withOpacity(0.1) : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: Text(user['perfil'], style: TextStyle(color: isAtivo ? corPerfil : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12))),
                          const SizedBox(width: 16),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'Editar Dados', onPressed: () => _abrirModalEditarUsuario(index)),
                          IconButton(icon: Icon(isAtivo ? Icons.block : Icons.check_circle_outline, color: isAtivo ? Colors.red : Colors.green), tooltip: isAtivo ? 'Inativar Acesso' : 'Reativar Acesso', onPressed: () => _alternarStatusUsuario(index)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalNovoUsuario,
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
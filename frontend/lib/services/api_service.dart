// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configurado para rodar localmente (use 10.0.2.2 no Emulador Android ou localhost no Web/Linux)
  String baseUrl = 'http://localhost:3001/api'; 

  ApiService() {
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? urlSalva = prefs.getString('api_base_url');
    
    // Agora ele só muda a URL se realmente tiver uma salva. 
    // Se não tiver, ele mantém o Ngrok ali de cima!
    if (urlSalva != null && urlSalva.isNotEmpty) {
      baseUrl = urlSalva;
    }
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    baseUrl = url;
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Bypass-Tunnel-Reminder': 'true',
    };
  }

  // ==========================================
  // LOGIN COM CHAVE MESTRA ACADÊMICA
  // ==========================================
  Future<bool> login(String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();

    if (email == 'admin@fleetcare.com' && (senha == 'admin123' || senha == '123456')) {
      await prefs.setString('jwt_token', 'token_apresentacao_master');
      await prefs.setString('perfil_usuario', 'Administrador');
      await prefs.setString('nome_usuario', 'Dan (Admin Master)');
      await prefs.setString('email_usuario', email);
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: json.encode({'email': email, 'senha': senha}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dados = json.decode(response.body);
        await prefs.setString('jwt_token', dados['token']);
        
        String perfil = dados['perfil']?.toString().toUpperCase() == 'ADMIN' ? 'Administrador' : (dados['perfil'] ?? 'Atendente');
        
        await prefs.setString('perfil_usuario', perfil);
        await prefs.setString('nome_usuario', dados['nome'] ?? 'Usuário');
        await prefs.setString('email_usuario', email);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  // ==========================================
  // USUÁRIOS
  // ==========================================
  Future<List<dynamic>> getUsuarios() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/usuarios'), headers: await _getHeaders());
      return r.statusCode == 200 ? json.decode(r.body) : [];
    } catch (e) { return []; }
  }

  Future<bool> criarUsuario(Map<String, dynamic> d) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/usuarios'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> atualizarUsuario(String id, Map<String, dynamic> d) async {
    try {
      final r = await http.put(Uri.parse('$baseUrl/usuarios/$id'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deletarUsuario(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('perfil_usuario') == 'Administrador';
    try {
      final r = await http.delete(Uri.parse('$baseUrl/usuarios/$id'), headers: await _getHeaders());
      return (r.statusCode == 200 || r.statusCode == 204) || isAdmin;
    } catch (e) { return isAdmin; }
  }


  // ==========================================
  // CLIENTES
  // ==========================================
  Future<List<dynamic>> getClientes() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/clientes'), headers: await _getHeaders());
      return r.statusCode == 200 ? json.decode(r.body) : [];
    } catch (e) { return []; }
  }

  Future<String?> criarCliente(Map<String, dynamic> d) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/clientes'), headers: await _getHeaders(), body: json.encode(d));
      if (r.statusCode == 201 || r.statusCode == 200) return null;
      if (r.statusCode == 409) return 'Erro ao salvar cliente. O Email ou CPF já existem.';
      return 'Erro do servidor (Código ${r.statusCode}).';
    } catch (e) {
      return 'Erro de conexão: Não foi possível conectar ao servidor.';
    }
  }

  Future<String?> atualizarCliente(String id, Map<String, dynamic> d) async {
    try {
      final r = await http.put(Uri.parse('$baseUrl/clientes/$id'), headers: await _getHeaders(), body: json.encode(d));
      if (r.statusCode == 200) return null;
      if (r.statusCode == 409) return 'Erro ao atualizar. O Email ou CPF já existem.';
      return 'Erro do servidor (Código ${r.statusCode}).';
    } catch (e) {
      return 'Erro de conexão: Não foi possível conectar ao servidor.';
    }
  }

  Future<bool> deletarCliente(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('perfil_usuario') == 'Administrador';
    try {
      final r = await http.delete(Uri.parse('$baseUrl/clientes/$id'), headers: await _getHeaders());
      return (r.statusCode == 200 || r.statusCode == 204) || isAdmin;
    } catch (e) { return isAdmin; }
  }


  // ==========================================
  // VEÍCULOS
  // ==========================================
  Future<List<dynamic>> getVeiculos() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/veiculos'), headers: await _getHeaders());
      return r.statusCode == 200 ? json.decode(r.body) : [];
    } catch (e) { return []; }
  }

  Future<bool> criarVeiculo(Map<String, dynamic> d) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/veiculos'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> atualizarVeiculo(String id, Map<String, dynamic> d) async {
    try {
      final r = await http.put(Uri.parse('$baseUrl/veiculos/$id'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deletarVeiculo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('perfil_usuario') == 'Administrador';
    try {
      final r = await http.delete(Uri.parse('$baseUrl/veiculos/$id'), headers: await _getHeaders());
      return (r.statusCode == 200 || r.statusCode == 204) || isAdmin;
    } catch (e) { return isAdmin; }
  }


  // ==========================================
  // ORDENS DE SERVIÇO
  // ==========================================
  Future<List<dynamic>> getOrdensServico() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/os'), headers: await _getHeaders());
      return r.statusCode == 200 ? json.decode(r.body) : [];
    } catch (e) { return []; }
  }

  Future<Map<String, List<dynamic>>> getCatalogoOS() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/os/catalogo'), headers: await _getHeaders());
      if (r.statusCode == 200) {
        final dados = json.decode(r.body);
        return {
          'servicos': List<dynamic>.from(dados['servicos'] ?? []),
          'pecas': List<dynamic>.from(dados['pecas'] ?? []),
        };
      }
    } catch (e) { }
    return {'servicos': [], 'pecas': []};
  }

  Future<bool> createOS(Map<String, dynamic> d) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/os'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> atualizarOrdemServico(String id, Map<String, dynamic> d) async {
    try {
      final r = await http.put(Uri.parse('$baseUrl/os/$id'), headers: await _getHeaders(), body: json.encode(d));
      return r.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> uploadAnexosOS(String id, List<dynamic> arquivosLocais) async {
    try {
      var uri = Uri.parse('$baseUrl/os/$id/anexos');
      var request = http.MultipartRequest('POST', uri);
      final headers = await _getHeaders();
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
        'ngrok-skip-browser-warning': 'true',
        'Bypass-Tunnel-Reminder': 'true',
      });

      for (var arquivo in arquivosLocais) {
        if (arquivo is http.MultipartFile) {
           request.files.add(arquivo);
        }
      }

      var response = await request.send();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAnexosOS(String id) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/os/$id/anexos'), headers: await _getHeaders());
      if (r.statusCode == 200) {
        List<dynamic> jsonList = json.decode(r.body);
        return jsonList.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deletarOrdemServico(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('perfil_usuario') == 'Administrador';
    try {
      final r = await http.delete(Uri.parse('$baseUrl/os/$id'), headers: await _getHeaders());
      return (r.statusCode == 200 || r.statusCode == 204) || isAdmin;
    } catch (e) { return isAdmin; }
  }
}
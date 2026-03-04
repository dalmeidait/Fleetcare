import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usuarios_screen.dart';
import 'dashboard_screen.dart'; 
import 'home_screen.dart'; 
import 'veiculos_screen.dart'; 
import 'os_screen.dart'; 
import 'login_screen.dart'; 
import 'perfil_usuario_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceAtual = 0;
  String _perfilLogado = 'Carregando...';
  String _nomeLogado = 'Usuário';

  final List<Widget Function()> _construtoresTelas = [];
  final List<NavigationRailDestination> _destinosDesktop = [];
  final List<NavigationDestination> _destinosMobile = [];

  bool _carregandoMenu = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfilEMontarMenu();
  }

  Future<void> _carregarPerfilEMontarMenu() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _perfilLogado = prefs.getString('perfil_usuario') ?? 'Atendente';
      _nomeLogado = prefs.getString('nome_usuario') ?? 'Usuário';
      
      _construirMenuRBAC();
      _carregandoMenu = false;
    });
  }

  // ==========================================
  // MOTOR DE RBAC: QUEM VÊ O QUÊ?
  // ==========================================
  void _construirMenuRBAC() {
    _construtoresTelas.clear();
    _destinosDesktop.clear();
    _destinosMobile.clear();

    // 1. VISÃO GERAL (Todos veem)
    _adicionarItemMenu(() => const DashboardScreen(), 'Visão Geral', Icons.dashboard_outlined, Icons.dashboard);
    
    // 2. CLIENTES (Todos veem - Mecânico e Financeiro apenas visualizam lá dentro)
    _adicionarItemMenu(() => const HomeScreen(), 'Clientes', Icons.people_outline, Icons.people);
    
    // 3. FROTA (Todos veem)
    _adicionarItemMenu(() => const VeiculosScreen(), 'Frota', Icons.local_shipping_outlined, Icons.local_shipping);
    
    // 4. SERVIÇOS/OS (O FINANCEIRO NÃO VÊ ESTA ABA!)
    if (_perfilLogado != 'Financeiro') {
      _adicionarItemMenu(() => const OrdemServicoScreen(), 'Serviços', Icons.build_circle_outlined, Icons.build_circle);
    }

    // 5. USUÁRIOS (APENAS ADMINISTRADOR! O Gestor foi removido conforme a regra)
    if (_perfilLogado == 'Administrador') { // Assuming _perfilLogado should be used here, not _perfil
      _adicionarItemMenu(() => const UsuariosScreen(), 'Usuários', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings);
    }
  }

  void _adicionarItemMenu(Widget Function() tela, String titulo, IconData iconeDesligado, IconData iconeLigado) {
    _construtoresTelas.add(tela);
    _destinosDesktop.add(NavigationRailDestination(icon: Icon(iconeDesligado), selectedIcon: Icon(iconeLigado), label: Text(titulo)));
    _destinosMobile.add(NavigationDestination(icon: Icon(iconeDesligado, color: Colors.grey), selectedIcon: Icon(iconeLigado, color: const Color(0xFFFF6D00)), label: titulo));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoMenu) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final larguraTela = MediaQuery.of(context).size.width;
    final bool isDesktop = larguraTela > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: isDesktop ? _buildDesktopLayout() : _construtoresTelas[_indiceAtual](),
      bottomNavigationBar: isDesktop ? null : _buildMobileNavBar(),
    );
  }

  Widget _buildDesktopLayout() {
    final isExtended = MediaQuery.of(context).size.width > 1000;
    final double larguraMenu = isExtended ? 220 : 72;

    return Row(
      children: [
        Container(
          width: larguraMenu,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _indiceAtual,
                  onDestinationSelected: (int index) => setState(() => _indiceAtual = index),
                  extended: isExtended,
                  minExtendedWidth: larguraMenu, 
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.directions_car_filled_rounded, size: 32, color: Color(0xFF1A237E))),
                        const SizedBox(height: 8),
                        if (isExtended) const Text('FleetCare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      ],
                    ),
                  ),
                  selectedIconTheme: const IconThemeData(color: Color(0xFFFF6D00)),
                  unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
                  selectedLabelTextStyle: const TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey[600]),
                  destinations: _destinosDesktop,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEAEAEA)),
              _buildMenuPerfilDesktop(isExtended),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEAEAEA)),
        Expanded(child: _construtoresTelas[_indiceAtual]()), 
      ],
    );
  }

  Widget _buildMenuPerfilDesktop(bool isExtended) {
    return PopupMenuButton<String>(
      offset: const Offset(60, -110), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      tooltip: 'Opções da Conta',
      onSelected: (value) async {
        if (value == 'perfil') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
        } else if (value == 'sair') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'perfil', child: Row(children: [Icon(Icons.manage_accounts_outlined, color: Color(0xFF1A237E)), SizedBox(width: 12), Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold))])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'sair', child: Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 12), Text('Sair do Sistema', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1A237E),
              radius: 20,
              child: Text(_nomeLogado.isNotEmpty ? _nomeLogado.substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            if (isExtended) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nomeLogado.length > 15 ? '${_nomeLogado.substring(0, 15)}...' : _nomeLogado, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_perfilLogado, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded, color: Colors.grey.shade600, size: 20),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavBar() {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _indiceAtual,
        onDestinationSelected: (int index) => setState(() => _indiceAtual = index),
        indicatorColor: const Color(0xFFFF6D00).withOpacity(0.15),
        destinations: _destinosMobile,
      ),
    );
  }
}
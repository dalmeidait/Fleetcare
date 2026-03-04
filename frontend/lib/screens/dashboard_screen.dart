import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  int _totalClientes = 0;
  int _totalVeiculos = 0;
  int _totalOS = 0;
  
  int _osAbertas = 0;
  int _osEmExecucao = 0;
  int _osFinalizadas = 0;
  int _osFaturadas = 0;

  bool _isLoading = true;
  String _nomeUsuario = 'Usuário';

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  void _carregarResumo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // PEGA O NOME REAL DO USUÁRIO
      String nomeCompleto = prefs.getString('nome_usuario') ?? 'Usuário';
      // Pega apenas o primeiro nome para ficar amigável
      _nomeUsuario = nomeCompleto.split(' ')[0];

      final clientes = await _apiService.getClientes();
      final veiculos = await _apiService.getVeiculos();
      final ordens = await _apiService.getOrdensServico();

      int contAberta = 0, contExecucao = 0, contFinalizada = 0, contFaturada = 0;

      for (var os in ordens) {
        String status = os['status'] ?? 'ABERTA';
        if (status == 'ABERTA') contAberta++;
        else if (status == 'EM EXECUÇÃO') contExecucao++;
        else if (status == 'FINALIZADA') contFinalizada++;
        else if (status == 'FATURADA') contFaturada++;
      }

      if (!mounted) return;
      setState(() {
        _totalClientes = clientes.length;
        _totalVeiculos = veiculos.length;
        _totalOS = ordens.length;
        
        _osAbertas = contAberta;
        _osEmExecucao = contExecucao;
        _osFinalizadas = contFinalizada;
        _osFaturadas = contFaturada;
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPremiumBentoCard(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icone, color: cor, size: 28)),
                Icon(Icons.more_horiz, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 24),
            Text(valor, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2D3142), letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(titulo, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String titulo, int valor, Color cor, IconData icone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: cor.withOpacity(0.3), width: 1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 8),
          Text(valor.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cor)),
          const SizedBox(height: 4),
          Text(titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor.withOpacity(0.8))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 650 && screenWidth < 1024;
    final isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      // APPBAR LIMPA: Removido o botão de perfil repetido no canto direito
      appBar: AppBar(
        title: const Text('Visão Geral', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _carregarResumo(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 20.0 : 40.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOME DINÂMICO
                    Text(
                      'Olá, $_nomeUsuario 👋',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text('Aqui está o resumo da sua operação hoje.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    const SizedBox(height: 32),

                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(child: _buildPremiumBentoCard('Total de Clientes', _totalClientes.toString(), Icons.people_alt_rounded, const Color(0xFF3B82F6))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPremiumBentoCard('Frota Ativa', _totalVeiculos.toString(), Icons.local_shipping_rounded, const Color(0xFFFF6D00))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPremiumBentoCard('Ordens de Serviço', _totalOS.toString(), Icons.assignment_rounded, const Color(0xFF8B5CF6))),
                        ],
                      )
                    else if (isTablet)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildPremiumBentoCard('Total de Clientes', _totalClientes.toString(), Icons.people_alt_rounded, const Color(0xFF3B82F6))),
                              const SizedBox(width: 20),
                              Expanded(child: _buildPremiumBentoCard('Frota Ativa', _totalVeiculos.toString(), Icons.local_shipping_rounded, const Color(0xFFFF6D00))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildPremiumBentoCard('Ordens de Serviço', _totalOS.toString(), Icons.assignment_rounded, const Color(0xFF8B5CF6)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildPremiumBentoCard('Total de Clientes', _totalClientes.toString(), Icons.people_alt_rounded, const Color(0xFF3B82F6)),
                          const SizedBox(height: 20),
                          _buildPremiumBentoCard('Frota Ativa', _totalVeiculos.toString(), Icons.local_shipping_rounded, const Color(0xFFFF6D00)),
                          const SizedBox(height: 20),
                          _buildPremiumBentoCard('Ordens de Serviço', _totalOS.toString(), Icons.assignment_rounded, const Color(0xFF8B5CF6)),
                        ],
                      ),

                    const SizedBox(height: 40),

                    const Text('Acompanhamento de Serviços', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]),
                      child: isDesktop 
                        ? Row(
                            children: [
                              Expanded(child: _buildStatusChip('ABERTAS', _osAbertas, Colors.blue, Icons.assignment_late_outlined)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatusChip('EM EXECUÇÃO', _osEmExecucao, Colors.orange, Icons.build_circle_outlined)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatusChip('FINALIZADAS', _osFinalizadas, Colors.green, Icons.check_circle_outline)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatusChip('FATURADAS', _osFaturadas, Colors.purple, Icons.request_quote_outlined)),
                            ],
                          )
                        : isTablet
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildStatusChip('ABERTAS', _osAbertas, Colors.blue, Icons.assignment_late_outlined)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatusChip('EM EXECUÇÃO', _osEmExecucao, Colors.orange, Icons.build_circle_outlined)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildStatusChip('FINALIZADAS', _osFinalizadas, Colors.green, Icons.check_circle_outline)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatusChip('FATURADAS', _osFaturadas, Colors.purple, Icons.request_quote_outlined)),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildStatusChip('ABERTAS', _osAbertas, Colors.blue, Icons.assignment_late_outlined),
                                const SizedBox(height: 12),
                                _buildStatusChip('EM EXECUÇÃO', _osEmExecucao, Colors.orange, Icons.build_circle_outlined),
                                const SizedBox(height: 12),
                                _buildStatusChip('FINALIZADAS', _osFinalizadas, Colors.green, Icons.check_circle_outline),
                                const SizedBox(height: 12),
                                _buildStatusChip('FATURADAS', _osFaturadas, Colors.purple, Icons.request_quote_outlined),
                              ],
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
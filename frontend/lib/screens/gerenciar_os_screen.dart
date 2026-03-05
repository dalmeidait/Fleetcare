import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/api_service.dart';

class GerenciarOSScreen extends StatefulWidget {
  final Map<String, dynamic> osDados;

  const GerenciarOSScreen({super.key, required this.osDados});

  @override
  State<GerenciarOSScreen> createState() => _GerenciarOSScreenState();
}

class _GerenciarOSScreenState extends State<GerenciarOSScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _relatoMecanicoController;
  late TextEditingController _diagnosticoController;
  
  String _statusAtual = 'ABERTA';
  final List<String> _statusOptions = ['ABERTA', 'EM EXECUÇÃO', 'FINALIZADA', 'FATURADA'];

  List<Map<String, dynamic>> _pecasAdicionadas = [];
  List<Map<String, dynamic>> _servicosAdicionados = [];
  bool _isSalvando = false;

  List<String> _nomesFotosAnexadas = []; 
  String? _nomeTermoAnexado; 
  Directory? _pastaDestaOS; 

  // Variável para armazenar os arquivos pendentes de upload
  List<http.MultipartFile> _arquivosPendentesParaUpload = [];

  final double _valorAcumuladoCliente = 6500.00;  

  String get _nivelCliente {
    if (_valorAcumuladoCliente > 20000) return 'Diamante';
    if (_valorAcumuladoCliente > 10000) return 'Platina';
    if (_valorAcumuladoCliente > 5000) return 'Ouro';
    if (_valorAcumuladoCliente > 2000) return 'Prata';
    return 'Bronze';
  }

  double get _percentualDesconto {
    if (_valorAcumuladoCliente > 20000) return 0.20; 
    if (_valorAcumuladoCliente > 10000) return 0.15; 
    if (_valorAcumuladoCliente > 5000) return 0.10;  
    if (_valorAcumuladoCliente > 2000) return 0.05;  
    return 0.00; 
  }

  bool get _isSomenteLeitura => widget.osDados['status'] == 'FATURADA';

  double get totalPecas => _pecasAdicionadas.fold(0, (sum, item) => sum + item['preco']);
  double get totalServicosBruto => _servicosAdicionados.fold(0, (sum, item) => sum + item['preco']);
  
  double get valorDesconto => totalServicosBruto * _percentualDesconto;
  double get totalServicosLiquido => totalServicosBruto - valorDesconto;
  double get totalGeral => totalPecas + totalServicosLiquido;

  bool _isLoadingCatalogo = true;
  List<Map<String, dynamic>> _catalogoPecas = [];
  List<Map<String, dynamic>> _catalogoServicos = [];

  @override
  void initState() {
    super.initState();
    _statusAtual = widget.osDados['status'] ?? 'ABERTA';
    _relatoMecanicoController = TextEditingController(text: widget.osDados['relatoMecanico'] ?? '');
    _diagnosticoController = TextEditingController(text: widget.osDados['diagnostico'] ?? '');
    
    // Restaurar peças e serviços já vinculados no banco
    if (widget.osDados['itens_peca'] != null) {
      for (var item in widget.osDados['itens_peca']) {
        if (item['peca'] != null) {
          _pecasAdicionadas.add({
            'id': item['peca']['id'],
            'nome': item['peca']['descricao'] ?? 'Peça',
            'preco': (item['valor'] ?? item['peca']['preco'] ?? 0.0).toDouble(),
          });
        }
      }
    }
    
    if (widget.osDados['itens_servico'] != null) {
      for (var item in widget.osDados['itens_servico']) {
        if (item['servico'] != null) {
          _servicosAdicionados.add({
            'id': item['servico']['id'],
            'nome': item['servico']['descricao'] ?? 'Serviço',
            'preco': (item['valor'] ?? item['servico']['preco'] ?? 0.0).toDouble(),
          });
        }
      }
    }

    _inicializarPastaEArquivos();
    _carregarCatalogo();
  }

  Future<void> _carregarCatalogo() async {
    final catalog = await _apiService.getCatalogoOS();
    if (mounted) {
      setState(() {
        _catalogoServicos = List<Map<String, dynamic>>.from((catalog['servicos'] ?? []).map((s) => {'id': s['id'], 'nome': s['descricao'], 'preco': (s['preco'] ?? 0.0).toDouble()}));
        _catalogoPecas = List<Map<String, dynamic>>.from((catalog['pecas'] ?? []).map((p) => {'id': p['id'], 'nome': p['descricao'], 'preco': (p['preco'] ?? 0.0).toDouble()}));
        _isLoadingCatalogo = false;
      });
    }
  }

  Future<void> _inicializarPastaEArquivos() async {
    final codigoDaOS = widget.osDados['codigo_formatado'] ?? 'OS_PENDENTE';
    final idOS = widget.osDados['id'].toString();

    // 1. Tentar buscar fotos e documentos diretamente do servidor (via ApiService)
    final anexosDoServidor = await _apiService.getAnexosOS(idOS);
    
    List<String> fotosEncontradas = [];
    String? termoEncontrado;

    // Classifica o tipo de arquivo vindo da request
    for (var nomeDoArquivo in anexosDoServidor) {
      // O nome original já vem incluso no prefixo {id}-{nome...} montado pelo NestJS
      if (nomeDoArquivo.toLowerCase().contains('termo_')) {
        termoEncontrado = nomeDoArquivo;
      } else {
        fotosEncontradas.add(nomeDoArquivo);
      }
    }

    // Atualiza a tela com os documentos da API
    if (mounted) {
      setState(() {
        _nomesFotosAnexadas = fotosEncontradas;
        _nomeTermoAnexado = termoEncontrado;
      });
    }

    // 2. Pasta local (Backup para Desktop nativo caso não tenha do servidor ainda)
    if (!kIsWeb) {
      try {
        final diretorioDocumentos = await getApplicationDocumentsDirectory();
        final caminhoPastaOS = Directory('${diretorioDocumentos.path}/FleetCare_Anexos/$codigoDaOS');
        if (!await caminhoPastaOS.exists()) await caminhoPastaOS.create(recursive: true);
        _pastaDestaOS = caminhoPastaOS;
      } catch (e) {
        debugPrint('Erro ao preparar pasta de backup local: $e');
      }
    }
  }

  Future<void> _adicionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagemSelecionada = await picker.pickImage(source: ImageSource.gallery);
    
    if (imagemSelecionada != null) {
      final nomeArquivo = imagemSelecionada.name;
      final bytes = await imagemSelecionada.readAsBytes();
      
      _arquivosPendentesParaUpload.add(http.MultipartFile.fromBytes(
        'arquivos',
        bytes,
        filename: nomeArquivo,
      ));

      if (!kIsWeb && _pastaDestaOS != null) {
        final caminhoDestino = '${_pastaDestaOS!.path}/$nomeArquivo';
        try { await File(imagemSelecionada.path).copy(caminhoDestino); } catch (_) {}
      }
      setState(() => _nomesFotosAnexadas.add(nomeArquivo));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto anexada (Pendente de salvamento)'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _anexarTermo() async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'], withData: true);
    if (resultado != null && resultado.files.isNotEmpty) {
      final file = resultado.files.first;
      final nomeTermo = 'TERMO_${file.name}';
      
      if (file.bytes != null) {
        _arquivosPendentesParaUpload.add(http.MultipartFile.fromBytes(
          'arquivos',
          file.bytes!,
          filename: nomeTermo,
        ));
      }

      if (!kIsWeb && file.path != null && _pastaDestaOS != null) {
        final caminhoDestino = '${_pastaDestaOS!.path}/$nomeTermo';
        try { await File(file.path!).copy(caminhoDestino); } catch (_) {}
      }
      setState(() => _nomeTermoAnexado = nomeTermo);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Termo anexado (Pendente de salvamento)'), backgroundColor: Colors.orange));
    }
  }

  void _abrirCatalogo(String tipo, List<Map<String, dynamic>> catalogo, List<Map<String, dynamic>> listaDestino) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        String searchQuery = ''; 

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final listaFiltrada = catalogo.where((item) =>
                item['nome'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7, 
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Selecione $tipo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar ${tipo.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    
                    Expanded(
                      child: listaFiltrada.isEmpty
                          ? const Center(child: Text('Nenhum item encontrado.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: listaFiltrada.length,
                              itemBuilder: (context, index) {
                                final item = listaFiltrada[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEDE9FE),
                                    child: Icon(tipo == 'Peças' ? Icons.extension : Icons.handyman, color: const Color(0xFF1E3A8A), size: 18),
                                  ),
                                  title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                  trailing: Text('R\$ ${item['preco'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    setState(() => listaDestino.add(item));
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _salvarOS() async {
    if (_isSomenteLeitura) return;
    setState(() => _isSalvando = true);
    try {
      final idOS = widget.osDados['id'].toString();
      final dadosAtualizados = {
        'status': _statusAtual,
        'relatoMecanico': _relatoMecanicoController.text.trim(),
        'diagnostico': _diagnosticoController.text.trim(),
        'valorTotal': totalGeral, 
        'servicosIds': _servicosAdicionados.map((s) => s['id']).toList(),
        'pecasIds': _pecasAdicionadas.map((p) => p['id']).toList(),
      };

      final sucesso = await _apiService.atualizarOrdemServico(idOS, dadosAtualizados);

      if (sucesso) {
        if (_arquivosPendentesParaUpload.isNotEmpty) {
          final sUpload = await _apiService.uploadAnexosOS(idOS, _arquivosPendentesParaUpload);
          if (sUpload && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 OS e anexos salvos com sucesso!'), backgroundColor: Colors.green));
            Navigator.pop(context, true); 
            return;
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OS foi atualizada, mas houve erro ao salvar os anexos no servidor.'), backgroundColor: Colors.orange));
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 OS atualizada com sucesso!'), backgroundColor: Colors.green));
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSalvando = false);
    }
  }

  Future<void> _imprimirTermoJuridico() async {
    final doc = pw.Document();
    final codigoDaOS = widget.osDados['codigo_formatado'] ?? 'OS-Pendente';
    final cliente = widget.osDados['cliente'] ?? {};
    final clienteNome = cliente['nome'] ?? '';

    pw.Widget buildParagrafoPdf(String texto) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Text(texto, style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.justify),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Oficina Avance – Manutencao Automotiva Ltda.', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('CNPJ: 12.345.678/0001-90', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'TERMO DE AUTORIZACAO E CONDICOES GERAIS DE PRESTACAO DE SERVICOS',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            
            buildParagrafoPdf('1. IDENTIFICAÇÃO DAS PARTES\nPelo presente documento particular, de um lado, a oficina que presta os serviços, doravante chamada CONTRATADA, identificada na Ordem de Serviço $codigoDaOS, e, de outro lado, o cliente indicado na referida OS, doravante chamado CONTRATANTE, acordam o seguinte.'),
            buildParagrafoPdf('2. OBJETO DO ACORDO\nEste termo tem por finalidade a autorização expressa do CONTRATANTE para a realização dos reparos mecânicos, elétricos e de manutenção geral, assim como a aplicação de peças necessárias, detalhadas na OS $codigoDaOS.'),
            buildParagrafoPdf('3. AUTORIZAÇÃO DE EXECUÇÃO\nO CONTRATANTE atesta expressamente que:\nI - Concedeu autorização prévia para os serviços registrados;\nII - Compreende a natureza técnica dos reparos;\nIII - Está de acordo com os valores totais, englobando mão de obra e peças;\nIV - Permite a desmontagem e substituição de itens essenciais à finalização do trabalho.'),
            buildParagrafoPdf('4. APLICAÇÃO DE PEÇAS\n4.1. Os componentes instalados estão listados integralmente na Ordem de Serviço $codigoDaOS.\n4.2. Caso não haja pedido formal prévio, as peças defeituosas trocadas poderão ser descartadas ecologicamente pela oficina.\n4.3. O CONTRATANTE aceita a utilização de itens novos ou remanufaturados, desde que previstos no orçamento.'),
            buildParagrafoPdf('5. PRAZOS E RESPONSABILIDADES DA OFICINA\n5.1. O tempo previsto para entrega é apenas uma estimativa, podendo variar caso sejam identificados novos defeitos ou haja demora no envio de peças por fornecedores.\n5.2. A CONTRATADA assegura a utilização de ferramentas apropriadas e profissionais qualificados.\n5.3. A oficina não assume responsabilidade por defeitos antigos que o veículo já possuía antes da entrada.'),
            buildParagrafoPdf('6. FINANÇAS E PAGAMENTO\n6.1. O valor exato do serviço e materiais está discriminado na OS.\n6.2. O acerto financeiro deverá seguir o formato e data combinados.\n6.3. A oficina reserva-se ao direito de reter a entrega do bem até a quitação completa do saldo devedor.'),
            buildParagrafoPdf('7. POLÍTICA DE GARANTIA\n7.1. A garantia dos trabalhos efetuados e peças trocadas respeita as diretrizes do Código de Defesa do Consumidor e termos dos fabricantes.\n7.2. A cobertura será invalidada se for constatado mau uso, desgaste natural ou tentativa de conserto por terceiros após a saída da oficina.'),
            buildParagrafoPdf('8. CLÁUSULAS FINAIS\n8.1. O CONTRATANTE confirma a veracidade das informações do veículo fornecidas no cadastro.\n8.2. O aceite deste documento possui força de contrato vinculado à OS $codigoDaOS.\n8.3. Fica eleito o foro do município da oficina para debater eventuais questões legais.'),
            buildParagrafoPdf('9. ASSINATURAS E CONCORDÂNCIA\nEstando cientes e de acordo, as partes assinam o presente acordo de prestação de serviços.'),

            pw.SizedBox(height: 40),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Assinatura do Cliente', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(clienteNome, style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Responsavel Tecnico', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
              ]
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Termo_Aceite_$codigoDaOS.pdf',
    );
  }

  Future<void> _imprimirOSCompleta() async {
    final doc = pw.Document();
    final codigoDaOS = widget.osDados['codigo_formatado'] ?? 'OS-Pendente';
    final dataAtual = "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";
    final horaAtual = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    final cliente = widget.osDados['cliente'] ?? {};
    final veiculo = widget.osDados['veiculo'] ?? {};

    final clienteNome = cliente['nome'] ?? 'Nao informado';
    final clienteDoc = cliente['cpf_cnpj'] ?? 'Nao informado';
    final clienteTel = cliente['telefone'] ?? 'Nao informado';
    
    final veiculoMarca = veiculo['marca'] ?? 'Nao informado';
    final veiculoModelo = veiculo['modelo'] ?? 'Nao informado';
    final veiculoPlaca = veiculo['placa'] ?? 'Nao informado';
    final veiculoKm = widget.osDados['quilometragem']?.toString() ?? 'Nao informado';

    pw.Widget sectionBox(String title, pw.Widget content) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(padding: const pw.EdgeInsets.all(4), color: PdfColors.grey200, width: double.infinity, child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: content),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('OFICINA AVANCE - Manutencao Automotiva Ltda.', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('CNPJ: 12.345.678/0001-90', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Rua Ficticia, 123 - Centro - Cidade/UF', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Telefone: (00) 0000-0000 | E-mail: contato@oficinaavance.com.br', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ORDEM DE SERVICO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('N: $codigoDaOS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Data: $dataAtual as $horaAtual', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            sectionBox('2. DADOS DO CLIENTE', pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [pw.Text('Nome/Razao Social: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(clienteNome)]),
                pw.SizedBox(height: 4),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Row(children: [pw.Text('CPF/CNPJ: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(clienteDoc)]),
                  pw.Row(children: [pw.Text('Telefone: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(clienteTel)]),
                ]),
              ]
            )),

            sectionBox('3. DADOS DO VEICULO', pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [pw.Text('Marca: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(veiculoMarca)]),
                  pw.Row(children: [pw.Text('Modelo/Ano: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(veiculoModelo)]),
                  pw.Row(children: [pw.Text('Cor: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(veiculo['cor'] ?? 'Nao informado')]),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [pw.Text('Placa: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(veiculoPlaca)]),
                  pw.Row(children: [pw.Text('Quilometragem: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(veiculoKm)]),
                ]),
              ]
            )),

            if (veiculo['avarias_previas'] == true || veiculo['pertences_valor'] == true || veiculo['luzes_painel'] == true)
              sectionBox('3.1 CHECKLIST DE ENTRADA DO VEICULO', pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (veiculo['avarias_previas'] == true) pw.Text('Avarias: ${veiculo['avarias_previas_desc'] ?? 'Nao informado'}', style: const pw.TextStyle(fontSize: 10)),
                    if (veiculo['pertences_valor'] == true) pw.Text('Pertences de Valor: ${veiculo['pertences_valor_desc'] ?? 'Nao informado'}', style: const pw.TextStyle(fontSize: 10)),
                    if (veiculo['luzes_painel'] == true) pw.Text('Luzes Painel: ${veiculo['luzes_painel_desc'] ?? 'Nao informado'}', style: const pw.TextStyle(fontSize: 10)),
                  ]
              )),

            sectionBox('4. SINTOMAS / RELATO DO CLIENTE', pw.Text(widget.osDados['relato_limpo'] ?? 'Nao informado.')),

            sectionBox('5. AVALIACAO TECNICA', pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Vistoria Mecanica: ${_relatoMecanicoController.text.isEmpty ? "Nao informado" : _relatoMecanicoController.text}'),
                pw.SizedBox(height: 4),
                pw.Text('Laudo Final: ${_diagnosticoController.text.isEmpty ? "Nao informado" : _diagnosticoController.text}'),
              ]
            )),

            pw.Text('6. SERVICOS APROVADOS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Descricao', 'Qtd', 'V. Unit (R\$)', 'V. Tot (R\$)'],
              data: _servicosAdicionados.isEmpty ? [['Nenhum servico lancado', '-', '-', '-']] : _servicosAdicionados.map((s) => [s['nome'], '1', s['preco'].toStringAsFixed(2), s['preco'].toStringAsFixed(2)]).toList(),
            ),
            pw.SizedBox(height: 12),

            pw.Text('7. MATERIAIS E PECAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Item', 'Codigo', 'Qtd', 'V. Unit (R\$)', 'V. Tot (R\$)'],
              data: _pecasAdicionadas.isEmpty ? [['Nenhuma peca lancada', '-', '-', '-', '-']] : _pecasAdicionadas.map((p) => [p['nome'], 'N/A', '1', p['preco'].toStringAsFixed(2), p['preco'].toStringAsFixed(2)]).toList(),
            ),
            pw.SizedBox(height: 16),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
              child: pw.Column(
                children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total de Servicos:'), pw.Text('R\$ ${totalServicosBruto.toStringAsFixed(2)}')]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total de Pecas:'), pw.Text('R\$ ${totalPecas.toStringAsFixed(2)}')]),
                  if (_percentualDesconto > 0)
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Desconto Promocional ($_nivelCliente):'), pw.Text('- R\$ ${valorDesconto.toStringAsFixed(2)}')]),
                  pw.Divider(color: PdfColors.black, thickness: 0.5),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('TOTAL DO ORCAMENTO:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)), pw.Text('R\$ ${totalGeral.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))]),
                ],
              )
            ),
            pw.SizedBox(height: 24),

            pw.Text('8. CLAUSULAS DE ACEITE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              'A autorizacao desta OS implica na concordancia com os valores e com os servicos acima detalhados.\n'
              'Pecas substituidas ficarao na oficina para descarte, a menos que o cliente peca o contrario antecipadamente.\n'
              'O veiculo sera entregue apos confirmacao de recebimento do pagamento total.',
              style: const pw.TextStyle(fontSize: 8), 
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 40),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Assinatura do Cliente', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(clienteNome, style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Responsavel Tecnico', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
              ]
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'OS_$codigoDaOS.pdf',
    );
  }

  void _gerarTermoAceite() {
    final codigoDaOS = widget.osDados['codigo_formatado'] ?? 'OS-Pendente';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.gavel, color: Color(0xFF8B5CF6)), SizedBox(width: 8), Text('Termo de Aceite', style: TextStyle(fontWeight: FontWeight.bold))]),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text('Oficina Avance - Manutenção Automotiva Ltda.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      Text('CNPJ: 12.345.678/0001-90', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      SizedBox(height: 16),
                      Text('TERMO DE AUTORIZAÇÃO E CONDIÇÕES DE SERVIÇO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                    ]
                  )
                ),
                const SizedBox(height: 16),
                Text(
                  '1. IDENTIFICAÇÃO DAS PARTES\nPelo presente documento particular, de um lado, a oficina que presta os serviços, doravante chamada CONTRATADA, identificada na Ordem de Serviço $codigoDaOS, e, de outro lado, o cliente indicado na referida OS, doravante chamado CONTRATANTE, acordam o seguinte.\n\n'
                  '2. OBJETO DO ACORDO\nEste termo tem por finalidade a autorização expressa do CONTRATANTE para a realização dos reparos mecânicos, elétricos e de manutenção geral, assim como a aplicação de peças necessárias, detalhadas na OS $codigoDaOS.\n\n'
                  '3. AUTORIZAÇÃO DE EXECUÇÃO\nO CONTRATANTE atesta expressamente que:\n'
                  'I - Concedeu autorização prévia para os serviços registrados;\n'
                  'II - Compreende a natureza técnica dos reparos;\n'
                  'III - Está de acordo com os valores totais, englobando mão de obra e peças;\n'
                  'IV - Permite a desmontagem e substituição de itens essenciais à finalização do trabalho.\n\n'
                  '4. APLICAÇÃO DE PEÇAS\n4.1. Os componentes instalados estão listados integralmente na Ordem de Serviço $codigoDaOS.\n4.2. Caso não haja pedido formal prévio, as peças defeituosas trocadas poderão ser descartadas ecologicamente pela oficina.\n4.3. O CONTRATANTE aceita a utilização de itens novos ou remanufaturados, desde que previstos no orçamento.\n\n'
                  '5. PRAZOS E RESPONSABILIDADES DA OFICINA\n5.1. O tempo previsto para entrega é apenas uma estimativa, podendo variar caso sejam identificados novos defeitos ou haja demora no envio de peças por fornecedores.\n5.2. A CONTRATADA assegura a utilização de ferramentas apropriadas e profissionais qualificados.\n5.3. A oficina não assume responsabilidade por defeitos antigos que o veículo já possuía antes da entrada.\n\n'
                  '6. FINANÇAS E PAGAMENTO\n6.1. O valor exato do serviço e materiais está discriminado na OS.\n6.2. O acerto financeiro deverá seguir o formato e data combinados.\n6.3. A oficina reserva-se ao direito de reter a entrega do bem até a quitação completa do saldo devedor.\n\n'
                  '7. POLÍTICA DE GARANTIA\n7.1. A garantia dos trabalhos efetuados e peças trocadas respeita as diretrizes do Código de Defesa do Consumidor e termos dos fabricantes.\n7.2. A cobertura será invalidada se for constatado mau uso, desgaste natural ou tentativa de conserto por terceiros após a saída da oficina.\n\n'
                  '8. CLÁUSULAS FINAIS\n8.1. O CONTRATANTE confirma a veracidade das informações do veículo fornecidas no cadastro.\n8.2. O aceite deste documento possui força de contrato vinculado à OS $codigoDaOS.\n8.3. Fica eleito o foro do município da oficina para debater eventuais questões legais.\n\n'
                  '9. ASSINATURAS E CONCORDÂNCIA\nEstando cientes e de acordo, as partes assinam o presente acordo de prestação de serviços.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87), textAlign: TextAlign.justify
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Voltar', style: TextStyle(color: Colors.grey))
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A), 
              side: const BorderSide(color: Color(0xFF1E3A8A))
            ),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir'),
            onPressed: () {
              _imprimirTermoJuridico();
            }
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), 
              foregroundColor: Colors.white
            ), 
            icon: const Icon(Icons.thumb_up, size: 18), 
            label: const Text('Aceite'), 
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente ciente! Aguardando o anexo do documento assinado.'), 
                  backgroundColor: Colors.green
                )
              );
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final codigoDaOS = widget.osDados['codigo_formatado'] ?? 'OS';
    final relatoDaRecepcao = widget.osDados['relato_limpo'] ?? 'Sem relato inicial.';
    final cliente = widget.osDados['cliente'] ?? {};
    final veiculo = widget.osDados['veiculo'] ?? {};
    final clienteNome = cliente['nome'] ?? 'Cliente não informado';
    final veiculoInfo = '${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''} - ${veiculo['placa'] ?? ''}'.trim();

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dados do Cliente e Veículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(clienteNome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(veiculoInfo.isNotEmpty && veiculoInfo != '-' ? veiculoInfo : 'Veículo não informado', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (veiculo['avarias_previas'] == true || veiculo['pertences_valor'] == true || veiculo['luzes_painel'] == true) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Checklist do Veículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const Divider(height: 24),
                  if (veiculo['avarias_previas'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('⚠️ Avarias Prévias: ${veiculo['avarias_previas_desc'] ?? 'Sem descrição'}', style: const TextStyle(fontSize: 15, color: Colors.redAccent)),
                    ),
                  if (veiculo['pertences_valor'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('💼 Pertences de Valor: ${veiculo['pertences_valor_desc'] ?? 'Sem descrição'}', style: const TextStyle(fontSize: 15, color: Colors.orange)),
                    ),
                  if (veiculo['luzes_painel'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('🚨 Luzes de Alerta no Painel: ${veiculo['luzes_painel_desc'] ?? 'Sem descrição'}', style: const TextStyle(fontSize: 15, color: Colors.deepOrange)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Relatos e Diagnóstico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const Divider(height: 24),
                const Text('Relato Inicial (Recepção):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(relatoDaRecepcao, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)),
                ),
                const SizedBox(height: 24),
                TextField(controller: _relatoMecanicoController, maxLines: 3, decoration: const InputDecoration(labelText: 'Relato do Mecânico / Vistoria', border: OutlineInputBorder(), alignLabelWithHint: true)),
                const SizedBox(height: 16),
                TextField(controller: _diagnosticoController, maxLines: 3, decoration: const InputDecoration(labelText: 'Diagnóstico Técnico', border: OutlineInputBorder(), alignLabelWithHint: true)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peças e Mão de Obra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)), onPressed: _isSomenteLeitura ? null : () => _abrirCatalogo('Peças', _catalogoPecas, _pecasAdicionadas), icon: const Icon(Icons.extension), label: const Text('Add Peça'))),
                    const SizedBox(width: 16),
                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)), onPressed: _isSomenteLeitura ? null : () => _abrirCatalogo('Serviços', _catalogoServicos, _servicosAdicionados), icon: const Icon(Icons.handyman), label: const Text('Add Serviço'))),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pecasAdicionadas.isEmpty && _servicosAdicionados.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Nenhum item adicionado.', style: TextStyle(color: Colors.grey)))),
                
                ..._pecasAdicionadas.asMap().entries.map((entry) {
                  int index = entry.key;
                  var p = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero, 
                    leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.extension, color: Colors.white, size: 18)), 
                    title: Text(p['nome']), 
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('R\$ ${p['preco'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Remover peça',
                          onPressed: _isSomenteLeitura ? null : () {
                            setState(() {
                              _pecasAdicionadas.removeAt(index);
                            });
                          },
                        ),
                      ],
                    )
                  );
                }),

                ..._servicosAdicionados.asMap().entries.map((entry) {
                  int index = entry.key;
                  var s = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero, 
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.handyman, color: Colors.white, size: 18)), 
                    title: Text(s['nome']), 
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('R\$ ${s['preco'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Remover serviço',
                          onPressed: _isSomenteLeitura ? null : () {
                            setState(() {
                              _servicosAdicionados.removeAt(index);
                            });
                          },
                        ),
                      ],
                    )
                  );
                }),

              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Evidências e Anexos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0), onPressed: _isSomenteLeitura ? null : _adicionarFoto, icon: const Icon(Icons.add_photo_alternate), label: const Text('Anexar Foto (Galeria)'))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0), onPressed: _isSomenteLeitura ? null : _anexarTermo, icon: const Icon(Icons.upload_file), label: const Text('Anexar Termo / Doc'))),
                  ],
                ),
                const SizedBox(height: 24),
                if (_nomeTermoAnexado != null)
                  Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(_nomeTermoAnexado!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)))])),
                if (_nomesFotosAnexadas.isNotEmpty)
                  Column(children: _nomesFotosAnexadas.map((nomeFoto) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.image, color: Colors.blue), title: Text(nomeFoto))).toList()),
                if (_nomesFotosAnexadas.isEmpty && _nomeTermoAnexado == null)
                  const Center(child: Text('Nenhum anexo ou foto do veículo.', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E3A8A)), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusAtual,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
                      items: _isSomenteLeitura 
                        ? [DropdownMenuItem(value: _statusAtual, child: Text(_statusAtual, style: const TextStyle(fontWeight: FontWeight.bold)))]
                        : _statusOptions.map((String s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: _isSomenteLeitura ? null : (val) => setState(() => _statusAtual = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFF8FAFC),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resumo Financeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)), child: Text(_nivelCliente, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total em Peças:', style: TextStyle(fontSize: 16)), Text('R\$ ${totalPecas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Mão de Obra:', style: TextStyle(fontSize: 16)), Text('R\$ ${totalServicosBruto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16))]),
                
                if (_percentualDesconto > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Desconto Fidelidade (${(_percentualDesconto * 100).toInt()}%):', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)), Text('- R\$ ${valorDesconto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold))]),
                ],

                const Divider(thickness: 2, height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL GERAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('R\$ ${totalGeral.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        if (!_isSomenteLeitura) ...[
          SizedBox(height: 55, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: _isSalvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save), label: Text(_isSalvando ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), onPressed: _isSalvando ? null : _salvarOS)),
          const SizedBox(height: 12),
        ],
        SizedBox(height: 55, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.gavel), label: const Text('LER TERMO JURÍDICO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), onPressed: _gerarTermoAceite)),
        const SizedBox(height: 12),
        SizedBox(height: 55, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A), side: const BorderSide(color: Color(0xFF1E3A8A), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.print), label: const Text('IMPRIMIR DOCUMENTO COMPLETO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), onPressed: _imprimirOSCompleta)),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: Text('Gerenciar $codigoDaOS', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isDesktop ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: leftColumn), const SizedBox(width: 24), Expanded(flex: 4, child: rightColumn)]) : Column(children: [rightColumn, const SizedBox(height: 24), leftColumn]),
      ),
    );
  }
}
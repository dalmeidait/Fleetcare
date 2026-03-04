import 'package:flutter/material.dart';

class CadastroOsScreen extends StatelessWidget {
  const CadastroOsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Obsoleta'),
        backgroundColor: Colors.grey,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Esta tela foi substituída!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Por favor, use as novas telas: "Recepção (Abrir OS)" e "Centro de Comando (Gerenciar OS)".\n\nAtualize os botões do seu menu para apontarem para o AbrirOSScreen.',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            )
          ],
        ),
      ),
    );
  }
}
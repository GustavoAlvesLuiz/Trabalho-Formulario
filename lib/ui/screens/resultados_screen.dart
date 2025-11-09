import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot?>? _dataFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a busca pelos dados assim que a tela é criada
    _dataFuture = _fetchData();
  }

  // Função que busca os dados no Firestore
  Future<DocumentSnapshot?> _fetchData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('usuarios').doc(user.uid).get();
    }
    return null;
  }

  // Função para fazer Logout
  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      // Volta para a tela de login e remove todas as outras da pilha
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // 1. Enquanto está carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Se deu erro
          if (snapshot.hasError) {
            return const Center(
                child: Text('Erro ao carregar os dados. Tente novamente.'));
          }

          // 3. Se não encontrou dados
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          // 4. Se deu tudo certo e os dados chegaram!
          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text('Documento vazio.'));
          }

          final dadosPessoais =
              data['dados_pessoais'] as Map<String, dynamic>? ?? {};
          final quizHabitos =
              data['quiz_habitos'] as Map<String, dynamic>? ?? {};

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Dados Pessoais'),
                  _buildResultCard(dadosPessoais),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Respostas do Quiz'),
                  _buildResultCard(quizHabitos),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget helper para o título da seção
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget helper para mostrar os dados em um "card"
  Widget _buildResultCard(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhum dado preenchido para esta seção.'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: data.entries.map((entry) {
            // Transforma os dados em 'Chave: Valor'
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text('${entry.value ?? 'N/A'}'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
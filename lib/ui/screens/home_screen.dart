import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DadosPessoaisScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _senhaCtrl = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Color get _hint => Colors.grey.shade600;
  BorderRadius get _radius => BorderRadius.circular(12);
  InputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = _emailCtrl.text.trim();
        final senha = _senhaCtrl.text.trim();

        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: senha,
        );

        final user = userCredential.user;
        if (user == null) return;

        // --- LÓGICA DE DIRECIONAMENTO ---
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        String telaDestino = '/'; // Rota padrão

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final dadosPessoais = data['dados_pessoais'] as Map<String, dynamic>? ?? {};
          final tipoUsuario = dadosPessoais['tipo_usuario'];

          // 1. É Professor?
          if (tipoUsuario == 'Professor') {
            telaDestino = '/lista_usuarios';
          } 
          // 2. É Aluno?
          else {
            final quizHabitos = data['quiz_habitos'] as Map<String, dynamic>? ?? {};
            final bool quizConcluido = quizHabitos['quiz_concluido'] == true;

            if (quizConcluido) {
              // Já respondeu? Vai para os resultados.
              telaDestino = '/results';
            } else {
              // Não respondeu? Vai para o formulário.
              // (Mandamos para DadosPessoais pois é a primeira etapa)
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DadosPessoaisScreen()),
                );
              }
              return; // Já navegamos, encerra a função aqui.
            }
          }
        } else {
          // Documento não existe? (Ex: usuário do Auth antigo)
          // Manda para o formulário de dados pessoais.
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DadosPessoaisScreen()),
            );
          }
          return; // Já navegamos.
        }

        // Navega para a tela destino decidida
        if (mounted) {
          Navigator.pushNamed(context, telaDestino);
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Ocorreu um erro.';
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          message = 'Email ou senha incorretos.';
        } else if (e.code == 'invalid-email') {
          message = 'Email inválido.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Colors.black87;
    final Color textSecondary = Colors.grey.shade600;
    final Color cardBg = Colors.grey.shade200;
    final Color dividerColor = Colors.grey.shade500;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        title: const Text(
          'Formulário sobre seu hábitos de estudos',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dividerColor),
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bem-vindo(a)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Este app coleta hábitos de estudo e faz um quiz rápido. Leva menos de 3 minutos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: _hint),
                      border: _inputBorder,
                      enabledBorder: _inputBorder,
                      focusedBorder: _inputBorder.copyWith(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1.6),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      hintStyle: TextStyle(color: _hint),
                      border: _inputBorder,
                      enabledBorder: _inputBorder,
                      focusedBorder: _inputBorder.copyWith(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1.6),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Próximo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registro');
                    },
                    child: const Text(
                      'Não tem conta? Registrar-se',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Seus dados são usados somente para fins educacionais.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Feito pelos alunos Athos Telini e Gustavo Alves\nIFSULDEMINAS - Campus Machado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
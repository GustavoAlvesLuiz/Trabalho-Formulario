import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO
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
  final _firestore = FirebaseFirestore.instance; // NOVO

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

  // FUNÇÃO LOGIN MODIFICADA
  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = _emailCtrl.text.trim();
        final senha = _senhaCtrl.text.trim();

        // 1. Fazer o login
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: senha,
        );

        final user = userCredential.user;
        if (user == null) return;

        // 2. Buscar os dados do usuário no Firestore
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();

        String telaDestino = '/';
        bool quizConcluido = false;

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          // Verifica se o quiz_habitos existe e se quiz_concluido é true
          if (data.containsKey('quiz_habitos') &&
              data['quiz_habitos']['quiz_concluido'] == true) {
            quizConcluido = true;
          }
        }

        // 3. Decidir para onde navegar
        if (quizConcluido) {
          // Se já respondeu o quiz, vai para os resultados
          telaDestino = '/results';
        } else {
          // Se é novo ou não terminou, vai para os dados pessoais
          telaDestino = '/form';
          // (Nota: seu app navega de DadosPessoais -> FormScreen,
          //  mas sua rota '/form' vai direto pro quiz.
          //  Vamos simplificar e navegar para a DadosPessoaisScreen direto)
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DadosPessoaisScreen()),
            );
          }
          return; // Retorna aqui pois já navegamos
        }

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

  // FUNÇÃO REGISTRAR MODIFICADA (para ir para a tela certa)
  void _registrar() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = _emailCtrl.text.trim();
        final senha = _senhaCtrl.text.trim();

        if (senha.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A senha deve ter no mínimo 6 caracteres.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );

        // Após registrar, sempre vai para a tela de Dados Pessoais
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DadosPessoaisScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Ocorreu um erro no registro.';
        if (e.code == 'weak-password') {
          message = 'A senha é muito fraca.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Este email já está em uso.';
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

  //
  // O RESTANTE DO CÓDIGO (O MÉTODO 'build')
  // CONTINUA EXATAMENTE O MESMO DE ANTES
  //
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
                    onPressed: _registrar,
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
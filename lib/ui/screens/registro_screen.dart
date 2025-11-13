import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DadosPessoaisScreen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _senhaCtrl = TextEditingController();
  String? _tipoUsuario;

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
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final email = _emailCtrl.text.trim();
      final senha = _senhaCtrl.text.trim();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Usuário não foi criado.');
      }

      await _firestore.collection('usuarios').doc(user.uid).set({
        'dados_pessoais': {
          'nome': _nomeCtrl.text.trim(),
          'email': email,
          'tipo_usuario': _tipoUsuario,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
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
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro inesperado: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preencha seus dados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CAMPO NOME ---
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nome Completo',
                        hintStyle: TextStyle(color: _hint),
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 1.6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // --- CAMPO EMAIL ---
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
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // --- CAMPO SENHA ---
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Senha (mínimo 6 caracteres)',
                        hintStyle: TextStyle(color: _hint),
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 1.6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (v.length < 6) {
                          return 'A senha deve ter no mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- CAMPO TIPO DE USUÁRIO ---
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Tipo de Usuário',
                        hintStyle: TextStyle(color: _hint),
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 1.6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _tipoUsuario,
                      items: const [
                        DropdownMenuItem(value: 'Aluno', child: Text('Aluno')),
                        DropdownMenuItem(
                            value: 'Professor', child: Text('Professor')),
                      ],
                      onChanged: (v) => setState(() => _tipoUsuario = v),
                      validator: (v) =>
                          v == null ? 'Selecione um tipo' : null,
                    ),
                    const SizedBox(height: 28),

                    // --- BOTÃO CADASTRAR ---
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _cadastrar,
                        child: const Text(
                          'Cadastrar e Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
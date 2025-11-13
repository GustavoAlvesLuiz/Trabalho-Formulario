import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final String userId;

  const EditarUsuarioScreen({super.key, required this.userId});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeCtrl = TextEditingController();
  String? _tipoUsuario;
  String _email = '';

  final _firestore = FirebaseFirestore.instance;
  late Future<DocumentSnapshot> _loadUserFuture;

  Color get _hint => Colors.grey.shade600;
  BorderRadius get _radius => BorderRadius.circular(12);
  InputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      );

  @override
  void initState() {
    super.initState();
    _loadUserFuture =
        _firestore.collection('usuarios').doc(widget.userId).get();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await _firestore.collection('usuarios').doc(widget.userId).set({
        'dados_pessoais': {
          'nome': _nomeCtrl.text.trim(),
          'tipo_usuario': _tipoUsuario,
          'email': _email,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuário'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Erro ao carregar dados do usuário.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final dadosPessoais =
              data['dados_pessoais'] as Map<String, dynamic>? ?? {};

          if (_nomeCtrl.text.isEmpty) {
            _nomeCtrl.text = dadosPessoais['nome'] ?? '';
          }
          if (_tipoUsuario == null) {
            _tipoUsuario = dadosPessoais['tipo_usuario'];
          }
          _email = dadosPessoais['email'] ?? 'N/A';


          return Center(
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
                      Text('Email: $_email', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          hintStyle: TextStyle(color: _hint),
                          border: _inputBorder,
                          enabledBorder: _inputBorder,
                          focusedBorder: _inputBorder.copyWith(
                            borderSide: const BorderSide(
                                color: Colors.blue, width: 1.6),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de Usuário',
                          hintStyle: TextStyle(color: _hint),
                          border: _inputBorder,
                          enabledBorder: _inputBorder,
                          focusedBorder: _inputBorder.copyWith(
                            borderSide: const BorderSide(
                                color: Colors.blue, width: 1.6),
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

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _salvar,
                          child: const Text(
                            'Salvar Alterações',
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
          );
        },
      ),
    );
  }
}
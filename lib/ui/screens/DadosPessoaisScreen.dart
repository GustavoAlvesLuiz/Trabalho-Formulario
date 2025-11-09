import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_screen.dart';

class DadosPessoaisScreen extends StatefulWidget {
  const DadosPessoaisScreen({super.key});

  @override
  State<DadosPessoaisScreen> createState() => _DadosPessoaisScreenState();
}

class _DadosPessoaisScreenState extends State<DadosPessoaisScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _idadeCtrl = TextEditingController();
  final TextEditingController _telefoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _outroGeneroCtrl = TextEditingController();
  String? _genero;
  String? _escolaridade;

  // NOVAS LINHAS
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Color get _cardBg => Colors.grey.shade100;
  Color get _hint => Colors.grey.shade600;
  BorderRadius get _radius => BorderRadius.circular(14);
  InputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _cardBg, borderRadius: _radius),
      child: child,
    );
  }

  // FUNÇÃO MODIFICADA
  void _proximo() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Pegar o usuário logado
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não autenticado.')));
          Navigator.of(context).pop();
        }
        return;
      }

      final uid = user.uid; // ID único do usuário

      // Criar um mapa com os dados
      final dadosPessoais = {
        'nome': _nomeCtrl.text.trim(),
        'idade': _idadeCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'genero': _genero,
        'genero_outro': _genero == 'Outros' ? _outroGeneroCtrl.text.trim() : null,
        'escolaridade': _escolaridade,
      };

      try {
        // Salvar no Firestore
        await _firestore.collection('usuarios').doc(uid).set(
          {'dados_pessoais': dadosPessoais},
          SetOptions(merge: true), // 'merge' evita sobrescrever outros dados
        );

        // Navegar para o próximo formulário
        if (mounted) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FormScreen()));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar dados: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Colors.grey.shade500;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title:
            const Text('Formulario', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dividerColor),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nome completo',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nomeCtrl,
                          decoration: InputDecoration(
                            hintText: 'Digite seu nome',
                            hintStyle: TextStyle(color: _hint),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _inputBorder.copyWith(
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1.6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Idade',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idadeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: 'Digite sua idade',
                            hintStyle: TextStyle(color: _hint),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _inputBorder.copyWith(
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1.6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo obrigatório';
                            final ok = RegExp(r'^\d+$').hasMatch(v);
                            if (!ok) return 'Informe apenas números inteiros';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Telefone',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telefoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '(00) 00000-0000',
                            hintStyle: TextStyle(color: _hint),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _inputBorder.copyWith(
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1.6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'exemplo@email.com',
                            hintStyle: TextStyle(color: _hint),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _inputBorder.copyWith(
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1.6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gênero',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        RadioListTile<String>(
                          title: const Text('Homem'),
                          value: 'Homem',
                          groupValue: _genero,
                          onChanged: (v) => setState(() => _genero = v),
                        ),
                        RadioListTile<String>(
                          title: const Text('Mulher'),
                          value: 'Mulher',
                          groupValue: _genero,
                          onChanged: (v) => setState(() => _genero = v),
                        ),
                        RadioListTile<String>(
                          title: const Text('Outros'),
                          value: 'Outros',
                          groupValue: _genero,
                          onChanged: (v) => setState(() => _genero = v),
                        ),
                        if (_genero == 'Outros')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextFormField(
                              controller: _outroGeneroCtrl,
                              decoration: InputDecoration(
                                hintText: 'Especifique',
                                hintStyle: TextStyle(color: _hint),
                                border: _inputBorder,
                                enabledBorder: _inputBorder,
                                focusedBorder: _inputBorder.copyWith(
                                  borderSide: const BorderSide(
                                      color: Colors.blue, width: 1.6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                              validator: (v) {
                                if (_genero == 'Outros' &&
                                    (v == null || v.isEmpty)) {
                                  return 'Campo obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grau de escolaridade',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _inputBorder.copyWith(
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1.6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          hint: Text('Selecione', style: TextStyle(color: _hint)),
                          value: _escolaridade,
                          items: const [
                            DropdownMenuItem(
                              value: 'Fundamental - Incompleto',
                              child: Text('Fundamental - Incompleto',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Fundamental - Completo',
                              child: Text('Fundamental - Completo',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Médio - Incompleto',
                              child: Text('Médio - Incompleto',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Médio - Completo',
                              child: Text('Médio - Completo',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Superior - Incompleto',
                              child: Text('Superior - Incompleto',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Superior - Completo',
                              child: Text('Superior - Completo',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value:
                                  'Pós-graduação (especialização, mestrado, doutorado) - Completo/Incompleto',
                              child: Text(
                                'Pós-graduação (especialização, mestrado, doutorado) - Completo/Incompleto',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _escolaridade = v),
                          validator: (v) => v == null ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _proximo,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Próximo',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
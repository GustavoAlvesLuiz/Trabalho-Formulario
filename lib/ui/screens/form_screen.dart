import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cursoCtrl = TextEditingController();
  final TextEditingController _fatorCtrl = TextEditingController();
  final TextEditingController _outroGeneroCtrl = TextEditingController();
  final TextEditingController _preferenciaOutroCtrl = TextEditingController();
  final TextEditingController _dificuldadeOutroCtrl = TextEditingController();
  final TextEditingController _ferramentasOutroCtrl = TextEditingController();

  String? _horasDia;
  String? _revisa;
  String? _pratica;
  String? _onde;
  bool _usaOrganizacao = false;

  String? _preferenciaDuvida;
  final Set<String> _dificuldades = {};
  final Set<String> _ferramentas = {};

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

  Widget _radioTile<T>({
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    final selected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey.shade300,
          width: selected ? 1.6 : 1.2,
        ),
      ),
      child: RadioListTile<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        dense: true,
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(label),
        shape: RoundedRectangleBorder(borderRadius: _radius),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }

  Widget _checkTile({
    required String value,
    required Set<String> group,
    required void Function(bool) onChanged,
    required String label,
  }) {
    final selected = group.contains(value);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey.shade300,
          width: selected ? 1.6 : 1.2,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        dense: true,
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(label),
        shape: RoundedRectangleBorder(borderRadius: _radius),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }

  void _enviar() async {
    final textOk = _formKey.currentState?.validate() ?? false;
    final radiosOk = _horasDia != null &&
        _revisa != null &&
        _pratica != null &&
        _onde != null &&
        _preferenciaDuvida != null;

    if (textOk && radiosOk) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não autenticado.')));
          Navigator.of(context).pop();
        }
        return;
      }

      final uid = user.uid;

      final dadosQuiz = {
        'curso': _cursoCtrl.text.trim(),
        'horas_dia': _horasDia,
        'revisa': _revisa,
        'onde_estuda': _onde,
        'onde_estuda_outro':
            _onde == 'Outro' ? _outroGeneroCtrl.text.trim() : null,
        'usa_organizacao': _usaOrganizacao,
        'fator_distracao': _fatorCtrl.text.trim(),
        'pratica_eficaz': _pratica,
        'preferencia_duvida': _preferenciaDuvida,
        'preferencia_duvida_outro': _preferenciaDuvida == 'Outro'
            ? _preferenciaOutroCtrl.text.trim()
            : null,
        'dificuldades': _dificuldades.toList(),
        'dificuldades_outro': _dificuldades.contains('Outro')
            ? _dificuldadeOutroCtrl.text.trim()
            : null,
        'ferramentas': _ferramentas.toList(),
        'ferramentas_outro': _ferramentas.contains('Outro')
            ? _ferramentasOutroCtrl.text.trim()
            : null,
        'quiz_concluido': true,
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        await _firestore.collection('usuarios').doc(uid).set(
          {'quiz_habitos': dadosQuiz},
          SetOptions(merge: true),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Respostas enviadas com sucesso!')));
          
          Navigator.pushNamedAndRemoveUntil(
              context, '/parceiro', (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar respostas: $e')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos obrigatórios.')));
    }
  }

  @override
  void dispose() {
    _cursoCtrl.dispose();
    _fatorCtrl.dispose();
    _outroGeneroCtrl.dispose();
    _preferenciaOutroCtrl.dispose();
    _dificuldadeOutroCtrl.dispose();
    _ferramentasOutroCtrl.dispose();
    super.dispose();
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
            const Text('Quiz', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        const Text(
                          'Qual é o seu curso ou área de estudo atual?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cursoCtrl,
                          decoration: InputDecoration(
                            hintText: 'Digite aqui',
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Em média, quantas horas por dia você estuda fora da sala de aula?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _radioTile<String>(
                          value: '0h',
                          groupValue: _horasDia,
                          onChanged: (v) => setState(() => _horasDia = v),
                          label: '0h',
                        ),
                        _radioTile<String>(
                          value: '1h',
                          groupValue: _horasDia,
                          onChanged: (v) => setState(() => _horasDia = v),
                          label: '1h',
                        ),
                        _radioTile<String>(
                          value: '2h',
                          groupValue: _horasDia,
                          onChanged: (v) => setState(() => _horasDia = v),
                          label: '2h',
                        ),
                        _radioTile<String>(
                          value: '3h+',
                          groupValue: _horasDia,
                          onChanged: (v) => setState(() => _horasDia = v),
                          label: '3h+',
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você costuma revisar o conteúdo após as aulas?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _radioTile<String>(
                          value: 'Sempre',
                          groupValue: _revisa,
                          onChanged: (v) => setState(() => _revisa = v),
                          label: 'Sempre',
                        ),
                        _radioTile<String>(
                          value: 'Às vezes',
                          groupValue: _revisa,
                          onChanged: (v) => setState(() => _revisa = v),
                          label: 'Às vezes',
                        ),
                        _radioTile<String>(
                          value: 'Raramente',
                          groupValue: _revisa,
                          onChanged: (v) => setState(() => _revisa = v),
                          label: 'Raramente',
                        ),
                        _radioTile<String>(
                          value: 'Nunca',
                          groupValue: _revisa,
                          onChanged: (v) => setState(() => _revisa = v),
                          label: 'Nunca',
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Onde você estuda com mais frequência?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
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
                          value: _onde,
                          items: const [
                            DropdownMenuItem(
                                value: 'Em casa', child: Text('Em casa')),
                            DropdownMenuItem(
                                value: 'Biblioteca',
                                child: Text('Biblioteca')),
                            DropdownMenuItem(
                                value: 'Outro local',
                                child: Text('Outro local')),
                            DropdownMenuItem(
                                value: 'Outro', child: Text('Outro')),
                          ],
                          onChanged: (v) => setState(() => _onde = v),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                        ),
                        if (_onde == 'Outro')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: _outroGeneroCtrl,
                              decoration: InputDecoration(
                                hintText: 'Descreva o local',
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
                            ),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você usa algum método de organização para planejar seus estudos?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _usaOrganizacao,
                          onChanged: (v) => setState(() => _usaOrganizacao = v),
                          title: const Text('Sim/Não'),
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(borderRadius: _radius),
                          tileColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'O que mais atrapalha sua concentração ao estudar?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fatorCtrl,
                          decoration: InputDecoration(
                            hintText: 'Digite aqui',
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qual prática é mais eficaz para você aprender e reter o conteúdo?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _radioTile<String>(
                          value: 'Ler várias vezes',
                          groupValue: _pratica,
                          onChanged: (v) => setState(() => _pratica = v),
                          label: 'a) Ler várias vezes',
                        ),
                        _radioTile<String>(
                          value: 'Fazer resumos e exercícios',
                          groupValue: _pratica,
                          onChanged: (v) => setState(() => _pratica = v),
                          label: 'b) Fazer resumos e exercícios',
                        ),
                        _radioTile<String>(
                          value: 'Assistir vídeos e anotar',
                          groupValue: _pratica,
                          onChanged: (v) => setState(() => _pratica = v),
                          label: 'c) Assistir vídeos e anotar',
                        ),
                        _radioTile<String>(
                          value: 'Estudar na véspera',
                          groupValue: _pratica,
                          onChanged: (v) => setState(() => _pratica = v),
                          label: 'd) Estudar na véspera',
                        ),
                        _radioTile<String>(
                          value: 'Outro',
                          groupValue: _pratica,
                          onChanged: (v) => setState(() => _pratica = v),
                          label: 'Outro',
                        ),
                        if (_pratica == 'Outro')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Descreva sua prática',
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
                            ),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quando tem dúvida, qual é sua forma preferida de buscar a resposta?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
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
                          value: _preferenciaDuvida,
                          items: const [
                            DropdownMenuItem(
                                value: 'Perguntar ao professor',
                                child: Text('Perguntar ao professor')),
                            DropdownMenuItem(
                                value: 'Pesquisar na internet',
                                child: Text('Pesquisar na internet')),
                            DropdownMenuItem(
                                value: 'Usar respostas rápidas de IA generativa',
                                child: Text(
                                    'Usar respostas rápidas de IA generativa')),
                            DropdownMenuItem(
                                value: 'Consultar livros ou apostilas',
                                child: Text('Consultar livros ou apostilas')),
                            DropdownMenuItem(
                                value: 'Outro', child: Text('Outro')),
                          ],
                          onChanged: (v) =>
                              setState(() => _preferenciaDuvida = v),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                        ),
                        if (_preferenciaDuvida == 'Outro')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: _preferenciaOutroCtrl,
                              decoration: InputDecoration(
                                hintText: 'Descreva sua preferência',
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
                                if (_preferenciaDuvida == 'Outro' &&
                                    (v == null || v.isEmpty))
                                  return 'Obrigatório';
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
                        const Text(
                          'Quais dificuldades mais atrapalham seus estudos?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _checkTile(
                          value: 'Falta de motivação',
                          group: _dificuldades,
                          onChanged: (v) => setState(() => v
                              ? _dificuldades.add('Falta de motivação')
                              : _dificuldades.remove('Falta de motivação')),
                          label: 'Falta de motivação',
                        ),
                        _checkTile(
                          value: 'Falta de tempo',
                          group: _dificuldades,
                          onChanged: (v) => setState(() => v
                              ? _dificuldades.add('Falta de tempo')
                              : _dificuldades.remove('Falta de tempo')),
                          label: 'Falta de tempo',
                        ),
                        _checkTile(
                          value: 'Procrastinação',
                          group: _dificuldades,
                          onChanged: (v) => setState(() => v
                              ? _dificuldades.add('Procrastinação')
                              : _dificuldades.remove('Procrastinação')),
                          label: 'Procrastinação',
                        ),
                        _checkTile(
                          value: 'Outro',
                          group: _dificuldades,
                          onChanged: (v) => setState(() {
                            if (v) {
                              _dificuldades.add('Outro');
                            } else {
                              _dificuldades.remove('Outro');
                              _dificuldadeOutroCtrl.clear();
                            }
                          }),
                          label: 'Outro',
                        ),
                        if (_dificuldades.contains('Outro'))
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: _dificuldadeOutroCtrl,
                              decoration: InputDecoration(
                                hintText: 'Descreva sua dificuldade',
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
                            ),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quais recursos você usa para estudar?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _checkTile(
                          value: 'Caderno',
                          group: _ferramentas,
                          onChanged: (v) => setState(() => v
                              ? _ferramentas.add('Caderno')
                              : _ferramentas.remove('Caderno')),
                          label: 'Caderno',
                        ),
                        _checkTile(
                          value: 'Computador',
                          group: _ferramentas,
                          onChanged: (v) => setState(() => v
                              ? _ferramentas.add('Computador')
                              : _ferramentas.remove('Computador')),
                          label: 'Computador',
                        ),
                        _checkTile(
                          value: 'Notebook',
                          group: _ferramentas,
                          onChanged: (v) => setState(() => v
                              ? _ferramentas.add('Notebook')
                              : _ferramentas.remove('Notebook')),
                          label: 'Notebook',
                        ),
                        _checkTile(
                          value: 'Tablet',
                          group: _ferramentas,
                          onChanged: (v) => setState(() => v
                              ? _ferramentas.add('Tablet')
                              : _ferramentas.remove('Tablet')),
                          label: 'Tablet',
                        ),
                        _checkTile(
                          value: 'Celular',
                          group: _ferramentas,
                          onChanged: (v) => setState(() => v
                              ? _ferramentas.add('Celular')
                              : _ferramentas.remove('Celular')),
                          label: 'Celular',
                        ),
                        _checkTile(
                          value: 'Outro',
                          group: _ferramentas,
                          onChanged: (v) => setState(() {
                            if (v) {
                              _ferramentas.add('Outro');
                            } else {
                              _ferramentas.remove('Outro');
                              _ferramentasOutroCtrl.clear();
                            }
                          }),
                          label: 'Outro',
                        ),
                        if (_ferramentas.contains('Outro'))
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: _ferramentasOutroCtrl,
                              decoration: InputDecoration(
                                hintText: 'Descreva o recurso',
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
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _enviar,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enviar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
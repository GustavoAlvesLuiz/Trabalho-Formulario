import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonParceiroScreen extends StatefulWidget {
  const PokemonParceiroScreen({super.key});

  @override
  State<PokemonParceiroScreen> createState() => _PokemonParceiroScreenState();
}

class _PokemonParceiroScreenState extends State<PokemonParceiroScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>?>? _pokemonFuture;

  @override
  void initState() {
    super.initState();
    _pokemonFuture = _getPokemonParceiro();
  }

  Future<Map<String, dynamic>?> _getPokemonParceiro() async {
    try {
      // 1. Pegar o nome do usuário no Firestore
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      final data = doc.data();
      final nome = data?['dados_pessoais']?['nome'] as String?;

      if (nome == null || nome.isEmpty) return null;

      final primeiraLetra = nome[0].toUpperCase();

      // 2. Chamar a API de Pokémons
      final response = await http
          .get(Uri.parse('https://www.canalti.com.br/api/pokemons.json'));

      if (response.statusCode == 200) {
        // 3. Decodificar a resposta
        final decodedJson = jsonDecode(response.body);
        final List<dynamic> pokemons = decodedJson['pokemon'];

        // 4. Encontrar um Pokémon com a mesma letra
        final pokemonEncontrado = pokemons.firstWhere(
          (p) => p['name'] != null && p['name'][0].toUpperCase() == primeiraLetra,
          orElse: () => pokemons[0], // Se não achar, pega o primeiro
        );

        return pokemonEncontrado as Map<String, dynamic>;
      } else {
        return null; // Falha ao chamar API
      }
    } catch (e) {
      return null; // Erro geral
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu Parceiro de Estudos!'),
        automaticallyImplyLeading: false, // Remove a seta de "voltar"
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _pokemonFuture,
          builder: (context, snapshot) {
            // 1. Enquanto está carregando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Analisando seu perfil e buscando\nseu parceiro Pokémon...'),
                ],
              );
            }

            // 2. Se deu erro ou não achou
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    const Text(
                      'Não foi possível encontrar um parceiro Pokémon.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/results');
                      },
                      child: const Text('Ver Meus Resultados Mesmo Assim'),
                    )
                  ],
                ),
              );
            }

            // 3. Se deu tudo certo!
            final pokemon = snapshot.data!;
            final nomePokemon = pokemon['name'] ?? 'Desconhecido';
            final imgUrl = pokemon['img'] ?? ''; // A API usa 'img'

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Parabéns!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Seu novo parceiro de estudos é o:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  if (imgUrl.isNotEmpty)
                    Image.network(
                      imgUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.contain,
                      // Widget de loading para a imagem
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 150,
                          width: 150,
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      },
                      // Widget de erro para a imagem
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.help_outline, size: 150);
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    nomePokemon,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navega para a tela de resultados
                        Navigator.pushNamed(context, '/results');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ver Meus Resultados',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
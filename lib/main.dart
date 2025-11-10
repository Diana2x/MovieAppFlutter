import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const PokeApp());

class PokeApp extends StatelessWidget {
  const PokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const PokemonSearchScreen(),
    );
  }
}

class PokemonSearchScreen extends StatefulWidget {
  const PokemonSearchScreen({super.key});

  @override
  State<PokemonSearchScreen> createState() => _PokemonSearchScreenState();
}

class _PokemonSearchScreenState extends State<PokemonSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _pokemonData;
  bool _loading = false;
  String? _error;

  Future<void> _fetchPokemon(String name) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _pokemonData = json.decode(response.body);
        });
      } else {
        setState(() => _error = 'Pokémon not found');
      }
    } catch (e) {
      setState(() => _error = 'Error loading Pokémon');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search Pokémon (e.g. ditto)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      _fetchPokemon(_controller.text.toLowerCase()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_pokemonData != null) Expanded(child: _buildPokemonDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonDetails() {
    final data = _pokemonData!;
    final image = data['sprites']['other']['official-artwork']['front_default'];
    final name = data['name'];
    final id = data['id'];
    final types = (data['types'] as List)
        .map((t) => t['type']['name'])
        .toList();
    final abilities = (data['abilities'] as List)
        .map((a) => a['ability']['name'])
        .toList();
    final stats = (data['stats'] as List)
        .map((s) => {'name': s['stat']['name'], 'value': s['base_stat']})
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            '$name (#$id)',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Image.network(image, height: 200),
          Wrap(
            spacing: 8,
            children: types
                .map((t) => Chip(label: Text(t.toUpperCase())))
                .toList(),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: stats
                  .map(
                    (s) => ListTile(
                      title: Text(s['name']),
                      trailing: Text(s['value'].toString()),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text('Abilities: ${abilities.join(', ')}'),
          const SizedBox(height: 10),
          Text('Height: ${data['height']} | Weight: ${data['weight']}'),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

const String tmdbApiKey = '21e304b1f49db179679318688c589a15';
const String tmdbBase = 'https://api.themoviedb.org/3';
const String tmdbImageBase = 'https://image.tmdb.org/t/p/w500';

// Almacenamiento temporal de películas añadidas desde la pantalla Admin o Firestore
final List<LocalMovie> localAddedMovies = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF); // pastel purple
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: ThemeData.dark().copyWith(
        primaryColor: accent,
        colorScheme: ThemeData.dark().colorScheme.copyWith(secondary: accent),
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1724),
          elevation: 2,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            elevation: 6,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// -------------------- MODELOS --------------------
class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;
  final String overview;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.overview,
  });

  String get posterUrl =>
      posterPath.isNotEmpty ? '$tmdbImageBase$posterPath' : '';

  String get year {
    if (releaseDate.isEmpty) return '—';
    return releaseDate.split('-').first;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      posterPath: json['poster_path'] as String? ?? '',
      releaseDate: json['release_date'] as String? ?? '',
      voteAverage: (json['vote_average'] is num)
          ? (json['vote_average'] as num).toDouble()
          : 0.0,
      overview: json['overview'] as String? ?? '',
    );
  }
}

class MovieDetail {
  final String title;
  final String releaseDate;
  final String overview;
  final List<String> genres;
  final String director;
  final String posterPath;

  MovieDetail({
    required this.title,
    required this.releaseDate,
    required this.overview,
    required this.genres,
    required this.director,
    required this.posterPath,
  });

  String get year => releaseDate.isEmpty ? '—' : releaseDate.split('-').first;
  String get posterUrl =>
      posterPath.isNotEmpty ? '$tmdbImageBase$posterPath' : '';
}

// Representa una película creada localmente desde Admin o Firestore (no TMDB id)
class LocalMovie {
  final int id; // negative id to avoid conflicts
  final String title;
  final String year;
  final String director;
  final String genre;
  final String synopsis;
  final String imageUrl;

  LocalMovie({
    required this.id,
    required this.title,
    required this.year,
    required this.director,
    required this.genre,
    required this.synopsis,
    required this.imageUrl,
  });
}

// -------------------- PANTALLAS --------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071024), Color(0xFF0B0E14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.movie_filter_rounded,
                  size: 86,
                  color: Colors.white70,
                ),
                const SizedBox(height: 18),
                const Text(
                  '¡Bienvenido a MovieZone!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre y administra tus películas favoritas',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Ingresar'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 22,
                    ),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Registrarse'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Login / Register (simulados)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF0F1724),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: _fieldDecoration('Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _fieldDecoration('Contraseña'),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 8),
                  Text('Ingresar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF0F1724),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: _fieldDecoration('Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _fieldDecoration('Contraseña'),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Registrarse'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- CATÁLOGO (usa TMDB) --------------------
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = fetchPopularMovies();
  }

  Future<List<Movie>> fetchPopularMovies() async {
    final uri = Uri.parse(
      '$tmdbBase/movie/popular?api_key=$tmdbApiKey&language=es-ES&page=1',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('Error al cargar películas');
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    final movies = results
        .map((m) => Movie.fromJson(m as Map<String, dynamic>))
        .toList();
    return movies;
  }

  Future<void> _showAddMovieDialog() async {
    final TextEditingController titleC = TextEditingController();
    final TextEditingController yearC = TextEditingController();
    final TextEditingController directorC = TextEditingController();
    final TextEditingController genreC = TextEditingController();
    final TextEditingController synopsisC = TextEditingController();
    final TextEditingController imageC = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1724),
          title: const Text('Agregar película'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: yearC,
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: directorC,
                  decoration: const InputDecoration(
                    labelText: 'Director',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: genreC,
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: synopsisC,
                  decoration: const InputDecoration(
                    labelText: 'Sinopsis',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imageC,
                  decoration: const InputDecoration(
                    labelText: 'URL de Imagen',
                    filled: true,
                    fillColor: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleC.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El título es obligatorio')),
                  );
                  return;
                }
                // Guardar en Firestore
                try {
                  await FirebaseFirestore.instance.collection('movies').add({
                    'title': title,
                    'year': yearC.text.trim(),
                    'director': directorC.text.trim(),
                    'genre': genreC.text.trim(),
                    'synopsis': synopsisC.text.trim(),
                    'imageUrl': imageC.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // Añadir localmente para mostrar inmediatamente
                  final lastId = localAddedMovies.isEmpty
                      ? -1
                      : (localAddedMovies
                                .map((m) => m.id)
                                .reduce((a, b) => a < b ? a : b) -
                            1);
                  setState(() {
                    localAddedMovies.add(
                      LocalMovie(
                        id: lastId,
                        title: title,
                        year: yearC.text.trim(),
                        director: directorC.text.trim(),
                        genre: genreC.text.trim(),
                        synopsis: synopsisC.text.trim(),
                        imageUrl: imageC.text.trim(),
                      ),
                    );
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Película guardada en Firebase'),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          // Reemplazado: ícono de settings abre Pantalla de administración
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            ).then((_) => setState(() {})),
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Administración',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder<List<Movie>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            final tmdbMovies = snapshot.data ?? [];
            // Combina TMDB + localAddedMovies (local al final)
            final combinedCount = tmdbMovies.length + localAddedMovies.length;
            return GridView.builder(
              itemCount: combinedCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (index < tmdbMovies.length) {
                  final movie = tmdbMovies[index];
                  return MovieCard(
                    title: movie.title,
                    imageUrl: movie.posterUrl,
                    subtitle: movie.year,
                    rating: movie.voteAverage,
                    overview: movie.overview,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreenTmdb(id: movie.id),
                      ),
                    ),
                  );
                } else {
                  final local = localAddedMovies[index - tmdbMovies.length];
                  return MovieCard(
                    title: local.title,
                    imageUrl: local.imageUrl,
                    subtitle: local.year,
                    rating: null,
                    overview: local.synopsis,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreenLocal(local: local),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
      // FAB eliminado porque ahora el acceso a Admin está en AppBar (settings)
    );
  }
}

class MovieCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String subtitle;
  final double? rating;
  final String overview;
  final VoidCallback onTap;
  const MovieCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.onTap,
    this.rating,
    this.overview = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1724),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Poster
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Container(color: Colors.grey[800]),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : Container(color: Colors.grey[800]),
              ),
              // Dark gradient for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Rating badge
              if (rating != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD166),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              // Title / subtitle bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 6, color: Colors.black54),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorito (simulado)'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Optional overview preview on long press (small tooltip)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onLongPress: () {
                    if (overview.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF0F1724),
                          title: Text(title),
                          content: Text(
                            overview,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.info_outline, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- DETALLE TMDB --------------------
class MovieDetailScreenTmdb extends StatefulWidget {
  final int id;
  const MovieDetailScreenTmdb({super.key, required this.id});

  @override
  State<MovieDetailScreenTmdb> createState() => _MovieDetailScreenTmdbState();
}

class _MovieDetailScreenTmdbState extends State<MovieDetailScreenTmdb> {
  late Future<MovieDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = fetchMovieDetail(widget.id);
  }

  Future<MovieDetail> fetchMovieDetail(int id) async {
    final detailUri = Uri.parse(
      '$tmdbBase/movie/$id?api_key=$tmdbApiKey&language=es-ES',
    );
    final creditsUri = Uri.parse(
      '$tmdbBase/movie/$id/credits?api_key=$tmdbApiKey&language=es-ES',
    );

    final detailResp = await http.get(detailUri);
    final creditsResp = await http.get(creditsUri);
    if (detailResp.statusCode != 200 || creditsResp.statusCode != 200)
      throw Exception('Error al cargar detalle');

    final d = json.decode(detailResp.body) as Map<String, dynamic>;
    final c = json.decode(creditsResp.body) as Map<String, dynamic>;

    final genres = (d['genres'] as List<dynamic>? ?? [])
        .map((g) => (g['name'] as String))
        .toList();
    String director = '—';
    final crew = c['crew'] as List<dynamic>? ?? [];
    for (final member in crew) {
      if ((member['job'] as String?)?.toLowerCase() == 'director') {
        director = member['name'] as String;
        break;
      }
    }

    return MovieDetail(
      title: d['title'] as String? ?? '',
      releaseDate: d['release_date'] as String? ?? '',
      overview: d['overview'] as String? ?? '',
      genres: genres,
      director: director,
      posterPath: d['poster_path'] as String? ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MovieDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (snapshot.hasError)
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );

        final movie = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(movie.title)),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF0B1220)],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            height: 360,
                            width: double.infinity,
                          )
                        : Container(height: 360, color: Colors.grey[800]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(movie.year),
                            backgroundColor: const Color(0xFF172033),
                          ),
                          const SizedBox(width: 8),
                          ...movie.genres.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(g),
                                backgroundColor: const Color(0xFF172033),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Director: ${movie.director}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sinopsis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.overview,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -------------------- DETALLE LOCAL --------------------
class MovieDetailScreenLocal extends StatelessWidget {
  final LocalMovie local;
  const MovieDetailScreenLocal({super.key, required this.local});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(local.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF0B1220)],
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: local.imageUrl.isNotEmpty
                    ? Image.network(
                        local.imageUrl,
                        fit: BoxFit.cover,
                        height: 360,
                        width: double.infinity,
                      )
                    : Container(height: 360, color: Colors.grey[800]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(local.year),
                        backgroundColor: const Color(0xFF172033),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(local.genre),
                        backgroundColor: const Color(0xFF172033),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Director: ${local.director}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    local.synopsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ADMIN (agrega locales en memoria) --------------------
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _synopsisController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF0F1724),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  void _addLocalMovie() {
    final lastId = localAddedMovies.isEmpty
        ? -1
        : (localAddedMovies.map((m) => m.id).reduce((a, b) => a < b ? a : b) -
              1);
    final movie = LocalMovie(
      id: lastId,
      title: _titleController.text.trim(),
      year: _yearController.text.trim(),
      director: _directorController.text.trim(),
      genre: _genreController.text.trim(),
      synopsis: _synopsisController.text.trim(),
      imageUrl: _imageController.text.trim(),
    );
    setState(() {
      localAddedMovies.add(movie);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Película agregada localmente')),
    );
    _titleController.clear();
    _yearController.clear();
    _directorController.clear();
    _genreController.clear();
    _synopsisController.clear();
    _imageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Películas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: _fieldDecoration('Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearController,
                decoration: _fieldDecoration('Año'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _directorController,
                decoration: _fieldDecoration('Director'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _genreController,
                decoration: _fieldDecoration('Género'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _synopsisController,
                decoration: _fieldDecoration('Sinopsis'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageController,
                decoration: _fieldDecoration('URL de Imagen'),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar Película (local)'),
                onPressed: _addLocalMovie,
              ),
              const SizedBox(height: 18),
              const Text(
                'Películas locales añadidas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final m in localAddedMovies.reversed)
                ListTile(
                  leading: m.imageUrl.isNotEmpty
                      ? Image.network(m.imageUrl, width: 48, fit: BoxFit.cover)
                      : const SizedBox(width: 48),
                  title: Text(m.title),
                  subtitle: Text('${m.year} • ${m.genre}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        localAddedMovies.removeWhere((e) => e.id == m.id);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final api = serviceLocator.apiClient;
    return await api.getAllReviews();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _deleteReview(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: const Text('Da li želite obrisati ovu recenziju?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await serviceLocator.apiClient.deleteReview(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzija obrisana'), backgroundColor: Colors.green),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri brisanju: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije (Admin)'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Greška: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nema recenzija'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = items[index];
              T v<T>(String a, String b) {
                final x = r[a];
                if (x != null) return x as T;
                return r[b] as T;
              }
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: Text('${r['rating'] ?? r['Rating']}', style: const TextStyle(color: Colors.black)),
                  ),
                  title: Text(r['title'] ?? r['Title'] ?? 'Bez naslova'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((r['comment'] ?? r['Comment']) != null) Text(r['comment'] ?? r['Comment']),
                      const SizedBox(height: 4),
                      Text('Korisnik: ${r['userName'] ?? r['UserName'] ?? '-'}'),
                      Text('Veterinar: ${r['veterinarianName'] ?? r['VeterinarianName'] ?? '-'}'),
                      Text('Datum: ${(r['dateCreated'] ?? r['DateCreated'] ?? '').toString()}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReview((r['id'] ?? r['Id']) as int),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



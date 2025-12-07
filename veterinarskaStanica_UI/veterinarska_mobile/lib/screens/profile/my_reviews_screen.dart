import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;
  Set<int> _deletingIds = {}; // Track which reviews are being deleted

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 [MY REVIEWS SCREEN] Loading reviews...');
      final apiClient = serviceLocator.apiClient;
      final reviews = await apiClient.getMyReviews();
      print('✅ [MY REVIEWS SCREEN] Loaded ${reviews.length} reviews');
      print('📋 [MY REVIEWS SCREEN] Reviews data: $reviews');
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ [MY REVIEWS SCREEN] Error loading reviews: $e');
      print('❌ [MY REVIEWS SCREEN] Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReview(int id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: const Text('Da li ste sigurni da želite obrisati ovu recenziju? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Obriši',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Set loading state
    setState(() {
      _deletingIds.add(id);
    });

    try {
      print('🗑️ [MY REVIEWS SCREEN] Deleting review with ID: $id');
      final apiClient = serviceLocator.apiClient;
      await apiClient.deleteMyReview(id);
      print('✅ [MY REVIEWS SCREEN] Review deleted successfully');

      if (mounted) {
        // Immediately remove the review from the list (optimistic update)
        setState(() {
          _deletingIds.remove(id);
          _reviews.removeWhere((review) => (review['id'] as int) == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija je uspešno obrisana'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Optionally reload from server to ensure consistency
        // But the UI is already updated, so this is just a background refresh
        _loadReviews();
      }
    } catch (e) {
      print('❌ [MY REVIEWS SCREEN] Error deleting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri brisanju recenzije: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Remove loading state
      if (mounted) {
        setState(() {
          _deletingIds.remove(id);
        });
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Nepoznato';
    
    DateTime date;
    if (dateValue is String) {
      date = DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      return 'Nepoznato';
    }
    
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje recenzije'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Greška pri učitavanju recenzija',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nemate recenzija',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Kada ostavite recenziju za veterinara,\nona će se pojaviti ovde.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (review['veterinarianName'] != null)
                                        Text(
                                          review['veterinarianName'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      _buildStarRating(review['rating'] ?? 0),
                                    ],
                                  ),
                                  if (review['title'] != null && review['title'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      review['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      review['comment'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  if (review['petName'] != null || review['petSpecies'] != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.pets, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${review['petName'] ?? ''}${review['petName'] != null && review['petSpecies'] != null ? ' - ' : ''}${review['petSpecies'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(review['dateCreated']),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (review['isVerifiedPurchase'] == true) ...[
                                              const SizedBox(width: 16),
                                              const Icon(Icons.verified, size: 14, color: Colors.green),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Verifikovano',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (_deletingIds.contains(review['id'] as int))
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _deleteReview(review['id'] as int),
                                          tooltip: 'Obriši recenziju',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar with glass morphism
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: AppTheme.glassDecoration(borderRadius: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _isSearching = value.isNotEmpty);
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search movies...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildTrendingGrid(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPressStart: (_) => _showPreview(context, index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Movie ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: const Text('Movie Title', style: TextStyle(color: Colors.white)),
          subtitle: const Text('12 Episodes', style: TextStyle(color: Colors.white54)),
          onTap: () {
            // Navigate to movie detail
          },
        );
      },
    );
  }
  
  void _showPreview(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          height: 200,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('5 sec preview', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pop();
    });
  }
}

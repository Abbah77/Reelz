import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/video_player_pool.dart';
import '../data/feed_repository.dart';

// Providers
final currentFeedIndexProvider = StateProvider<int>((ref) => 0);
final feedEpisodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Replace with actual API call
  return FeedRepository.getFeedEpisodes();
});

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  final Map<int, Player> _activePlayers = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (var player in _activePlayers.values) {
      player.dispose();
    }
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _activePlayers.values.forEach((player) => player.pause());
    } else if (state == AppLifecycleState.resumed) {
      final currentIndex = ref.read(currentFeedIndexProvider);
      _activePlayers[currentIndex]?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(feedEpisodesProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: episodesAsync.when(
        data: (episodes) => Stack(
          children: [
            // Video PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: episodes.length,
              onPageChanged: (index) {
                ref.read(currentFeedIndexProvider.notifier).state = index;
                // Pause previous, play current
                _activePlayers.values.forEach((p) => p.pause());
                _activePlayers[index]?.play();
              },
              itemBuilder: (context, index) {
                return _FeedVideoItem(
                  episode: episodes[index],
                  player: _getPlayerForIndex(index, episodes[index]['video_url']),
                  onWatchEpisode: () {
                    // Navigate to player with hero animation
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                            opacity: animation,
                            child: const PlayerScreen(episodeId: '', movieId: ''),
                          );
                        },
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return Hero(
                            tag: 'episode-${episodes[index]['id']}',
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            
            // Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reelz wordmark
                    const Text(
                      'Reelz',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    // Following | For You tabs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: AppTheme.glassDecoration(borderRadius: 20),
                      child: const Row(
                        children: [
                          Text(
                            'Following',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'For You',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    // Search icon
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        // Navigate to explore/search
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Player _getPlayerForIndex(int index, String videoUrl) {
    if (!_activePlayers.containsKey(index)) {
      final player = Player();
      player.open(Media(videoUrl));
      player.play();
      _activePlayers[index] = player;
      
      // Dispose old players (keep only 3)
      if (_activePlayers.length > 3) {
        final keysToRemove = _activePlayers.keys.where((k) => (k - index).abs() > 1).toList();
        for (var key in keysToRemove) {
          _activePlayers[key]?.dispose();
          _activePlayers.remove(key);
        }
      }
    }
    return _activePlayers[index]!;
  }
}

class _FeedVideoItem extends StatelessWidget {
  final Map<String, dynamic> episode;
  final Player player;
  final VoidCallback onWatchEpisode;
  
  const _FeedVideoItem({
    required this.episode,
    required this.player,
    required this.onWatchEpisode,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        Hero(
          tag: 'episode-${episode['id']}',
          child: Video(
            controller: VideoController(player),
            fit: BoxFit.cover,
          ),
        ),
        
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Bottom Left Info
        Positioned(
          bottom: 100,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie Title
              Text(
                episode['movie_title'] ?? 'Movie Title',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 8),
              
              // Hashtags
              Wrap(
                spacing: 8,
                children: (episode['hashtags'] as List? ?? ['#drama', '#romance'])
                    .map((tag) => Text(
                          tag,
                          style: const TextStyle(color: AppTheme.electricBlue, fontSize: 14),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              
              // Watch Episode Button
              Hero(
                tag: 'watch-btn-${episode['id']}',
                child: GestureDetector(
                  onTap: onWatchEpisode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: AppTheme.glowingButtonStyle.shape is RoundedRectangleBorder
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.electricBlue, AppTheme.primaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.electricBlue.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Watch Episode 1',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Right Side Actions
        Positioned(
          right: 8,
          bottom: 120,
          child: Column(
            children: [
              _ActionButton(
                icon: Icons.favorite_border,
                label: 'Like',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  // Share via WhatsApp first
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isActive = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isActive = !_isActive);
        widget.onTap();
      },
      child: Column(
        children: [
          Icon(
            _isActive ? _getFilledIcon() : widget.icon,
            color: _isActive ? AppTheme.electricBlue : Colors.white,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  IconData _getFilledIcon() {
    switch (widget.icon) {
      case Icons.favorite_border:
        return Icons.favorite;
      case Icons.bookmark_border:
        return Icons.bookmark;
      default:
        return widget.icon;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../core/theme/app_theme.dart';
import '../data/player_repository.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String movieId;
  
  const PlayerScreen({
    super.key,
    required this.episodeId,
    required this.movieId,
  });
  
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with TickerProviderStateMixin {
  late Player _player;
  late VideoController _videoController;
  bool _isControlsVisible = true;
  bool _isLocked = false;
  bool _isLandscape = false;
  double _playbackSpeed = 1.0;
  double _brightness = 0.5;
  Timer? _hideControlsTimer;
  
  // Animation controllers
  late AnimationController _drawerAnimationController;
  late AnimationController _controlsAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupAnimations();
    _startHideControlsTimer();
    
    // Listen for orientation changes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  void _initializePlayer() async {
    _player = Player();
    final videoUrl = await PlayerRepository.getEpisodeVideo(widget.episodeId);
    await _player.open(Media(videoUrl));
    
    _videoController = VideoController(_player);
    
    // Listen for position updates
    _player.stream.position.listen((position) {
      if (position != null && _player.state.duration != null) {
        final progress = position.inMilliseconds / _player.state.duration!.inMilliseconds;
        if (progress >= 0.98) {
          _autoPlayNext();
        }
      }
    });
  }
  
  void _setupAnimations() {
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
  }
  
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isLocked) {
        setState(() => _isControlsVisible = false);
        _controlsAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        _isLandscape = orientation == Orientation.landscape;
        return _isLandscape ? _buildLandscapePlayer() : _buildPortraitPlayer();
      },
    );
  }
  
  Widget _buildPortraitPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!_isLocked) {
            setState(() => _isControlsVisible = !_isControlsVisible);
            if (_isControlsVisible) {
              _controlsAnimationController.forward();
              _startHideControlsTimer();
            } else {
              _controlsAnimationController.reverse();
            }
          }
        },
        onLongPress: _showToolsDrawer,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: Video(
                controller: _videoController,
                fit: BoxFit.contain,
              ),
            ),
            
            // Controls overlay
            if (!_isLocked)
              AnimatedBuilder(
                animation: _controlsAnimationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controlsAnimationController.value,
                    child: child,
                  );
                },
                child: _buildPortraitControls(),
              ),
            
            // Lock screen overlay
            if (_isLocked) _buildLockOverlay(),
            
            // Episode grid drawer
            _buildEpisodeDrawer(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLandscapePlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!_isLocked) {
            setState(() => _isControlsVisible = !_isControlsVisible);
            _startHideControlsTimer();
          }
        },
        onLongPress: _showToolsDrawer,
        child: Stack(
          children: [
            // Full screen video
            Center(
              child: Video(
                controller: _videoController,
                fit: BoxFit.contain,
              ),
            ),
            
            // Minimal controls
            if (_isControlsVisible && !_isLocked) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                            ]);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Movie Title',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom progress bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildProgressBar(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPortraitControls() {
    return Stack(
      children: [
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Movie Title',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(),
                
                // Episode info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EP 1/12',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    Text(
                      _formatDuration(_player.state.position ?? Duration.zero),
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Right side actions
        Positioned(
          right: 8,
          bottom: 100,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar() {
    final position = _player.state.position ?? Duration.zero;
    final duration = _player.state.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
    
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final width = box.size.width;
        final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
        final seekPosition = Duration(
          milliseconds: (duration.inMilliseconds * ratio).round(),
        );
        _player.seek(seekPosition);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
            minHeight: 3,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Stack(
          children: [
            // Block all touches
            Container(color: Colors.transparent),
            
            // Unlock button
            Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: _showUnlockDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.glassDecoration(borderRadius: 12),
                  child: const Icon(Icons.lock, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUnlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Unlock Screen', style: TextStyle(color: Colors.white)),
        content: const Text('Swipe to unlock', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isLocked = false);
              Navigator.pop(context);
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEpisodeDrawer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) {
            _showEpisodeGrid();
          }
        },
        child: Container(
          height: 60,
          decoration: AppTheme.glassDecoration(),
          child: const Center(
            child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  void _showEpisodeGrid() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Episode grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final isCurrentEpisode = index == 0;
                  return _EpisodeGridItem(
                    number: index + 1,
                    progress: index == 0 ? 0.5 : (index < 0 ? 1.0 : 0.0),
                    isCurrent: isCurrentEpisode,
                    onTap: () {
                      Navigator.pop(context);
                      // Switch to episode
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showToolsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speed controls
            _buildToolsSection('Playback Speed', [
              _ToolChip('0.5x', () => _setSpeed(0.5)),
              _ToolChip('0.75x', () => _setSpeed(0.75)),
              _ToolChip('1x', () => _setSpeed(1.0)),
              _ToolChip('1.25x', () => _setSpeed(1.25)),
              _ToolChip('1.5x', () => _setSpeed(1.5)),
              _ToolChip('2x', () => _setSpeed(2.0)),
            ]),
            
            const SizedBox(height: 16),
            
            // Brightness slider
            Row(
              children: [
                const Icon(Icons.brightness_6, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    onChanged: (value) async {
                      setState(() => _brightness = value);
                      await ScreenBrightness().setScreenBrightness(value);
                    },
                    activeColor: AppTheme.electricBlue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolAction(Icons.screen_rotation, 'Rotate', () {
                  if (_isLandscape) {
                    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                  } else {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                    ]);
                  }
                }),
                _ToolAction(Icons.lock, 'Lock', () {
                  setState(() => _isLocked = true);
                  Navigator.pop(context);
                }),
                _ToolAction(Icons.skip_next, 'Skip Intro', () {
                  _player.seek(const Duration(seconds: 90));
                  Navigator.pop(context);
                }),
                _ToolAction(Icons.skip_next, 'Next Ep', () {
                  _playNextEpisode();
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToolsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
  
  void _setSpeed(double speed) {
    _playbackSpeed = speed;
    _player.setRate(speed);
    Navigator.pop(context);
  }
  
  void _playNextEpisode() {
    // Play next episode logic
    _player.open(Media('next_episode_url'));
  }
  
  void _autoPlayNext() async {
    final nextEpisodeUrl = await PlayerRepository.getNextEpisodeUrl(widget.episodeId);
    if (nextEpisodeUrl != null) {
      _player.open(Media(nextEpisodeUrl));
    }
  }
  
  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _drawerAnimationController.dispose();
    _controlsAnimationController.dispose();
    _player.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

class _EpisodeGridItem extends StatelessWidget {
  final int number;
  final double progress;
  final bool isCurrent;
  final VoidCallback onTap;
  
  const _EpisodeGridItem({
    required this.number,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? AppTheme.electricBlue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isCurrent ? Border.all(color: AppTheme.electricBlue, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number.toString(),
              style: TextStyle(
                color: isCurrent ? AppTheme.electricBlue : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Progress line
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  
  const _ToolChip(this.label, this.onTap);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.glassDecoration(borderRadius: 8),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _ToolAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _ToolAction(this.icon, this.label, this.onTap);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

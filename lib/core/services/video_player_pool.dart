import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerPool extends StateNotifier<Map<String, Player>> {
  VideoPlayerPool() : super({});
  
  static const int maxControllers = 3;
  
  Player? getController(String episodeId) {
    return state[episodeId];
  }
  
  Future<Player> createOrGetController(String episodeId, String videoUrl) async {
    if (state.containsKey(episodeId)) {
      return state[episodeId]!;
    }
    
    // Dispose old controllers if exceeding limit
    if (state.length >= maxControllers) {
      final oldestKey = state.keys.first;
      final oldestController = state[oldestKey];
      if (oldestController != null && 
          !state.entries.where((e) => e.key != oldestKey).any((e) => e.value == oldestController)) {
        await oldestController.dispose();
        state.remove(oldestKey);
      }
    }
    
    final player = Player();
    await player.open(Media(videoUrl));
    state = {...state, episodeId: player};
    return player;
  }
  
  Future<void> disposeController(String episodeId) async {
    if (state.containsKey(episodeId)) {
      await state[episodeId]?.dispose();
      state = {...state}..remove(episodeId);
      state = Map.from(state); // Trigger state update
    }
  }
  
  @override
  void dispose() {
    for (var controller in state.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

final videoPlayerPoolProvider = StateNotifierProvider<VideoPlayerPool, Map<String, Player>>((ref) {
  return VideoPlayerPool();
});

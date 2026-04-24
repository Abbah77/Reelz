import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

@DataClassName('WatchProgressData')
class WatchProgressTable extends Table {
  TextColumn get episodeId => text()();
  RealColumn get progress => real()();
  IntColumn get lastPositionInSeconds => integer()();
  DateTimeColumn get lastWatched => dateTime()();
  TextColumn get movieId => text()();
  
  @override
  Set<Column> get primaryKey => {episodeId};
}

@DriftDatabase(tables: [WatchProgressTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'reelz.db'));
      return NativeDatabase(file);
    });
  }

  // Watch Progress Methods
  Future<void> saveProgress(WatchProgressData data) async {
    await into(watchProgressTable).insertOnConflictUpdate(data);
  }

  Future<WatchProgressData?> getProgress(String episodeId) {
    return (select(watchProgressTable)
          ..where((tbl) => tbl.episodeId.equals(episodeId)))
        .getSingleOrNull();
  }

  Future<List<WatchProgressData>> getContinueWatching() async {
    return (select(watchProgressTable)
          ..orderBy([(t) => OrderingTerm(expression: t.lastWatched, mode: OrderingMode.desc)])
          ..limit(20))
        .get();
  }

  Stream<List<WatchProgressData>> watchProgress(String movieId) {
    return (select(watchProgressTable)
          ..where((tbl) => tbl.movieId.equals(movieId)))
        .watch();
  }

  Future<void> clearAllProgress() async {
    await delete(watchProgressTable).go();
  }
}

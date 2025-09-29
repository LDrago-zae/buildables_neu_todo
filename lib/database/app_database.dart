import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

@DataClassName('Todo')
class Todos extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text()(); // Changed from ownerId to createdBy
  TextColumn get sharedWith =>
      text().map(const UuidListConverter()).nullable()();
  TextColumn get attachmentUrl => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // NEW: Location fields (all optional)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class UuidListConverter extends TypeConverter<List<String>, String> {
  const UuidListConverter();
  @override
  List<String> fromSql(String fromDb) =>
      fromDb.split(',').where((e) => e.isNotEmpty).toList();
  @override
  String toSql(List<String> value) => value.join(',');
}

@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Increment version for location fields

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        // For simplicity with location fields, drop and recreate tables
        await m.drop(todos);
        await m.createAll();
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;
    return NativeDatabase.createInBackground(file);
  });
}

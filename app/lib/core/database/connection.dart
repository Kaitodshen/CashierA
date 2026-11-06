import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// The on-device SQLite file. Never opened on web (back office only).
QueryExecutor openAppDatabase() => driftDatabase(name: 'cashiera');

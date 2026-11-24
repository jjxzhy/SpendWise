import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';

/// Persistence contract for expense records.
///
/// Decouples UI/state management from the underlying storage engine so the
/// local Hive/IndexedDB implementation can be swapped for a REST API or cloud
/// database without changing providers or screens.
abstract class ExpenseRepository {
  List<Expense> getAll();
  Future<void> save(Expense expense);
  Future<void> delete(String id);
  Future<void> clear();
}

/// Web- and mobile-compatible local implementation backed by Hive
/// (uses IndexedDB on Flutter Web and local files on native platforms).
class HiveExpenseRepository implements ExpenseRepository {
  HiveExpenseRepository(this._box);

  final Box<Expense> _box;

  @override
  List<Expense> getAll() => _box.values.toList(growable: false);

  @override
  Future<void> save(Expense expense) => _box.put(expense.id, expense);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

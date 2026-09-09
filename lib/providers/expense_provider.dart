import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';
import '../providers/settings_provider.dart';
import '../utils/category_utils.dart';

enum ExpensePeriod { allTime, today, thisWeek, thisMonth, thisYear }

extension ExpensePeriodLabel on ExpensePeriod {
  String get label {
    return switch (this) {
      ExpensePeriod.allTime => 'All time',
      ExpensePeriod.today => 'Today',
      ExpensePeriod.thisWeek => 'This week',
      ExpensePeriod.thisMonth => 'This month',
      ExpensePeriod.thisYear => 'This year',
    };
  }
}

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._expenseBox, this._settingsProvider) {
    _loadExpenses();
    seedSampleExpensesIfNeeded();
  }

  static const List<String> categories = CategoryUtils.categories;

  final Box<Expense> _expenseBox;
  final SettingsProvider _settingsProvider;
  final List<Expense> _expenses = [];

  List<Expense> get expenses {
    return List.unmodifiable(_expenses);
  }

  List<Expense> get recentExpenses => expenses.take(6).toList();

  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .toList();
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get currentMonthTotal {
    return currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get previousMonthTotal {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    return expenses
        .where(
          (expense) =>
              expense.date.year == previousMonth.year &&
              expense.date.month == previousMonth.month,
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  int get currentMonthTransactionCount => currentMonthExpenses.length;

  double get averageTransactionAmount {
    if (expenses.isEmpty) {
      return 0;
    }
    return totalExpenses / expenses.length;
  }

  double get currentMonthDailyAverage {
    final day = DateTime.now().day;
    if (day == 0) {
      return 0;
    }
    return currentMonthTotal / day;
  }

  Expense? get highestExpense {
    if (expenses.isEmpty) {
      return null;
    }
    return expenses.reduce(
      (current, next) => current.amount >= next.amount ? current : next,
    );
  }

  String? get highestCategory {
    final totals = currentMonthExpensesByCategory;
    if (totals.isEmpty) {
      return null;
    }
    return totals.entries
        .reduce((current, next) => current.value >= next.value ? current : next)
        .key;
  }

  Map<String, double> get expensesByCategory {
    return categoryTotalsFor(expenses);
  }

  Map<String, double> get currentMonthExpensesByCategory {
    return categoryTotalsFor(currentMonthExpenses);
  }

  Map<String, double> categoryTotalsFor(List<Expense> source) {
    final totals = {for (final category in categories) category: 0.0};

    for (final expense in source) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    totals.removeWhere((_, value) => value == 0);
    return totals;
  }

  Map<String, double> get weeklyTotals {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final totals = <String, double>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final labels = totals.keys.toList();

    for (final expense in expenses) {
      final dateOnly = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final dayIndex = dateOnly.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        totals[labels[dayIndex]] = totals[labels[dayIndex]]! + expense.amount;
      }
    }

    return totals;
  }

  Map<String, double> get monthlyExpenses {
    final now = DateTime.now();
    final totals = <String, double>{};

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      totals[_monthKey(month)] = 0;
    }

    for (final expense in expenses) {
      final key = _monthKey(expense.date);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + expense.amount;
      }
    }

    return totals;
  }

  List<Expense> filteredExpenses({
    required String searchQuery,
    required String category,
    required ExpensePeriod period,
  }) {
    final query = searchQuery.trim().toLowerCase();
    return expenses.where((expense) {
      final matchesSearch =
          query.isEmpty ||
          expense.title.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query);
      final matchesCategory = category == 'All' || expense.category == category;
      final matchesPeriod = _matchesPeriod(expense.date, period);
      return matchesSearch && matchesCategory && matchesPeriod;
    }).toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _expenses.removeWhere((item) => item.id == expense.id);
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      _expenses.add(expense);
    } else {
      _expenses[index] = expense;
    }
    _sortExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
  }

  Future<void> restoreExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _expenses.removeWhere((item) => item.id == expense.id);
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
  }

  Future<void> clearAllExpenses() async {
    await _expenseBox.clear();
    _expenses.clear();
    notifyListeners();
  }

  Future<void> seedSampleExpensesIfNeeded() async {
    if (_settingsProvider.sampleDataSeeded || _expenseBox.isNotEmpty) {
      if (!_settingsProvider.sampleDataSeeded && _expenseBox.isNotEmpty) {
        await _settingsProvider.markSampleDataSeeded();
      }
      return;
    }

    for (final expense in _sampleExpenses()) {
      await _expenseBox.put(expense.id, expense);
    }
    await _settingsProvider.markSampleDataSeeded();
    _loadExpenses();
    notifyListeners();
  }

  Future<void> restoreSampleData() async {
    for (final expense in _sampleExpenses()) {
      await _expenseBox.put(expense.id, expense);
      _expenses.removeWhere((item) => item.id == expense.id);
      _expenses.add(expense);
    }
    await _settingsProvider.markSampleDataSeeded();
    _sortExpenses();
    notifyListeners();
  }

  void _loadExpenses() {
    _expenses
      ..clear()
      ..addAll(_expenseBox.values);
    _sortExpenses();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  String _monthKey(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  bool _matchesPeriod(DateTime date, ExpensePeriod period) {
    final now = DateTime.now();
    final expenseDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    return switch (period) {
      ExpensePeriod.allTime => true,
      ExpensePeriod.today => expenseDate == today,
      ExpensePeriod.thisWeek =>
        !expenseDate.isBefore(
              today.subtract(Duration(days: today.weekday - 1)),
            ) &&
            !expenseDate.isAfter(today),
      ExpensePeriod.thisMonth =>
        date.year == now.year && date.month == now.month,
      ExpensePeriod.thisYear => date.year == now.year,
    };
  }

  List<Expense> _sampleExpenses() {
    final now = DateTime.now();
    DateTime daysAgo(int days) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days));
    }

    return [
      Expense(
        id: 'sample-rewe-groceries',
        title: 'REWE Groceries',
        amount: 34.80,
        category: 'Food',
        date: daysAgo(0),
      ),
      Expense(
        id: 'sample-bvg-monthly-ticket',
        title: 'BVG Monthly Ticket',
        amount: 49.00,
        category: 'Transport',
        date: daysAgo(1),
      ),
      Expense(
        id: 'sample-coffee',
        title: 'Coffee',
        amount: 4.20,
        category: 'Food',
        date: daysAgo(2),
      ),
      Expense(
        id: 'sample-spotify-premium',
        title: 'Spotify Premium',
        amount: 10.99,
        category: 'Entertainment',
        date: daysAgo(3),
      ),
      Expense(
        id: 'sample-university-printing',
        title: 'University Printing',
        amount: 7.50,
        category: 'University',
        date: daysAgo(4),
      ),
      Expense(
        id: 'sample-electricity-bill',
        title: 'Electricity Bill',
        amount: 38.40,
        category: 'Bills',
        date: daysAgo(5),
      ),
      Expense(
        id: 'sample-football-shoes',
        title: 'Football Shoes',
        amount: 64.99,
        category: 'Shopping',
        date: daysAgo(7),
      ),
      Expense(
        id: 'sample-monthly-rent',
        title: 'Monthly Rent',
        amount: 520.00,
        category: 'Rent',
        date: daysAgo(10),
      ),
      Expense(
        id: 'sample-lunch-with-friends',
        title: 'Lunch with Friends',
        amount: 18.60,
        category: 'Food',
        date: daysAgo(12),
      ),
      Expense(
        id: 'sample-phone-recharge',
        title: 'Phone Recharge',
        amount: 14.99,
        category: 'Bills',
        date: daysAgo(15),
      ),
      Expense(
        id: 'sample-cinema-ticket',
        title: 'Cinema Ticket',
        amount: 13.50,
        category: 'Entertainment',
        date: daysAgo(20),
      ),
      Expense(
        id: 'sample-train-trip',
        title: 'Train Trip',
        amount: 29.90,
        category: 'Transport',
        date: daysAgo(35),
      ),
    ];
  }
}

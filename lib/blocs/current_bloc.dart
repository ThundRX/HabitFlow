import 'package:flutter/material.dart';

import 'package:habitflow/helpers/date_format.dart';
import 'package:habitflow/helpers/days.dart';
import 'package:habitflow/models/cycle.dart';
import 'package:habitflow/models/day.dart';
import 'package:habitflow/models/status.dart';
import 'package:habitflow/services/analytics/analytics.dart';
import 'package:habitflow/services/current_cycle/current_cycle.dart';
import 'package:habitflow/services/cycles/cycles.dart';
import 'package:habitflow/services/habits/habits.dart';

/// Bloc to manage current cycle and statuses of habits.
class CurrentBloc extends ChangeNotifier {
  /// Constructs.
  CurrentBloc() {
    _update();
  }

  final CurrentCycleDAO _dao = CurrentCycleDAO();
  final CyclesDAO _cyclesDAO = CyclesDAO();
  final HabitsDAO _habitsDAO = HabitsDAO();

  /// Days of cycle.
  Days _days;

  /// Current cycle.
  Cycle current;

  /// Statuses of all habits.
  Map<String, Status> statuses;

  /// Updates [statuses] and [current].
  Future<void> _update() async {
    if (current == null) {
      current = await _dao.get();
      if (current == null) {
        await create();
      }
    }

    if (isEnded()) {
      /// If [current] has ended then stop.
      notifyListeners();
      return;
    }

    // Fills missing days and unmarked failures.
    _days = Days(current.days);
    await _days.fill(
      parseDate(current.start),
      parseDate(current.end),
      _habitsDAO,
    );
    current.days = _days.days;
    await _updateStatuses();

    /// Updates.
    await _dao.update(current);
    notifyListeners();
  }

  /// Updates current days active habits.
  Future<void> updateActiveHabits() async {
    final DateTime date = DateTime.now();
    current.days[formatDate(date)].activeHabits = await _habitsDAO.active(date);
    await _update();
  }

  /// Deletes history of habit with [id].
  Future<void> deleteHistory(String id) async {
    _days.deleteHistory(id);
    current.days = _days.days;
    await _update();
  }

  /// Marks habit with [id] as [status].
  Future<void> mark(
    String id,
    Status status, [
    String reason,
    DateTime date,
  ]) async {
    _days.mark(id, status, reason: reason, date: date ?? DateTime.now());
    await _update();
  }

  /// Updates [statuses].
  Future<void> _updateStatuses() async {
    statuses = <String, Status>{};
    for (final String id in await _habitsDAO.active(DateTime.now())) {
      statuses[id] = _days.status(id);
    }
  }

  /// Creates a new cycle and updates [current].
  Future<void> create() async {
    final Day day = Day(
      date: formatDate(DateTime.now()),
      activeHabits: await _habitsDAO.active(DateTime.now()),
    );
    current = Cycle(
      start: formatDate(DateTime.now()),
      end: formatDate(DateTime.now().add(const Duration(days: 15))),
      days: {day.date: day},
    );
    await _dao.create(current);
    await _update();
    Analytics().logSimple('cycle_added');
  }

  /// Ends a cycle, puts in previous cycles, then creates new one.
  Future<void> end() async {
    await _cyclesDAO.add(current);
    await create();
    await _update();
    Analytics().logSimple('cycle_ended');
  }

  /// Returns if [current] ended.
  bool isEnded() {
    return (DateTime.now().isAfter(parseDate(current.end))) ||
        current.end == formatDate(DateTime.now());
  }

  @override
  void dispose() {
    super.dispose();
    _cyclesDAO.close();
    _dao.close();
    _habitsDAO.close();
  }
}

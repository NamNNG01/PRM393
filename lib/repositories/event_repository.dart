import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/event.dart';

class EventRepository {
  final Box<Event> _box = Hive.box<Event>(HiveBoxes.eventBox);

  List<Event> getAllEvents() {
    return _box.values.toList();
  }

  Future<void> addEvent(Event event) async {
    await _box.add(event);
  }

  Future<void> updateEvent(int index, Event event) async {
    await _box.putAt(index, event);
  }

  Future<void> deleteEvent(int index) async {
    await _box.deleteAt(index);
  }
}
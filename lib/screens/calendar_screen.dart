// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<DateTime, List<Map<String, dynamic>>> wateringEvents = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    fetchWateringReminders();
  }

  Future<void> fetchWateringReminders() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('plants')
            .where('uid', isEqualTo: user?.uid)
            .get();

    final now = DateTime.now();
    final Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String name = data['name'] ?? 'Plant';
      final String water = data['water'] ?? 'Everyday';
      final String plantId = doc.id;
      final Timestamp? lastWateredTimestamp = data['lastWatered'];
      final DateTime? lastWatered = lastWateredTimestamp?.toDate();

      final interval = _getWateringIntervalDays(water);
      if (interval == null) continue;

      DateTime reminderDay = now;

      for (int i = 0; i < 30; i += interval) {
        final date = DateTime(
          reminderDay.year,
          reminderDay.month,
          reminderDay.day + i,
        );
        final key = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(key, () => []).add({
          'name': name,
          'plantId': plantId,
          'lastWatered': lastWatered,
        });
      }
    }

    setState(() {
      wateringEvents = events;
    });
  }

  int? _getWateringIntervalDays(String frequency) {
    switch (frequency) {
      case 'Everyday':
        return 1;
      case 'Every Other Day':
        return 2;
      case 'Twice a Week':
        return 3;
      case 'Once a Week':
        return 7;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return wateringEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _markAsWatered(String plantId) async {
    await FirebaseFirestore.instance.collection('plants').doc(plantId).update({
      'lastWatered': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked as watered!')));

    fetchWateringReminders(); // Refresh reminders
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return now.year == day.year && now.month == day.month && now.day == day.day;
  }

  bool _isWateredToday(DateTime? lastWatered) {
    if (lastWatered == null) return false;
    final now = DateTime.now();
    return now.year == lastWatered.year &&
        now.month == lastWatered.month &&
        now.day == lastWatered.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watering Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.lightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                _selectedDay == null
                    ? const Center(
                      child: Text("Select a day to view reminders"),
                    )
                    : ListView(
                      children:
                          _getEventsForDay(_selectedDay!).map((event) {
                            final String plantName = event['name'];
                            final String plantId = event['plantId'];
                            final DateTime? lastWatered = event['lastWatered'];

                            final bool isToday = _isToday(_selectedDay!);
                            final bool isWatered = _isWateredToday(lastWatered);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.local_florist,
                                  color: Colors.green,
                                ),
                                title: Text('Water $plantName'),
                                trailing:
                                    isToday
                                        ? (isWatered
                                            ? const Chip(
                                              label: Text('Watered'),
                                              backgroundColor:
                                                  Colors.lightGreen,
                                            )
                                            : ElevatedButton(
                                              onPressed:
                                                  () => _markAsWatered(plantId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              child: const Text(
                                                'Mark as Watered',
                                              ),
                                            ))
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}

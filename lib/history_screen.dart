import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'localization.dart';

// FIX: Removed nested Scaffold and AppBar — parent handles the app bar.
// FIX: Added isNepali parameter so localisation works correctly in this tab.
// FIX: Reads from box.get('history') instead of filtering medicines,
//      so it shows the full persistent log including past daily entries.
// FIX: Replaced all deprecated .withOpacity() with .withValues(alpha:)

class HistoryScreen extends StatelessWidget {
  final bool isNepali;

  const HistoryScreen({super.key, required this.isNepali});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('medBox');

    // Reads from the persistent history key written by _appendHistory()
    List history = box.get('history', defaultValue: []);
    history = history.reversed.toList();

    return history.isEmpty
        ? Center(
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 80, color: Colors.teal[200]),
                  const SizedBox(height: 16),
                  Text(
                    Loc.get("No history yet!", isNepali),
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final isTaken = item["status"] == "taken";

              // FIX: withOpacity() → withValues(alpha:)
              Color cardColor = isTaken
                  ? Colors.green.shade50.withValues(alpha: 0.8)
                  : Colors.red.shade50.withValues(alpha: 0.8);
              MaterialColor accentColor =
                  isTaken ? Colors.green : Colors.red;

              return FadeInLeft(
                duration: const Duration(milliseconds: 400),
                delay:
                    Duration(milliseconds: 100 * (index % 10)),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    // FIX: withOpacity() → withValues(alpha:)
                    side: BorderSide(
                      color:
                          accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // FIX: withOpacity() → withValues(alpha:)
                            color: accentColor
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTaken
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: accentColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatDate(item["date"]),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    item["time"] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            // FIX: withOpacity() → withValues(alpha:)
                            color: accentColor
                                .withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            (item["status"] ?? '').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentColor[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    DateTime dt = DateTime.parse(date);
    String d = dt.day.toString().padLeft(2, '0');
    String m = dt.month.toString().padLeft(2, '0');
    return "$d/$m/${dt.year}";
  }
}
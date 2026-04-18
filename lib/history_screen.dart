import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'localization.dart';

class HistoryScreen extends StatelessWidget {
  final bool isNepali;
  const HistoryScreen({super.key, this.isNepali = false});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('medBox');
    List medicines = box.get('medicines', defaultValue: []);

    List history = medicines
        .where((med) => med['status'] != "pending")
        .toList();

    history = history.reversed.toList();
    return history.isEmpty
        ? Center(
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.teal[200]),
                  const SizedBox(height: 16),
                  Text(
                    Loc.get("No History", isNepali),
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
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
              
              Color cardColor = isTaken ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.red.shade50.withValues(alpha: 0.5);
              MaterialColor accentColor = isTaken ? Colors.green : Colors.red;

              return FadeInLeft(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: 100 * (index % 10)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTaken ? Icons.check_circle : Icons.cancel,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  formatDate(item["date"]),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  item["time"],
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item["status"].toUpperCase(),
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
              ),
            ),
          ),
        );
      },
          );
  }

  String formatDate(String? date) {
    if (date == null) return "";

    DateTime dt = DateTime.parse(date);
    
    // Add leading zero if needed
    String d = dt.day.toString().padLeft(2, '0');
    String m = dt.month.toString().padLeft(2, '0');

    return "$d/$m/${dt.year}";
  }
}

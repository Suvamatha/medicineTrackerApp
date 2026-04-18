import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'history_screen.dart';
import 'splash_screen.dart';
import 'localization.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('medBox');

  tz.initializeTimeZones() ;

  const AndroidInitializationSettings andriodSetting = 
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSetting = InitializationSettings(android: andriodSetting);

  await flutterLocalNotificationsPlugin.initialize(initSetting);
  
  runApp(MyApp());

 
}

Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
  bool repeatDaily = false,
}) async {
  final now = DateTime.now();

  DateTime scheduleDate = DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute
  );
  
  if (scheduleDate.isBefore(now)) {
    scheduleDate = scheduleDate.add(const Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduleDate, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'med_channel',
        'Medicine Reminder',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
  );
}

Future<void> snoozeNotification(int originalId, String name) async {
  final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
  await scheduleNotification(
    id: originalId + 10000, // Safe offset for snoozed IDs
    title: 'Snoozed: $name',
    body: 'It has been 10 minutes. Please take your medicine.',
    hour: snoozeTime.hour,
    minute: snoozeTime.minute,
    repeatDaily: false,
  );
}

 Future<void> showNotification()async {
    const AndroidNotificationDetails andriodDetails = 
    AndroidNotificationDetails(
      'med_channel',
      'Medicine Remainder',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: andriodDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Time to take your medicine',
      'Please take your medicine now',
      details,
    );

    
  }


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.teal),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MedicineScreen extends StatefulWidget {
  @override
  _MedicineScreenState createState() => _MedicineScreenState();
}



class _MedicineScreenState extends State<MedicineScreen> {

  int total = 0;
  int taken = 0;
  int missed = 0;
  int pending = 0;

  void updateState(){
  total = medicines.length;
  taken = medicines.where((m) => m['status'] == "taken").length;
  missed = medicines.where((m) => m['status'] == "missed").length;
  pending = medicines.where((m) => m['status'] == "pending").length;
}

  var box = Hive.box('medBox');
  List medicines = [];
  final TextEditingController nameController = TextEditingController();

  TimeOfDay? selectedTime;

  bool repeatDaily = false;
  bool isNepali = false;

  @override
  void initState() {
    super.initState();
    isNepali = box.get('isNepali', defaultValue: false);
    _checkDailyReset();
    medicines = box.get('medicines', defaultValue: []);
    updateState();
  }

  void _exportData() {
    final Map<String, dynamic> data = {
      "medicines": box.get('medicines', defaultValue: []),
      "history": box.get('history', defaultValue: [])
    };
    final String jsonStr = jsonEncode(data);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Loc.get("Copied", isNepali))),
    );
  }

  void _checkDailyReset() {
    String today = DateTime.now().toString().substring(0, 10);
    String? lastOpened = box.get('lastOpenedDate');
    
    if (lastOpened != today) {
      List meds = box.get('medicines', defaultValue: []);
      for (var m in meds) {
        if (m['repeatDaily'] == true && m['status'] != 'pending') {
          m['status'] = 'pending';
        }
      }
      box.put('medicines', meds);
      box.put('lastOpenedDate', today);
    }
  }

  void _showAddMedicineSheet(BuildContext context) {
    bool localRepeat = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Loc.get("Add Medication", isNepali),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    onChanged: (val) {
                      String lower = val.toLowerCase();
                      if (lower.contains("morning") || lower.contains("बिहान")) {
                        setModalState(() { selectedTime = const TimeOfDay(hour: 8, minute: 0); });
                      } else if (lower.contains("afternoon") || lower.contains("lunch") || lower.contains("दिउँसो")) {
                        setModalState(() { selectedTime = const TimeOfDay(hour: 13, minute: 0); });
                      } else if (lower.contains("night") || lower.contains("evening") || lower.contains("sleep") || lower.contains("राति")) {
                        setModalState(() { selectedTime = const TimeOfDay(hour: 21, minute: 0); });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: Loc.get("Medicine Name", isNepali),
                      prefixIcon: const Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.teal[50],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                        });
                        setState(() {
                          updateState();
                          selectedTime = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedTime == null
                          ? Loc.get("Select Time", isNepali)
                          : selectedTime!.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal[100],
                      foregroundColor: Colors.teal[900],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(Loc.get("Repeat Daily", isNepali), style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(Loc.get("Remind me every day", isNepali)),
                    value: localRepeat,
                    activeColor: Colors.teal,
                    onChanged: (bool value) {
                      setModalState(() {
                        localRepeat = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(Loc.get("Please enter", isNepali))),
                        );
                        return;
                      }

                      int newId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

                      await scheduleNotification(
                        id: newId,
                        title: 'Medicine Reminder',
                        body: 'Time to take: ${nameController.text}',
                        hour: selectedTime!.hour,
                        minute: selectedTime!.minute,
                        repeatDaily: localRepeat,
                      );
                      
                      setState(() {
                        medicines.add({
                          "id": newId,
                          "name": nameController.text,
                          "time": selectedTime!.format(context),
                          "status": "pending",
                          "repeatDaily": localRepeat,
                        });
                        box.put('medicines', medicines);
                      });
                      
                      nameController.clear();
                      selectedTime = null;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(Loc.get("Save Medicine", isNepali), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.clear();
      setState(() {
        selectedTime = null;
      });
    });
  }

  int _selectedIndex = 0;

  Widget _buildDashboardTab() {
    // ---- ANALYTICS LOGIC ----
    List history = box.get('history', defaultValue: []);
    
    // Streak gamification
    int currentStreak = 0;
    int bestStreak = 0;
    
    // Group history by date string 'YYYY-MM-DD'
    Map<String, List<dynamic>> historyByDate = {};
    for (var h in history) {
      if (h['date'] != null) {
        String dt = h['date'].toString().substring(0,10);
        historyByDate.putIfAbsent(dt, () => []).add(h);
      }
    }
    
    List<String> sortedDates = historyByDate.keys.toList()..sort();
    for (String d in sortedDates) {
      bool missedAny = historyByDate[d]!.any((h) => h['status'] == 'missed');
      bool takenAny = historyByDate[d]!.any((h) => h['status'] == 'taken');
      if (missedAny) {
        if (currentStreak > bestStreak) bestStreak = currentStreak;
        currentStreak = 0;
      } else if (takenAny) {
        currentStreak++;
      }
    }
    if (currentStreak > bestStreak) bestStreak = currentStreak;

    // Weekly Adherence
    int weekTaken = 0;
    int weekMissed = 0;
    final sevDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    for (var h in history) {
      if (h['date'] != null) {
        DateTime dt = DateTime.parse(h['date']);
        if (dt.isAfter(sevDaysAgo)) {
          if (h['status'] == 'taken') weekTaken++;
          if (h['status'] == 'missed') weekMissed++;
        }
      }
    }
    int totalWeek = weekTaken + weekMissed;
    double adherence = totalWeek == 0 ? 0.0 : (weekTaken / totalWeek) * 100;

    // Last 5 days Missed Trend (Chart Data)
    List<int> missedTrend = [0, 0, 0, 0, 0];
    for (int i = 0; i < 5; i++) {
        String d = DateTime.now().subtract(Duration(days: 4 - i)).toString().substring(0, 10);
        if (historyByDate.containsKey(d)) {
            missedTrend[i] = historyByDate[d]!.where((h) => h['status'] == 'missed').length;
        }
    }
    int maxMissed = missedTrend.reduce((a, b) => a > b ? a : b);
    if (maxMissed == 0) maxMissed = 1;

    String streakIcon = "";
    if (bestStreak >= 7) {
      streakIcon = " 🎖️";
    } else if (bestStreak >= 3) {
      streakIcon = " 🔥";
    }

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: ListView(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Loc.get("Today's Progress", isNepali),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildStat(Loc.get("Total", isNepali), total),
                      buildStat(Loc.get("Taken", isNepali), taken),
                      buildStat(Loc.get("Missed", isNepali), missed),
                      buildStat(Loc.get("Pending", isNepali), pending),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 16),
                  Text(
                    Loc.get("Analytics & Gamification", isNepali),
                     style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildStat(Loc.get("Weekly Adherence", isNepali), adherence.toInt(), isPercent: true),
                      ),
                      Expanded(
                        child: buildStat(Loc.get("Best Streak", isNepali), bestStreak, extra: streakIcon),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      double barHeight = (missedTrend[4 - i] / maxMissed) * 40;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight == 0 ? 4 : barHeight,
                            width: 12,
                            decoration: BoxDecoration(
                              color: missedTrend[4 - i] > 0 ? Colors.redAccent.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "-${4 - i}d",
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          )
                        ],
                      );
                    }),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMedicinesTab() {
    return medicines.isEmpty
        ? Center(
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.teal[200]),
                          const SizedBox(height: 16),
                          Text(
                            "No medications added yet.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap + to add your first reminder.",
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // extra padding for FAB
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index];
                final isTaken = med["status"] == "taken";
                final isMissed = med["status"] == "missed";
                
                Color cardColor = Colors.white.withValues(alpha: 0.3);
                MaterialColor accentColor = Colors.teal;
                if (isTaken) {
                  accentColor = Colors.green;
                  cardColor = Colors.green.shade50.withValues(alpha: 0.5);
                } else if (isMissed) {
                  accentColor = Colors.red;
                  cardColor = Colors.red.shade50.withValues(alpha: 0.5);
                }

                return FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: 100 * (index % 10)),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                          child: Icon(Icons.medication, color: accentColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med["name"],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  decoration: isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    med["time"],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      med["status"].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (med["status"] == "pending") ...[
                          IconButton(
                            icon: const Icon(Icons.snooze, color: Colors.orange, size: 32),
                            onPressed: () async {
                              await snoozeNotification(med["id"] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000), med["name"]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Snoozed ${med["name"]} for 10 minutes')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                            onPressed: () {
                              setState(() {
                                med["status"] = "taken";
                                med["date"] = DateTime.now().toString();
                                box.put('medicines', medicines);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                            onPressed: () {
                              setState(() {
                                med["status"] = "missed";
                                med["date"] = DateTime.now().toString();
                                box.put('medicines', medicines);
                              });
                            },
                          ),
                        ] else ...[
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                            onPressed: () {
                              setState(() {
                                medicines.removeAt(index);
                                box.put('medicines', medicines);
                              });
                            },
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final List<String> _titles = ["Dashboard", "Medicines", "History"];

    Widget _getBody() {
      switch (_selectedIndex) {
        case 0:
          return _buildDashboardTab();
        case 1:
          return _buildMedicinesTab();
        case 2:
          return HistoryScreen(isNepali: isNepali);
        default:
          return _buildDashboardTab();
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(Loc.get(_titles[_selectedIndex], isNepali)),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Text(isNepali ? '🇬🇧' : '🇳🇵', style: const TextStyle(fontSize: 22)),
            tooltip: isNepali ? 'Switch to English' : 'नेपालीमा बदल्नुहोस्',
            onPressed: () {
              setState(() {
                isNepali = !isNepali;
                box.put('isNepali', isNepali);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export Data',
            onPressed: _exportData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2DFDB)], // Premium soft teal glow gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: _getBody()),
      ),
      floatingActionButton: _selectedIndex == 1
          ? BounceInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 300),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                onPressed: () => _showAddMedicineSheet(context),
                icon: const Icon(Icons.add),
                label: const Text("Add Med", style: TextStyle(fontWeight: FontWeight.bold)),
                elevation: 4,
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
            updateState(); // Ensure stats are fresh
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: Loc.get('Dashboard', isNepali),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication),
            label: Loc.get('Medicines', isNepali),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: Loc.get('History', isNepali),
          ),
        ],
      ),
    );
  }

  Widget buildStat(String label, int value, {bool isPercent = false, String extra = ""}){
    return Column(
      children: [
        Text(
          "$value${isPercent ? '%' : ''}$extra",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}

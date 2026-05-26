import 'package:flutter/material.dart';

class StudentAnalyticsSection extends StatelessWidget {
  final Map<dynamic, dynamic> logsData;

  const StudentAnalyticsSection({super.key, required this.logsData});

  @override
  Widget build(BuildContext context) {
    // Mga lalagyan ng data
    Map<String, int> dailySectionFrequency = {};
    Map<String, double> monthlyCourseVolume = {};

    DateTime ngayon = DateTime.now();

    // Pag-proseso ng bawat entry sa dispense_logs
    logsData.forEach((key, value) {
      if (value is Map) {
        int amountMl = value['amount_ml'] ?? 0;
        String timestampStr = value['timestamp'] ?? '';
        double liters = amountMl / 1000.0;

        // Kung walang nakuhang course/section/year sa lumang log, bibigyan natin ng malinis na default string
        String fullCourse = value['course'] ?? '';
        String section = value['section'] ?? '';
        String year = value['year'] ?? '';

        // Kung walang kurso, ibig sabihin luma o hindi naka-register nang maayos ang log
        if (fullCourse.isEmpty) {
          fullCourse = "Unregistered / Guest";
        }

        // Pag-ikli ng pangalan ng kurso para kasya sa UI cards
        String courseCode = fullCourse;
        if (fullCourse.contains("Information Technology")) {
          courseCode = "BSIT";
        } else if (fullCourse.contains("Business Administration")) {
          courseCode = "BSBA";
        } else if (fullCourse.contains("Hospitality Management")) {
          courseCode = "BSHM";
        } else if (fullCourse.contains("Education")) {
          courseCode = "BSED";
        }

        // --- REQ 1 & 3: DAILY BREAKDOWN & FREQUENCY (IN-PLACE REPLACEMENT) ---
        try {
          DateTime logDate = DateTime.parse(timestampStr);
          if (logDate.year == ngayon.year && 
              logDate.month == ngayon.month && 
              logDate.day == ngayon.day) {
              
            String groupKey;
            if (fullCourse == "Unregistered / Guest" || fullCourse.isEmpty) {
              groupKey = "Guest / Unknown";
            } else {
              groupKey = "$courseCode ${year.replaceAll(' Year', '')} - $section".trim(); 
              // Magiging: "BSIT 3rd - 3C" para hindi masyadong mahaba
            }
            dailySectionFrequency[groupKey] = (dailySectionFrequency[groupKey] ?? 0) + 1;
          }
        } catch (e) {
          // Iwas error kung sakaling corrupted ang timestamp string
        }

        // --- REQ 2: MONTHLY TOP COURSE ---
        try {
          DateTime logDate = DateTime.parse(timestampStr);
          if (logDate.year == ngayon.year && logDate.month == ngayon.month) {
            monthlyCourseVolume[courseCode] = (monthlyCourseVolume[courseCode] ?? 0.0) + liters;
          }
        } catch (e) {
          // Iwas error sa parsing
        }
      }
    });

    // I-sort ang mga data para laging una ang pinakamataas
    var sortedDailyFrequency = dailySectionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var sortedMonthlyVolume = monthlyCourseVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Hydration Analytics",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 15),
          
          // Responsive layout gamit ang Row para magkatabi silang dalawa gaya ng standard web dashboard
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KARD NG DAILY BREAKDOWN AT FREQUENCY
              Expanded(
                child: _buildAnalyticsCard(
                  title: "Today's Active Groups & Frequency",
                  subtitle: "Daily breakdown of usage per section",
                  icon: Icons.today_rounded,
                  iconColor: Colors.blue,
                  child: sortedDailyFrequency.isEmpty
                      ? _buildEmptyState("No logs recorded for today yet.")
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedDailyFrequency.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            var entry = sortedDailyFrequency[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${entry.value} Dispenses",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 20),
              
              // KARD NG MONTHLY TOP COURSE
              Expanded(
                child: _buildAnalyticsCard(
                  title: "Monthly Top Course Leaderboard",
                  subtitle: "Total water consumption volume this month",
                  icon: Icons.leaderboard_rounded,
                  iconColor: Colors.orange,
                  child: sortedMonthlyVolume.isEmpty
                      ? _buildEmptyState("No data gathered for this month.")
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedMonthlyVolume.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            var entry = sortedMonthlyVolume[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                child: Text("#${index + 1}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: Text(
                                "${entry.value.toStringAsFixed(2)} L",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // REUSABLE CARD CONTAINER DESIGN
  Widget _buildAnalyticsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // EMPTY STATE INDICATOR
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'leaderboard_detail_page.dart';

class StudentAnalyticsSection extends StatelessWidget {
  final Map<dynamic, dynamic> logsData;

  const StudentAnalyticsSection({super.key, required this.logsData});

  @override
  Widget build(BuildContext context) {
    Map<String, int> dailySectionFrequency = {};
    Map<String, double> monthlyCourseVolume = {};

    DateTime ngayon = DateTime.now();

    // Pag-proseso ng bawat entry sa dispense_logs
    logsData.forEach((key, value) {
      if (value is Map) {
        // Safe amount_ml parsing
        double amountMl = 0.0;
        dynamic rawAmount = value['amount_ml'];
        if (rawAmount is num) {
          amountMl = rawAmount.toDouble();
        } else if (rawAmount != null) {
          amountMl = double.tryParse(rawAmount.toString()) ?? 0.0;
        }

        // Safe timestamp parsing
        dynamic rawTimestamp = value['timestamp'];
        DateTime? logDate;
        if (rawTimestamp is int) {
          logDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp).toLocal();
        } else if (rawTimestamp is num) {
          logDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt()).toLocal();
        } else if (rawTimestamp is String) {
          logDate = DateTime.tryParse(rawTimestamp)?.toLocal();
          if (logDate == null) {
            int? parsedInt = int.tryParse(rawTimestamp);
            if (parsedInt != null) {
              logDate = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
            }
          }
        }

        double liters = amountMl / 1000.0;

        String fullCourse = value['course']?.toString() ?? '';
        String section = value['section']?.toString() ?? '';
        String year = value['year']?.toString() ?? '';

        if (fullCourse.isEmpty) {
          fullCourse = "Faculty / Utility Officer";
        }

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

        if (logDate != null) {
          // Daily breakdown & frequency
          if (logDate.year == ngayon.year &&
              logDate.month == ngayon.month &&
              logDate.day == ngayon.day) {
            String groupKey;
            if (fullCourse == "Unregistered / Guest" || fullCourse.isEmpty) {
              groupKey = "Guest / Unknown";
            } else {
              groupKey = "$courseCode ${year.replaceAll(' Year', '')} - $section".trim();
            }
            dailySectionFrequency[groupKey] = (dailySectionFrequency[groupKey] ?? 0) + 1;
          }

          // Monthly top course
          if (logDate.year == ngayon.year && logDate.month == ngayon.month) {
            monthlyCourseVolume[courseCode] = (monthlyCourseVolume[courseCode] ?? 0.0) + liters;
          }
        }
      }
    });

    var sortedDailyFrequency = dailySectionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var sortedMonthlyVolume = monthlyCourseVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    // Daily Frequency Card Layout
    Widget dailyFrequencyCard = _buildAnalyticsCard(
      title: "Today's Active Groups",
      subtitle: "Daily breakdown of usage per section",
      icon: Icons.today_rounded,
      iconColor: const Color(0xFF2563EB),
      badgeText: "${sortedDailyFrequency.length} Active",
      badgeColor: const Color(0xFF2563EB),
      child: sortedDailyFrequency.isEmpty
          ? _buildEmptyState("No logs recorded for today yet.")
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDailyFrequency.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                var entry = sortedDailyFrequency[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${entry.value} Dispenses",
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );

    // Monthly Leaderboard Card Layout
    Widget monthlyLeaderboardCard = _buildAnalyticsCard(
      title: "Monthly Top Course Leaderboard",
      subtitle: "Total water consumption volume this month",
      icon: Icons.leaderboard_rounded,
      iconColor: const Color(0xFFEA580C),
      badgeText: "This Month",
      badgeColor: const Color(0xFFEA580C),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardDetailPage()),
        );
      },
      child: sortedMonthlyVolume.isEmpty
          ? _buildEmptyState("No data gathered for this month.")
          : Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedMonthlyVolume.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    var entry = sortedMonthlyVolume[index];
                    
                    Color rankColor;
                    if (index == 0) {
                      rankColor = const Color(0xFFEAB308); // Gold
                    } else if (index == 1) {
                      rankColor = const Color(0xFF94A3B8); // Silver
                    } else if (index == 2) {
                      rankColor = const Color(0xFFD97706); // Bronze
                    } else {
                      rankColor = const Color(0xFF64748B);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "#${index + 1}",
                              style: TextStyle(
                                color: rankColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${entry.value.toStringAsFixed(1)} L",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "View Full Analytics",
                      style: TextStyle(
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFEA580C),
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Student Hydration Analytics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        if (isMobile)
          Column(
            children: [
              dailyFrequencyCard,
              const SizedBox(height: 16),
              monthlyLeaderboardCard,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dailyFrequencyCard),
              const SizedBox(width: 16),
              Expanded(child: monthlyLeaderboardCard),
            ],
          ),
      ],
    );
  }

  // Modern Card Component
  Widget _buildAnalyticsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor ?? Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Empty State Container
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class TimetablePage extends StatefulWidget {
  final List<Map<String, String>> subjects;

  const TimetablePage({super.key, required this.subjects});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
    with SingleTickerProviderStateMixin {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late TabController _tabController;

  final Map<int, String> _dayIndexToFull = {
    0: 'Monday',
    1: 'Tuesday',
    2: 'Wednesday',
    3: 'Thursday',
    4: 'Friday',
    5: 'Saturday',
    6: 'Sunday',
  };

  int get _todayIndex {
    final day = DateTime.now().weekday; // 1=Mon, 7=Sun
    return day - 1;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _todayIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _subjectsForDay(int dayIndex) {
    final dayName = _days[dayIndex];
    return widget.subjects
        .where((s) => (s['days'] ?? '').contains(dayName))
        .toList()
      ..sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF1A1A2E) : Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Weekly Timetable',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Container(
            color: Colors.blueGrey[800],
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              tabs: _days.asMap().entries.map((entry) {
                final isToday = entry.key == _todayIndex;
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.value),
                      if (isToday)
                        Container(
                          margin: EdgeInsets.only(top: 3),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_days.length, (dayIndex) {
          final isToday = dayIndex == _todayIndex;
          final daySubjects = _subjectsForDay(dayIndex);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isToday
                      ? LinearGradient(
                          colors: [
                            Colors.blueGrey[800]!,
                            Colors.blueGrey[600]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isToday
                      ? null
                      : isDark
                      ? Color(0xFF2A2A3E)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayIndexToFull[dayIndex]!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Colors.white
                                : isDark
                                ? Colors.white
                                : Colors.blueGrey[900],
                          ),
                        ),
                        Text(
                          isToday
                              ? 'Today'
                              : '${daySubjects.length} class${daySubjects.length == 1 ? '' : 'es'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isToday ? Colors.white70 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    if (isToday)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${daySubjects.length} class${daySubjects.length == 1 ? '' : 'es'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Subject list
              Expanded(
                child: daySubjects.isEmpty
                    ? _buildEmptyDay(isDark)
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: daySubjects.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildClassCard(daySubjects[index], index, isDark),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildClassCard(Map<String, String> subject, int index, bool isDark) {
    final colors = [
      Colors.blue[600]!,
      Colors.teal[600]!,
      Colors.purple[600]!,
      Colors.orange[600]!,
      Colors.pink[600]!,
      Colors.indigo[600]!,
    ];
    final color = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color left bar
          Container(
            width: 5,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          SizedBox(width: 14),
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.book_rounded, color: color, size: 20),
          ),
          SizedBox(width: 14),
          // Subject info
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['subject']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.blueGrey[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: color),
                      SizedBox(width: 4),
                      Text(
                        subject['time']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyDay(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 40,
              color: Colors.blueGrey[300],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No classes today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.blueGrey[700],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Enjoy your free day!',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

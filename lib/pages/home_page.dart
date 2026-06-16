import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'timetable_page.dart';
import 'library_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.username,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> subjects = [];
  bool _isLoading = true;
  late String _username;

  final TextEditingController _subjectController = TextEditingController();
  String? _selectedTime;

  final List<String> _timeSlots = [
    '6:00 - 8:00',
    '8:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
  ];

  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadUserData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['username'] != null) {
        if (mounted) {
          setState(() => _username = userDoc.data()!['username']);
        }
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('subjects')
          .get();

      if (!mounted) return;

      setState(() {
        subjects = snapshot.docs
            .map((doc) => Map<String, String>.from(doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('subjects');

    final existing = await collection.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
    for (final subject in subjects) {
      await collection.add(subject);
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'username': newUsername,
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _username = newUsername);
    }
  }

  void _deleteSubject(int index) {
    setState(() => subjects.removeAt(index));
    _saveSubjects();
  }

  void _showAddSubjectDialog() {
    _subjectController.clear();
    _selectedTime = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubjectBottomSheet(
        subjectController: _subjectController,
        timeSlots: _timeSlots,
        allDays: _allDays,
        initialTime: null,
        initialDays: [],
        title: 'Add Subject',
        buttonLabel: 'Add Subject',
        onSubmit: (subject, time, days) {
          setState(() {
            subjects.add({
              'subject': subject,
              'time': time,
              'days': days.join(','),
            });
          });
          _saveSubjects();
        },
      ),
    );
  }

  void _showEditSubjectDialog(int index) {
    _subjectController.text = subjects[index]['subject']!;
    _selectedTime = subjects[index]['time'];
    final existingDays = (subjects[index]['days'] ?? '')
        .split(',')
        .where((d) => d.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubjectBottomSheet(
        subjectController: _subjectController,
        timeSlots: _timeSlots,
        allDays: _allDays,
        initialTime: subjects[index]['time'],
        initialDays: existingDays,
        title: 'Edit Subject',
        buttonLabel: 'Save Changes',
        onSubmit: (subject, time, days) {
          setState(() {
            subjects[index] = {
              'subject': subject,
              'time': time,
              'days': days.join(','),
            };
          });
          _saveSubjects();
        },
      ),
    );
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
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                _username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectDialog,
        backgroundColor: Colors.blueGrey[700],
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.blueGrey[700]),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  SizedBox(height: 24),
                  _buildSubjectList(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.35),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  _username,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${subjects.length} subject${subjects.length == 1 ? '' : 's'} scheduled',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _username[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Subjects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            if (subjects.isNotEmpty)
              Text(
                '${subjects.length} total',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[400]),
              ),
          ],
        ),
        SizedBox(height: 14),
        subjects.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                separatorBuilder: (_, __) => SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildSubjectCard(index, isDark),
              ),
      ],
    );
  }

  Widget _buildSubjectCard(int index, bool isDark) {
    final colors = [
      Colors.blue[600]!,
      Colors.teal[600]!,
      Colors.purple[600]!,
      Colors.orange[600]!,
      Colors.pink[600]!,
      Colors.indigo[600]!,
    ];
    final color = colors[index % colors.length];
    final days = (subjects[index]['days'] ?? '')
        .split(',')
        .where((d) => d.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LibraryPage(initialQuery: subjects[index]['subject']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2A2A3E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.book_rounded, color: color, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjects[index]['subject']!,
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
                        subjects[index]['time']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (days.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: days.map((day) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.local_library_rounded,
                        size: 12,
                        color: Colors.blueGrey[300],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to find related books',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey[300],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                if (val == 'edit') _showEditSubjectDialog(index);
                if (val == 'delete') _deleteSubject(index);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.blueGrey[700],
                      ),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: Colors.blueGrey[300],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No subjects yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.blueGrey[700],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap + Add Subject to get started',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 28,
                  child: Text(
                    _username[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blueGrey[800],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _username,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${subjects.length} subject${subjects.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          _DrawerTile(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerTile(
            icon: Icons.calendar_month_rounded,
            label: 'Timetable',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimetablePage(subjects: subjects),
                ),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.local_library_rounded,
            label: 'Library',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LibraryPage()),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.person_rounded,
            label: 'Account',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountPage(
                    username: _username,
                    subjectCount: subjects.length,
                    subjects: subjects,
                  ),
                ),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                    username: _username,
                    onUsernameChanged: _updateUsername,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      horizontalTitleGap: 8,
    );
  }
}

class _SubjectBottomSheet extends StatefulWidget {
  final TextEditingController subjectController;
  final List<String> timeSlots;
  final List<String> allDays;
  final String? initialTime;
  final List<String> initialDays;
  final String title;
  final String buttonLabel;
  final Function(String subject, String time, List<String> days) onSubmit;

  const _SubjectBottomSheet({
    required this.subjectController,
    required this.timeSlots,
    required this.allDays,
    required this.initialTime,
    required this.initialDays,
    required this.title,
    required this.buttonLabel,
    required this.onSubmit,
  });

  @override
  State<_SubjectBottomSheet> createState() => _SubjectBottomSheetState();
}

class _SubjectBottomSheetState extends State<_SubjectBottomSheet> {
  String? _selectedTime;
  late List<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _selectedDays = List.from(widget.initialDays);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Subject Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[600],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: widget.subjectController,
              decoration: InputDecoration(
                hintText: 'e.g. Mathematics',
                prefixIcon: Icon(
                  Icons.book_rounded,
                  color: Colors.blueGrey[400],
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.blueGrey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.blueGrey[600]!,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Class Time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[600],
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedTime != null
                      ? Colors.blueGrey[600]!
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTime,
                  hint: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.blueGrey[400],
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Select a time slot',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  isExpanded: true,
                  icon: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.blueGrey[400],
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  items: widget.timeSlots.map((time) {
                    return DropdownMenuItem(
                      value: time,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.blueGrey[500],
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              time,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : Colors.blueGrey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTime = val),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Days',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[600],
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allDays.map((day) {
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blueGrey[700]
                          : isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Colors.blueGrey[700]!
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : isDark
                            ? Colors.white60
                            : Colors.blueGrey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.subjectController.text.isNotEmpty &&
                      _selectedTime != null &&
                      _selectedDays.isNotEmpty) {
                    widget.onSubmit(
                      widget.subjectController.text,
                      _selectedTime!,
                      _selectedDays,
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fill in all fields and select at least one day',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.buttonLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

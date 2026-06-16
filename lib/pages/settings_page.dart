import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String username;
  final ValueChanged<String> onUsernameChanged;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.username,
    required this.onUsernameChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _notifications;
  late bool _darkMode;
  late String _currentUsername;
  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifications = true;
    _darkMode = widget.isDarkMode;
    _currentUsername = widget.username;
    _usernameController.text = widget.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showChangeUsernameDialog() {
    _usernameController.text = _currentUsername;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Username',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'New username',
            prefixIcon: Icon(Icons.person, color: Colors.blueGrey[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = _usernameController.text.trim();
              if (newUsername.isEmpty) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              // Save to Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'username': newUsername}, SetOptions(merge: true));

              // Update locally
              setState(() => _currentUsername = newUsername);

              // Notify HomePage to update
              widget.onUsernameChanged(newUsername);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Username updated!'),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Current password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.blueGrey[700],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blueGrey[700]!,
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New password',
                prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blueGrey[700]!,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: _oldPasswordController.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(_newPasswordController.text);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password updated successfully!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String message = 'An error occurred';
                if (e.code == 'wrong-password') {
                  message = 'Current password is incorrect';
                } else if (e.code == 'weak-password') {
                  message = 'New password is too weak';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            onThemeChanged: widget.onThemeChanged,
            isDarkMode: widget.isDarkMode,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _SettingsSection(
              title: 'Appearance',
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.dark_mode, color: Colors.blueGrey[700]),
                  title: Text('Dark Mode'),
                  value: _darkMode,
                  activeColor: Colors.blueGrey[700],
                  onChanged: (val) {
                    setState(() => _darkMode = val);
                    widget.onThemeChanged(val);
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            _SettingsSection(
              title: 'Notifications',
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications,
                    color: Colors.blueGrey[700],
                  ),
                  title: Text('Enable Notifications'),
                  value: _notifications,
                  activeColor: Colors.blueGrey[700],
                  onChanged: (val) => setState(() => _notifications = val),
                ),
              ],
            ),
            SizedBox(height: 16),
            _SettingsSection(
              title: 'Account',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: Colors.blueGrey[700],
                  ),
                  title: Text('Change Username'),
                  subtitle: Text(
                    _currentUsername,
                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChangeUsernameDialog,
                ),
                Divider(height: 1, color: Colors.grey[200]),
                ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: Colors.blueGrey[700],
                  ),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
            SizedBox(height: 16),
            _SettingsSection(
              title: 'Session',
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ...children,
        ],
      ),
    );
  }
}

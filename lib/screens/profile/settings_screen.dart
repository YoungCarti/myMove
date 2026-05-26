import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  // Helper to show Delete Account Confirmation Dialog
  void _showDeleteConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete your myMove account? This action cannot be undone and you will lose all bookings and settings.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                try {
                  // Show loading toast or handle loading state
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deleting account...'),
                      backgroundColor: Color(0xFF1E1E1E),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await authProvider.deleteAccount();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account permanently deleted.'),
                        backgroundColor: Color(0xFFFF453A),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: ${e.toString().replaceAll('Exception:', '')}'),
                        backgroundColor: const Color(0xFFFF453A),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDisable2FADialog(BuildContext context, AuthProvider authProvider) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          title: const Text(
            'Disable 2FA?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to disable Two-Factor Authentication? Your account will be less secure.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter 6-digit Authenticator Code',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, letterSpacing: 4.0),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 4.0),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid 6-digit code.'),
                      backgroundColor: Color(0xFFFF453A),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(); // Close dialog
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disabling 2FA...'),
                      backgroundColor: Color(0xFF1E1E1E),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await authProvider.disable2FA(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Two-factor authentication disabled.'),
                        backgroundColor: Color(0xFFFF453A),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to disable 2FA: ${e.toString().replaceAll('Exception:', '')}'),
                        backgroundColor: const Color(0xFFFF453A),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Disable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.email;
    final username = authProvider.username;
    final phone = authProvider.phoneNumber;

    final isUsernameSet = username.isNotEmpty;
    final isPhoneSet = phone.isNotEmpty;
    final is2FAEnabled = authProvider.is2FAEnabled;

    Future<void> handle2FAToggle(bool targetValue) async {
      if (targetValue) {
        // Turning ON
        if (authProvider.totpSecret.isEmpty) {
          Navigator.pushNamed(context, '/setup_2fa');
        } else {
          try {
            await authProvider.toggle2FA(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                  backgroundColor: Color(0xFF32D74B),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to enable 2FA: ${e.toString().replaceAll('Exception:', '')}'),
                  backgroundColor: const Color(0xFFFF453A),
                ),
              );
            }
          }
        }
      } else {
        // Turning OFF - prompt dialog
        _showDisable2FADialog(context, authProvider);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Card 1: Basic Info ───────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'BASIC INFO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.04),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Email Tile (Read-Only)
                    _buildSettingsRow(
                      label: 'Email',
                      valueWidget: Text(
                        email.isNotEmpty ? email : 'No email linked',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white12,
                        size: 20,
                      ),
                      onTap: () {
                        // Read-only email
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registered email address cannot be changed in-app.'),
                            backgroundColor: Color(0xFF1E1E1E),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),

                    // Mobile Number Tile
                    _buildSettingsRow(
                      label: 'Mobile Number',
                      valueWidget: Text(
                        isPhoneSet ? phone : 'Not set up',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: isPhoneSet ? Colors.white70 : const Color(0xFFFF453A),
                          fontSize: 15,
                          fontWeight: isPhoneSet ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        isPhoneSet ? Icons.edit_outlined : Icons.chevron_right_rounded,
                        color: isPhoneSet ? Colors.white38 : Colors.white30,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/enter_mobile');
                      },
                    ),
                    _buildDivider(),

                    // Username Tile
                    _buildSettingsRow(
                      label: 'Username',
                      valueWidget: Text(
                        isUsernameSet ? '@$username' : 'Not set up',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: isUsernameSet ? Colors.white70 : const Color(0xFFFF453A),
                          fontSize: 15,
                          fontWeight: isUsernameSet ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        isUsernameSet ? Icons.edit_outlined : Icons.chevron_right_rounded,
                        color: isUsernameSet ? Colors.white38 : Colors.white30,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/update_username');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Card 2: Security ──────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'SECURITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.04),
                    width: 1,
                  ),
                ),
                child: _buildSettingsRow(
                  label: '2FA Authentication',
                  valueWidget: Switch(
                    value: is2FAEnabled,
                    onChanged: (bool value) => handle2FAToggle(value),
                    activeColor: const Color(0xFF32D74B),
                    activeTrackColor: const Color(0xFF32D74B).withOpacity(0.3),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                  ),
                  trailing: const SizedBox.shrink(),
                  onTap: () => handle2FAToggle(!is2FAEnabled),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Card 4: Delete Account ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF453A).withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: () => _showDeleteConfirmation(context, authProvider),
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFFF453A),
                    size: 22,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF453A),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF453A),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper settings tile row
  Widget _buildSettingsRow({
    required String label,
    required Widget valueWidget,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: valueWidget,
              ),
            ),
            if (trailing != const SizedBox.shrink()) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  // Custom Divider to match the dark color
  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.04),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

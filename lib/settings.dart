import 'package:flutter/material.dart';
import 'services/primary_service.dart';

// settings.dart shows the app's settings screen
// right now it has a progress summary and a "Reset All Progress" button
// Settings screen UI inspired by: https://docs.flutter.dev/cookbook/design/themes
//                             and https://api.flutter.dev/flutter/material/AlertDialog-class.html

// StatefulWidget because we need to rebuild when quiz scores change
// StatefulWidget docs: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
class SettingsScreen extends StatefulWidget {
  final FirstAidService service; // passed in from main.dart so we reuse the same singleton

  const SettingsScreen({super.key, required this.service});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _primaryPink = Color.fromARGB(255, 250, 183, 178);
  static const Color _darkRed = Color(0xFFB71C1C);

  // _confirmResetProgress shows a "are you sure?" dialog before wiping all scores
  // AlertDialog docs: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  void _confirmResetProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C)),
            SizedBox(width: 8),
            Text('Reset All Progress'),
          ],
        ),
        content: const Text(
          'This will permanently erase all your quiz progress across every category. '
          'This action cannot be undone.',
        ),
        actions: [
          // Cancel just closes the dialog without doing anything
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);                  // close the dialog
              widget.service.resetAllProgress();   // wipe all scores from memory and storage
              // show a brief confirmation message floating at the bottom of the screen
              // ScaffoldMessenger docs: https://api.flutter.dev/flutter/material/ScaffoldMessenger-class.html
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('All progress has been reset.'),
                    ],
                  ),
                  backgroundColor: _darkRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // build() assembles the settings screen: progress section then about section
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryPink,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Progress section ──────────────────────────────────────────
          _SectionHeader(title: 'Progress'),
          const SizedBox(height: 8),
          // AnimatedBuilder watches the service and rebuilds this card automatically
          // whenever quiz scores change (like right after clicking Reset)
          // AnimatedBuilder docs: https://api.flutter.dev/flutter/widgets/AnimatedBuilder-class.html
          AnimatedBuilder(
            animation: widget.service,
            builder: (context, _) {
              final summary = widget.service.getOverallProgress();
              return _SettingsCard(
                children: [
                  // row showing "X/Y" total correct answers
                  _ProgressStat(
                    label: 'Total Questions Answered',
                    value:
                        '${summary.correctAnswers}/${summary.totalQuestions}',
                    icon: Icons.quiz_outlined,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall completion',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            // toStringAsFixed(0) chops off the decimal so it shows "60%" not "60.0%"
                            Text(
                              '${(summary.progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // the main progress bar showing overall quiz completion
                        // LinearProgressIndicator docs: https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: summary.progress, // 0.0 = nothing done, 1.0 = all correct
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: _primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // reset button in its own separate card
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.refresh,
                iconColor: _darkRed,
                title: 'Reset All Progress',
                subtitle: 'Erase all quiz scores and start fresh',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap: () => _confirmResetProgress(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── About section ─────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: Colors.blueGrey,
                title: 'First Aid Education',
                subtitle: 'Version 1.0.0',
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.medical_services_outlined,
                iconColor: _primaryPink,
                title: 'Disclaimer',
                subtitle:
                    'This app is for educational purposes only and is not a substitute for professional medical advice.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

// _SectionHeader shows the small all-caps label above each group of settings
// like "PROGRESS" or "ABOUT"
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(), // force uppercase no matter what was passed in
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2, // extra space between letters for the small-caps label look
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

// _SettingsCard is a white rounded container that groups settings tiles together
// Container docs: https://api.flutter.dev/flutter/widgets/Container-class.html
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge, // clips children so they don't overflow the rounded corners
      child: Column(
        children: children,
      ),
    );
  }
}

// _SettingsTile is one tappable row inside a settings card
// shows a colored icon box, a title, an optional subtitle, and an optional trailing widget
// InkWell docs: https://api.flutter.dev/flutter/material/InkWell-class.html
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;    // optional - not every tile needs a subtitle
  final Widget? trailing;    // optional - like a chevron arrow or a toggle switch
  final VoidCallback? onTap; // optional - if null, the tile isn't tappable

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // null = not tappable (for info-only tiles like the disclaimer)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // colored square icon badge on the left side
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1), // faint tint of the icon color as background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // title and subtitle stacked vertically, takes remaining horizontal space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // only render the subtitle if one was provided
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!, // render trailing widget if one was given
          ],
        ),
      ),
    );
  }
}

// _ProgressStat shows one stat row with a pink icon, a label, and a value on the right
// used for the "Total Questions Answered: X/Y" row in the progress card
class _ProgressStat extends StatelessWidget {
  final String label;
  final String value; // pre-formatted string like "7/20"
  final IconData icon;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // pink icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 250, 183, 178).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: const Color.fromARGB(255, 250, 183, 178), size: 20),
          ),
          const SizedBox(width: 14),
          // label fills the middle, value is pinned to the far right
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

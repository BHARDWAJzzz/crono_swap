import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final appConfigProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('settings')
      .snapshots()
      .map((doc) => doc.data() ?? _defaultConfig);
});

const Map<String, dynamic> _defaultConfig = {
  'signupBonus': 10,
  'xpPerSwap': 50,
  'xpPerReview': 10,
  'xpPerLecture': 30,
  'streakBonus': 20,
  'razorpayEnabled': false,
  'razorpayKeyId': '',
  'creditPackages': [],
  'maintenanceMode': false,
  'minAppVersion': '1.0.0',
};

class AdminConfigPage extends ConsumerStatefulWidget {
  const AdminConfigPage({super.key});

  @override
  ConsumerState<AdminConfigPage> createState() => _AdminConfigPageState();
}

class _AdminConfigPageState extends ConsumerState<AdminConfigPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _signupBonusController;
  late TextEditingController _xpPerSwapController;
  late TextEditingController _xpPerReviewController;
  late TextEditingController _xpPerLectureController;
  late TextEditingController _streakBonusController;
  late TextEditingController _razorpayKeyController;
  late TextEditingController _minVersionController;
  bool _razorpayEnabled = false;
  bool _maintenanceMode = false;

  // Credit packages
  final List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _signupBonusController = TextEditingController();
    _xpPerSwapController = TextEditingController();
    _xpPerReviewController = TextEditingController();
    _xpPerLectureController = TextEditingController();
    _streakBonusController = TextEditingController();
    _razorpayKeyController = TextEditingController();
    _minVersionController = TextEditingController();
  }

  @override
  void dispose() {
    _signupBonusController.dispose();
    _xpPerSwapController.dispose();
    _xpPerReviewController.dispose();
    _xpPerLectureController.dispose();
    _streakBonusController.dispose();
    _razorpayKeyController.dispose();
    _minVersionController.dispose();
    super.dispose();
  }

  void _loadConfig(Map<String, dynamic> config) {
    _signupBonusController.text = '${config['signupBonus'] ?? 10}';
    _xpPerSwapController.text = '${config['xpPerSwap'] ?? 50}';
    _xpPerReviewController.text = '${config['xpPerReview'] ?? 10}';
    _xpPerLectureController.text = '${config['xpPerLecture'] ?? 30}';
    _streakBonusController.text = '${config['streakBonus'] ?? 20}';
    _razorpayKeyController.text = config['razorpayKeyId'] ?? '';
    _minVersionController.text = config['minAppVersion'] ?? '1.0.0';
    _razorpayEnabled = config['razorpayEnabled'] ?? false;
    _maintenanceMode = config['maintenanceMode'] ?? false;
    _packages.clear();
    final pkgs = config['creditPackages'] as List<dynamic>? ?? [];
    for (final pkg in pkgs) {
      _packages.add(Map<String, dynamic>.from(pkg));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('app_config').doc('settings').set({
        'signupBonus': int.tryParse(_signupBonusController.text) ?? 10,
        'xpPerSwap': int.tryParse(_xpPerSwapController.text) ?? 50,
        'xpPerReview': int.tryParse(_xpPerReviewController.text) ?? 10,
        'xpPerLecture': int.tryParse(_xpPerLectureController.text) ?? 30,
        'streakBonus': int.tryParse(_streakBonusController.text) ?? 20,
        'razorpayEnabled': _razorpayEnabled,
        'razorpayKeyId': _razorpayKeyController.text.trim(),
        'creditPackages': _packages,
        'maintenanceMode': _maintenanceMode,
        'minAppVersion': _minVersionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration saved!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addPackage() {
    final hoursCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Credit Package', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Crono Hours', hintText: 'e.g. 5'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (INR)', hintText: 'e.g. 99'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final hours = int.tryParse(hoursCtrl.text);
              final price = int.tryParse(priceCtrl.text);
              if (hours != null && price != null) {
                setState(() => _packages.add({'hours': hours, 'priceINR': price}));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(appConfigProvider);
    bool initialized = false;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('App Configuration', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade900,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _save,
              child: Text('SAVE', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          if (!initialized) {
            _loadConfig(config);
            initialized = true;
          }
          return _buildForm(theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) {
          _loadConfig(_defaultConfig);
          return _buildForm(theme);
        },
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('💰 Economy'),
            _buildNumberField(_signupBonusController, 'Signup Bonus (Hours)', Icons.card_giftcard_rounded),
            const SizedBox(height: 32),

            _buildSectionHeader('🏆 Gamification'),
            _buildNumberField(_xpPerSwapController, 'XP per Swap', Icons.swap_horiz_rounded),
            _buildNumberField(_xpPerReviewController, 'XP per Review', Icons.star_rounded),
            _buildNumberField(_xpPerLectureController, 'XP per Lecture Sold', Icons.school_rounded),
            _buildNumberField(_streakBonusController, 'Streak Bonus XP', Icons.local_fire_department_rounded),
            const SizedBox(height: 32),

            _buildSectionHeader('💳 Razorpay'),
            SwitchListTile(
              title: const Text('Enable In-App Purchases'),
              value: _razorpayEnabled,
              onChanged: (val) => setState(() => _razorpayEnabled = val),
              activeColor: theme.colorScheme.primary,
            ),
            if (_razorpayEnabled) ...[
              _buildTextField(_razorpayKeyController, 'Razorpay Key ID', Icons.key_rounded),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Credit Packages', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  IconButton(onPressed: _addPackage, icon: const Icon(Icons.add_circle_rounded, color: Colors.green)),
                ],
              ),
              ..._packages.asMap().entries.map((entry) => ListTile(
                    leading: Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                    title: Text('${entry.value['hours']} Hours'),
                    subtitle: Text('₹${entry.value['priceINR']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _packages.removeAt(entry.key)),
                    ),
                  )),
            ],
            const SizedBox(height: 32),

            _buildSectionHeader('⚙️ System'),
            SwitchListTile(
              title: const Text('Maintenance Mode'),
              subtitle: const Text('Blocks new users from accessing the app'),
              value: _maintenanceMode,
              onChanged: (val) => setState(() => _maintenanceMode = val),
              activeColor: Colors.red,
            ),
            _buildTextField(_minVersionController, 'Minimum App Version', Icons.phone_android_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (val) => (int.tryParse(val ?? '') == null) ? 'Enter a number' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}

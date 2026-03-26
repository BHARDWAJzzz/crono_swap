import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  final List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Design', 'Coding', 'Cooking', 'Music', 'Fitness', 'Language', 'Marketing', 'Photography'
  ];

  bool _isLoading = false;
  int _currentPage = 0;
  DateTime? _selectedDob;
  String? _selectedAvatarUrl;

  final List<String> _avatarOptions = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Max&backgroundColor=d1d4f9',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Luna&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Oliver&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Caleb&backgroundColor=ffdfbf',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _submit() async {
    // Only validate if on a form page
    if (_currentPage > 0 && !_formKey.currentState!.validate()) return;

    if (_currentPage == 1) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authRepositoryProvider).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_currentPage == 3) {
      if (_selectedDob == null) {
        _showError('Please select your Date of Birth');
        return;
      }
      setState(() => _isLoading = true);
      try {
        await ref.read(authRepositoryProvider).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          interests: _selectedInterests,
          dob: _selectedDob!,
          avatarUrl: _selectedAvatarUrl,
        );
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $msg'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 60), // Space for back button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWelcomePage(theme),
                        _buildLoginPage(theme),
                        _buildSignUpBasicPage(theme),
                        _buildSignUpProfilePage(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 160), // Space for dots and buttons
              ],
            ),
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: _buildActionButtons(theme),
            ),
            if (_currentPage > 0)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: _prevPage,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mascot.png',
                height: 280,
              ),
              const SizedBox(height: 40),
              Text(
                'Value time,\nShare wisdom.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Join the world\'s first skill exchange where minutes are the only currency.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'CRONO SWAP',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          width: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Skill exchange powered by time.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log in',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Please enter your details.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hintText: 'alex@example.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) => val!.contains('@') ? null : 'Invalid email',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: '••••••••',
              icon: Icons.shield_moon_outlined,
              obscureText: true,
              validator: (val) => val!.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentPage = 2);
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Don\'t have an account? '),
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpBasicPage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your account',
            style: GoogleFonts.outfit(
              fontSize: 28, 
              fontWeight: FontWeight.w900, 
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your digital identity and details.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _nameController,
            label: 'FULL NAME',
            hintText: 'Alex Johnson',
            icon: Icons.person_outline,
            validator: (val) => val!.isEmpty ? 'Enter your name' : null,
          ),
          
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHOOSE YOUR AVATAR',
                style: GoogleFonts.outfit(
                  fontSize: 12, 
                  fontWeight: FontWeight.w800, 
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final randomName = ['Felix', 'Aneka', 'Max', 'Luna', 'Oliver', 'Caleb', 'Zoe', 'Leo'].elementAt(DateTime.now().millisecond % 8);
                  final randomColor = ['b6e3f4', 'ffdfbf', 'd1d4f9', 'ffd5dc', 'c0aede'].elementAt(DateTime.now().second % 5);
                  final newAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=$randomName${DateTime.now().millisecond}&backgroundColor=$randomColor';
                  setState(() => _selectedAvatarUrl = newAvatar);
                  if (!_avatarOptions.contains(newAvatar)) {
                    _avatarOptions.insert(0, newAvatar);
                  }
                },
                icon: Icon(Icons.refresh_rounded, size: 14, color: theme.colorScheme.primary),
                label: Text('Randomize', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _avatarOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final url = _avatarOptions[index];
                final isSelected = _selectedAvatarUrl == url;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarUrl = url),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2), 
                          blurRadius: 15, 
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        )
                      ] : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade50,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _emailController,
            label: 'EMAIL ADDRESS',
            hintText: 'alex@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val!.contains('@') ? null : 'Invalid email',
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDob = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDob == null 
                      ? 'DATE OF BIRTH' 
                      : 'BORN ON: ${DateFormat('MMM d, yyyy').format(_selectedDob!)}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedDob == null ? Colors.grey.shade500 : Colors.black87,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: 'PASSWORD',
            hintText: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (val) => val!.length < 6 ? 'Min 6 chars' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpProfilePage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more',
            style: GoogleFonts.outfit(
              fontSize: 28, 
              fontWeight: FontWeight.w900, 
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How can you help the community?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _bioController,
            label: 'SHORT BIO',
            hintText: 'e.g. I can help with Flutter and UI Design',
            icon: Icons.edit_note_outlined,
            maxLines: 3,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'SELECT YOUR INTERESTS',
            style: GoogleFonts.outfit(
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                    ] : null,
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(color: Colors.grey.shade300, fontSize: 15, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.red.shade100, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    String label = 'Log in';
    VoidCallback onPressed = _submit;

    if (_currentPage == 0) {
      label = 'Get Started';
      onPressed = _nextPage;
    } else if (_currentPage == 1) {
      label = 'Continue';
      onPressed = _submit;
    } else if (_currentPage == 2) {
      label = 'Next Step';
      onPressed = () {
        if (_formKey.currentState!.validate()) _nextPage();
      };
    } else if (_currentPage == 3) {
      label = 'Create Account';
      onPressed = _submit;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

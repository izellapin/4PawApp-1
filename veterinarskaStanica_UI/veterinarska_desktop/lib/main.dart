import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'screens/appointment_screen.dart';
import 'screens/financial_dashboard.dart';
import 'screens/pets_screen.dart';
import 'screens/veterinarians_screen.dart';
import 'screens/reviews_screen.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force reset ServiceLocator to ensure correct platform-specific URLs
  print('🔄 Desktop: Forcing ServiceLocator reset to ensure localhost URL...');
  if (serviceLocator.isInitialized) {
    await serviceLocator.reset();
  } else {
    await serviceLocator.initialize();
  }
  print('✅ Desktop: ServiceLocator initialized with correct configuration');
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: '4Paw Veterinarska Stanica - Desktop',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => serviceLocator.authService),
      ],
      child: MaterialApp(
        title: '4Paw Veterinarska Stanica - Desktop',
      theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF2E7D32),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authService.isLoggedIn) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await serviceLocator.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Check user role after successful login
      final userData = serviceLocator.authService.currentUser;
      if (userData != null) {
        final roleValue = userData['role'];
        final isEmailVerified = userData['isEmailVerified'] ?? true;
        bool isAllowedRole = false;
        
        if (roleValue is int) {
          // Handle numeric role (1-based indexing)
          if (roleValue > 0 && roleValue <= UserRole.values.length) {
            final userRole = UserRole.values[roleValue - 1];
            isAllowedRole = userRole == UserRole.admin || userRole == UserRole.veterinarian;
          }
        } else if (roleValue is String) {
          // Handle string role names
          final roleLower = roleValue.toLowerCase();
          isAllowedRole = roleLower == 'admin' || roleLower == 'administrator' || 
                         roleLower == 'veterinarian' || roleLower == 'vet';
        }
        
        if (!isAllowedRole) {
          // Logout user and show error
          await serviceLocator.authService.logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Desktop aplikacija je dostupna samo za administratore i veterinare'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (!isEmailVerified) {
          // Skip email verification for desktop app - veterinarians are pre-verified
          // Email verification is only required for mobile app users
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dobrodošli! Email verifikacija nije potrebna za desktop aplikaciju.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri prijavi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailVerificationDialog() {
    final verificationController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verifikacija email adrese'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Poslan vam je verifikacijski kod na email adresu. Molimo unesite kod da završite registraciju.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: verificationController,
              decoration: const InputDecoration(
                labelText: 'Verifikacijski kod',
                border: OutlineInputBorder(),
                hintText: 'Unesite 6-cifreni kod',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isVerifying ? null : () async {
              // Logout user
              await serviceLocator.authService.logout();
              Navigator.of(context).pop();
            },
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: isVerifying ? null : () async {
              final code = verificationController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Molimo unesite verifikacijski kod'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() => isVerifying = true);

              try {
                // Get current user email
                final userData = serviceLocator.authService.currentUser;
                final email = userData?['email'] ?? '';
                
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Greška: Email adresa nije pronađena'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Call API to verify email
                await serviceLocator.apiClient.verifyEmail(email, code);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email je uspješno verificiran!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Greška pri verifikaciji: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => isVerifying = false);
              }
            },
            child: isVerifying 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verificiraj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with dimming overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/pets_group.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B5E20).withOpacity(0.8),
                    const Color(0xFF2E7D32).withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and title
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '4Paw Veterinarska Stanica',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Desktop aplikacija',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Unesite e-mail';
                          }
                          if (!value.contains('@')) {
                            return 'Unesite valjan e-mail';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Lozinka',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Unesite lozinku';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Prijavite se',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  UserRole? _userRole;
  final ValueNotifier<int> _petCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  void dispose() {
    _petCountNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      // Get user data from auth service instead of API call
      final userData = serviceLocator.authService.currentUser;
      if (userData != null) {
        final roleValue = userData['role'];
        UserRole? userRole;
        
        print('🔍 User role value: $roleValue (type: ${roleValue.runtimeType})');
        
        if (roleValue is int) {
          // Handle numeric role (1-based indexing)
          if (roleValue > 0 && roleValue <= UserRole.values.length) {
            userRole = UserRole.values[roleValue - 1];
          }
        } else if (roleValue is String) {
          // Handle string role names
          switch (roleValue.toLowerCase()) {
            case 'petowner':
            case 'pet owner':
              userRole = UserRole.petOwner;
              break;
            case 'veterinarian':
            case 'vet':
              userRole = UserRole.veterinarian;
              break;
            case 'veterinarytechnician':
            case 'veterinary technician':
            case 'technician':
              userRole = UserRole.veterinaryTechnician;
              break;
            case 'receptionist':
              userRole = UserRole.receptionist;
              break;
            case 'admin':
            case 'administrator':
              userRole = UserRole.admin;
              break;
            default:
              // Try to parse as number
              final roleInt = int.tryParse(roleValue);
              if (roleInt != null && roleInt > 0 && roleInt <= UserRole.values.length) {
                userRole = UserRole.values[roleInt - 1];
              }
          }
        }
        
        if (userRole != null) {
          setState(() {
            _userRole = userRole;
          });
          print('✅ User role set to: $_userRole');
        } else {
          print('❌ Could not parse role value: $roleValue');
          // Default to petOwner for safety
          setState(() {
            _userRole = UserRole.petOwner;
          });
        }
      }
    } catch (e) {
      print('Error loading user role: $e');
      // Default to petOwner for safety
      setState(() {
        _userRole = UserRole.petOwner;
      });
    }
  }

  List<Widget> _getScreens() {
    if (_userRole == null) return [const Center(child: CircularProgressIndicator())];
    
    return [
      ValueListenableBuilder<int>(
        valueListenable: _petCountNotifier,
        builder: (context, petCount, child) {
          return FinancialDashboard(userRole: _userRole!);
        },
      ),
      AppointmentScreen(userRole: _userRole!),
      PetsScreen(
        userRole: _userRole!,
        onPetCreated: () {
          // Notify da je kreiran novi pacijent
          _petCountNotifier.value++;
        },
      ),
      if (_userRole == UserRole.admin)
        const VeterinariansScreen(userRole: UserRole.admin),
      if (_userRole == UserRole.admin)
        const ReviewsScreen(),
      const ProfilePage(),
    ];
  }

  List<NavigationItem> _getNavigationItems() {
    final items = [
      NavigationItem(
        icon: Icons.dashboard,
        label: _userRole == UserRole.admin ? 'Kontrolna tabla' : 'Moje statistike',
      ),
      NavigationItem(
        icon: Icons.calendar_month,
        label: _userRole == UserRole.admin ? 'Svi termini' : 'Moji termini',
      ),
      NavigationItem(
        icon: Icons.pets,
        label: 'Pacijenti',
      ),
    ];
    
    // Dodaj Veterinari samo za admin
    if (_userRole == UserRole.admin) {
      items.add(
        NavigationItem(
          icon: Icons.medical_services,
          label: 'Veterinari',
        ),
      );
      items.add(
        NavigationItem(
          icon: Icons.reviews,
          label: 'Recenzije',
        ),
      );
    }
    
    items.add(
      NavigationItem(
        icon: Icons.person,
        label: 'Profil',
      ),
    );
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _getScreens();
    final navigationItems = _getNavigationItems();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Color(0xFF2E7D32),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '4Paw Veterinarska',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Stanica',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation items
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = navigationItems[index];
                        final isSelected = index == _selectedIndex;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected 
                                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: isSelected 
                                    ? const Color(0xFF2E7D32)
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Logout button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Odjavi se',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () async {
                        await serviceLocator.authService.logout();
                      },
                    ),
                  ),
                ),
                
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}
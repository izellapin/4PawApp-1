import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'screens/appointments/appointments_list_screen.dart';
import 'screens/appointments/book_appointment_screen.dart';
import 'screens/pets/pets_list_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/dashboard_screen.dart';

// Globalne varijable za Stripe ključeve (da izbjegnemo NotInitializedError)
String? globalStripePublishableKey;
String? globalStripeSecretKey;

// Globalni RouteObserver za praćenje navigacije
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
  };
  
  // Load environment variables (if .env file exists)
  try {
    print('💳 [MAIN] Attempting to load .env file...');
    print('💳 [MAIN] Current directory: ${Directory.current.path}');
    
    // Pokušaj učitati .env fajl iz assets (za Android/iOS)
    // Koristimo try-catch da izbjegnemo NotInitializedError
    String? envContent;
    try {
      // Pristup rootBundle prije nego što Stripe SDK provjerava inicijalizaciju
      envContent = await rootBundle.loadString('assets/.env');
      print('✅ [MAIN] Successfully loaded .env from assets');
    } catch (assetsError) {
      print('⚠️ [MAIN] Could not load .env from assets: $assetsError');
      print('⚠️ [MAIN] Error type: ${assetsError.runtimeType}');
      
      // Ako je NotInitializedError, to je Stripe greška - ignoriramo i pokušavamo direktno
      if (assetsError.toString().contains('NotInitializedError') || 
          assetsError.runtimeType.toString().contains('NotInitialized')) {
        print('💡 [MAIN] NotInitializedError detected - this is a Stripe SDK issue');
        print('💡 [MAIN] Trying to load .env directly from file system...');
        try {
          await dotenv.load(fileName: ".env");
          envContent = null; // Signal da je već učitan
          print('✅ [MAIN] .env file loaded from file system successfully');
        } catch (fileError) {
          print('❌ [MAIN] Could not load .env from file system: $fileError');
          // Hardcode ključeve kao fallback
          print('💡 [MAIN] Using hardcoded keys as fallback...');
          globalStripePublishableKey = 'pk_test_51SNB9BCFslvIasynR4kbX2lEXellecCbYdPN7LPCaP9IImiIXJ51YS0HEkIA8B9M3xxwCY0TyrR1OtehTCSDHpV200zkwrdYO7';
          globalStripeSecretKey = 'sk_test_51SNB9BCFslvIasyndmYsoK2xdZJlCh9XqY9zKFbiEnxhTtNdbVEzabMfyasUkwscnW5jM0Y0ZTXyIbWZUWu7XeJ200ngtQnmYO';
          dotenv.env['STRIPE_PUBLISHABLE_KEY'] = globalStripePublishableKey!;
          dotenv.env['STRIPE_SECRET_KEY'] = globalStripeSecretKey!;
          print('✅ [MAIN] Hardcoded keys set as fallback');
          envContent = null; // Signal da je već postavljeno
        }
      } else {
        rethrow;
      }
    }
    
    // Parse envContent ako je učitan iz assets
    if (envContent != null) {
      try {
        final lines = envContent.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;
          final parts = trimmedLine.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            // Bezbedan pristup dotenv.env
            try {
              // Trim vrijednost da uklonimo eventualne razmake
              final trimmedValue = value.trim();
              dotenv.env[key] = trimmedValue;
              
              // Također postavi direktno u globalne varijable
              if (key == 'STRIPE_PUBLISHABLE_KEY') {
                globalStripePublishableKey = trimmedValue;
                print('💳 [MAIN] Set globalStripePublishableKey (length: ${trimmedValue.length})');
                print('💳 [MAIN]   First 20: ${trimmedValue.substring(0, 20)}');
                print('💳 [MAIN]   Last 10: ${trimmedValue.substring(trimmedValue.length - 10)}');
              } else if (key == 'STRIPE_SECRET_KEY') {
                globalStripeSecretKey = trimmedValue;
                print('💳 [MAIN] Set globalStripeSecretKey (length: ${trimmedValue.length})');
                print('💳 [MAIN]   First 20: ${trimmedValue.substring(0, 20)}');
                print('💳 [MAIN]   Last 10: ${trimmedValue.substring(trimmedValue.length - 10)}');
              }
            } catch (e) {
              print('⚠️ [MAIN] Error setting dotenv.env[$key]: $e');
              // Ako je NotInitializedError, koristi direktno globalne varijable
              final trimmedValue = value.trim();
              if (key == 'STRIPE_PUBLISHABLE_KEY') {
                globalStripePublishableKey = trimmedValue;
                print('💳 [MAIN] Set globalStripePublishableKey directly (length: ${trimmedValue.length})');
              } else if (key == 'STRIPE_SECRET_KEY') {
                globalStripeSecretKey = trimmedValue;
                print('💳 [MAIN] Set globalStripeSecretKey directly (length: ${trimmedValue.length})');
              }
            }
          }
        }
        print('✅ [MAIN] .env file parsed and loaded successfully');
      } catch (parseError) {
        print('❌ [MAIN] Error parsing .env content: $parseError');
        print('💡 [MAIN] Using hardcoded keys as fallback...');
        globalStripePublishableKey = 'pk_test_51SNB8oCO2UhMKqFWYvMyM1BIiicOHClmKp9FBvatPOPv34tn7lewZxMVXQz6yEvl2iGZWSnyNy5dDOop1NZRvzvR00FvZdOShC';
        globalStripeSecretKey = 'sk_test_51SNB8oCO2UhMKqFW1wGRHl41T2e99qz73u2WXynaVcRLZ1TlKPlSkTjvZ2dEmS2IcMkFqLSCfA1rgLI2G0zUreqP000k6S1s8aR';
      }
    }
    
    // Sačuvaj ključeve u globalne varijable prije nego što Stripe SDK provjerava inicijalizaciju
    try {
      globalStripePublishableKey ??= dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      globalStripeSecretKey ??= dotenv.env['STRIPE_SECRET_KEY'];
    } catch (e) {
      print('⚠️ [MAIN] Error accessing dotenv.env: $e');
      // Ako globalne varijable nisu postavljene, koristi hardcoded
      if (globalStripePublishableKey == null) {
        print('💡 [MAIN] Using hardcoded publishable key...');
        globalStripePublishableKey = 'pk_test_51SNB9BCFslvIasynR4kbX2lEXellecCbYdPN7LPCaP9IImiIXJ51YS0HEkIA8B9M3xxwCY0TyrR1OtehTCSDHpV200zkwrdYO7';
      }
      if (globalStripeSecretKey == null) {
        print('💡 [MAIN] Using hardcoded secret key...');
        globalStripeSecretKey = 'sk_test_51SNB9BCFslvIasyndmYsoK2xdZJlCh9XqY9zKFbiEnxhTtNdbVEzabMfyasUkwscnW5jM0Y0ZTXyIbWZUWu7XeJ200ngtQnmYO';
      }
    }
    
    print('💳 [MAIN] STRIPE_PUBLISHABLE_KEY loaded: ${globalStripePublishableKey != null}');
    print('💳 [MAIN] STRIPE_SECRET_KEY loaded: ${globalStripeSecretKey != null}');
    if (globalStripePublishableKey != null) {
      print('💳 [MAIN] STRIPE_PUBLISHABLE_KEY length: ${globalStripePublishableKey?.length ?? 0}');
      print('💳 [MAIN] STRIPE_PUBLISHABLE_KEY starts with: ${globalStripePublishableKey?.substring(0, 7) ?? 'null'}');
      print('💳 [MAIN] Global variable set: globalStripePublishableKey = ${globalStripePublishableKey!.substring(0, 20)}...');
    } else {
      print('❌ [MAIN] WARNING: globalStripePublishableKey is NULL after loading .env!');
    }
    if (globalStripeSecretKey != null) {
      print('💳 [MAIN] STRIPE_SECRET_KEY length: ${globalStripeSecretKey?.length ?? 0}');
      print('💳 [MAIN] Global variable set: globalStripeSecretKey = ${globalStripeSecretKey!.substring(0, 20)}...');
    } else {
      print('❌ [MAIN] WARNING: globalStripeSecretKey is NULL after loading .env!');
    }
  } catch (e) {
    // .env file not found - use environment variables or defaults
    print('❌ [MAIN] Warning: .env file not found or error loading: $e');
    print('❌ [MAIN] Error type: ${e.runtimeType}');
    print('💡 [MAIN] Make sure .env file exists in: ${Directory.current.path}');
    print('💡 [MAIN] Global variables will remain null: globalStripePublishableKey = $globalStripePublishableKey');
  }
  
  // Initialize Stripe with error handling
  try {
    final publishableKey = globalStripePublishableKey ?? dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    print('💳 [MAIN] Checking Stripe configuration...');
    print('💳 [MAIN] STRIPE_PUBLISHABLE_KEY exists: ${publishableKey != null}');
    print('💳 [MAIN] STRIPE_PUBLISHABLE_KEY length: ${publishableKey?.length ?? 0}');
    
    if (publishableKey == null || publishableKey.isEmpty) {
      print('❌ [MAIN] STRIPE_PUBLISHABLE_KEY is not set in .env file');
      print('⚠️ [MAIN] Stripe payments will not work until STRIPE_PUBLISHABLE_KEY is configured');
      print('💡 [MAIN] Please create a .env file in the mobile app root with:');
      print('💡 [MAIN] STRIPE_PUBLISHABLE_KEY=pk_test_...');
      print('💡 [MAIN] STRIPE_SECRET_KEY=sk_test_...');
    } else {
      Stripe.publishableKey = publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.4paw.veterinary';
      await Stripe.instance.applySettings();
      print('✅ [MAIN] Stripe initialized successfully');
      print('💳 [MAIN] Stripe.publishableKey: ${Stripe.publishableKey?.substring(0, 20)}...');
    }
  } catch (e) {
    print('❌ [MAIN] Stripe initialization error: $e');
    print('❌ [MAIN] Error type: ${e.runtimeType}');
    print('⚠️ [MAIN] Stripe payments will not work until this is fixed');
    // Continue without Stripe if it fails
  }
  
  // Initialize ServiceLocator with error handling
  try {
    await serviceLocator.initialize();
    print('✅ ServiceLocator initialized successfully');
  } catch (e) {
    print('❌ ServiceLocator initialization failed: $e');
    // Still run the app, but it might have limited functionality
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          if (!serviceLocator.isInitialized) {
            throw StateError('ServiceLocator not initialized');
          }
          return serviceLocator.authService;
        }),
      ],
      child: MaterialApp(
      title: '4Paw Veterinarska Stanica',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
        navigatorObservers: [routeObserver],
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
          return const MobileHomeScreen();
        } else {
          return const MobileLoginScreen();
        }
      },
    );
  }
}

class MobileHomeScreen extends StatefulWidget {
  final int initialIndex;

  const MobileHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;
  int? _previousIndex;
  
  // GlobalKey za appointments screen da možemo pozvati refresh metodu
  final GlobalKey _appointmentsKey = GlobalKey();
  
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previousIndex = _currentIndex;
    
    // Inicijalizuj ekrane sa key-om za appointments screen
    _screens.addAll([
      const MobileDashboardScreen(),
      const MobilePetsListScreen(),
      MobileAppointmentsListScreen(key: _appointmentsKey),
      const MobileProfileScreen(),
    ]);
  }

  void _onTabTapped(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    
    // Osveži appointments ekran kada se vrati na njega
    if (index == 2 && _previousIndex != 2) {
      // Index 2 je appointments ekran
      print('🔄 [HOME] Switched to appointments tab, triggering refresh...');
      // Pozovi refresh metodu direktno koristeći dinamički pristup
      final state = _appointmentsKey.currentState;
      if (state != null) {
        // Koristi dinamički pristup jer je klasa privatna
        try {
          (state as dynamic).refreshAppointments();
        } catch (e) {
          print('⚠️ [HOME] Could not call refreshAppointments: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Pocetna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Ljubimci',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Termini',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
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
      final authService = serviceLocator.authService;
      await authService.login(_emailController.text, _passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gre�ka pri prijavi: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo i naslov
                const Icon(
                  Icons.pets,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 16),
            const Text(
                  '4Paw',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
            const Text(
                  'Veterinarska Stanica',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Email or Username field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Email ili korisničko ime',
                    hintText: 'Email ili username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unesite email ili korisničko ime';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unesite lozinku';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                SizedBox(
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
                
                const SizedBox(height: 16),
                
                // Register link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MobileRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Nemate racun? Registrujte se'),
                ),
                
                const SizedBox(height: 16),
                
                // Info text
            Text(
                  'Aplikacija za vlasnike ljubimaca\nZakazivanje termina i upravljanje pacijentima',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// MobileDashboardScreen moved to lib/screens/home/dashboard_screen.dart

// MobilePetsListScreen moved to lib/screens/pets/pets_list_screen.dart

// MobileProfileScreen moved to lib/screens/profile/profile_screen.dart


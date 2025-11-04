import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

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
      
      // Check user role after successful login
      final userData = authService.currentUser;
      if (userData != null) {
        final roleValue = userData['role'];
        bool isAllowedRole = false;
        
        if (roleValue is int) {
          // Handle numeric role (1-based indexing)
          if (roleValue > 0 && roleValue <= UserRole.values.length) {
            final userRole = UserRole.values[roleValue - 1];
            isAllowedRole = userRole == UserRole.petOwner;
          }
        } else if (roleValue is String) {
          // Handle string role names
          final roleLower = roleValue.toLowerCase();
          isAllowedRole = roleLower == 'petowner' || roleLower == 'pet owner' || 
                         roleLower == 'user' || roleLower == 'client';
        }
        
        if (!isAllowedRole) {
          // Logout user and show error
          await authService.logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mobilna aplikacija je dostupna samo za vlasnike ljubimaca'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
        );
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
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unesite email';
                    }
                    if (!value.contains('@')) {
                      return 'Unesite valjan email';
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
                        builder: (context) => const MobileRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Nemate račun? Registrujte se'),
                ),
                
                const SizedBox(height: 32),
                
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







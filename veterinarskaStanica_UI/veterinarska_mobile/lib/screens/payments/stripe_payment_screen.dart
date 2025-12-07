import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../../main.dart' show globalStripePublishableKey, globalStripeSecretKey;

class StripePaymentScreen extends StatefulWidget {
  final Appointment appointment;
  final double amount;
  final Map<String, dynamic>? service;

  const StripePaymentScreen({
    super.key,
    required this.appointment,
    required this.amount,
    this.service,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _paymentCompleted = false;
  String? _generatedAppointmentCode;
  int? _generatedAppointmentId;
  Appointment? _paidAppointment;

  final commonDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plaćanje"),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32).withOpacity(0.1),
              const Color(0xFF2E7D32).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _paymentCompleted
              ? buildPaymentSuccessScreen()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: buildPaymentForm(context),
                ),
        ),
      ),
    );
  }

  Widget buildPaymentSuccessScreen() {
    final appointmentCode = _generatedAppointmentCode ?? 
        'APT${DateTime.now().millisecondsSinceEpoch}';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Plaćanje uspješno!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vaš termin je potvrđen.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAppointmentCard(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Pregledaj moje termine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    final user = serviceLocator.authService.currentUser;
    final serviceName = widget.service?['name'] ?? 'Veterinary Service';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: CustomPaint(
                  painter: _PerforationPainter(),
                  size: const Size(double.infinity, 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 48,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv(
                                'Pet Owner',
                                user != null
                                    ? '${user['firstName']} ${user['lastName']}'
                                    : 'John Doe',
                              ),
                              _kv('Pet', widget.appointment.petName ?? 'N/A'),
                              _kv(
                                'Amount',
                                '${widget.amount.toStringAsFixed(2)} KM',
                              ),
                              _kv(
                                'Date',
                                '${widget.appointment.appointmentDate.day}/${widget.appointment.appointmentDate.month}/${widget.appointment.appointmentDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Broj termina',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SelectableText(
                              widget.appointment.appointmentNumber,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // QR code removed per request; keeping only appointment number above.
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointment #${widget.appointment.id}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  serviceName,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // QR payload removed.

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentForm(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountCard(),
          const SizedBox(height: 24),
          _buildBillingSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final serviceName = widget.service?['name'] ?? 'Veterinary Service';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const Text(
                'Iznos za plaćanje',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E7D32).withOpacity(0.05),
                  const Color(0xFF2E7D32).withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.amount.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Veterinarski termin',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection() {
    final user = serviceLocator.authService.currentUser;
    final fullName = user != null 
        ? '${user['firstName']} ${user['lastName']}' 
        : 'John Doe';
    final email = user?['email'] ?? 'user@example.com';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informacije za naplatu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('name', 'Ime i prezime', initialValue: fullName),
          const SizedBox(height: 16),
          _buildTextField('email', 'Email', 
              initialValue: email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField('address', 'Adresa', initialValue: 'Glavna ulica'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('city', 'Grad', initialValue: 'Sarajevo'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('state', 'Regija', initialValue: 'BIH'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('country', 'Država', initialValue: 'Bosna i Hercegovina'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'pincode',
                  'ZIP Code',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                  initialValue: '71000',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final Map<String, TextEditingController> _controllers = {};
  
  TextEditingController _getController(String name, String initialValue) {
    if (!_controllers.containsKey(name)) {
      _controllers[name] = TextEditingController(text: initialValue);
    }
    return _controllers[name]!;
  }

  Widget _buildTextField(
    String name,
    String labelText, {
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
    String? initialValue,
  }) {
    return TextFormField(
      controller: _getController(name, initialValue ?? ''),
      decoration: commonDecoration.copyWith(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required.';
        }
        if (isNumeric && double.tryParse(value) == null) {
          return 'This field must be numeric';
        }
        return null;
      },
      keyboardType: keyboardType,
    );
  }
  
  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: _isLoading ? null : () async {
          if (formKey.currentState?.validate() ?? false) {
            final formData = {
              'name': _controllers['name']?.text ?? '',
              'email': _controllers['email']?.text ?? '',
              'address': _controllers['address']?.text ?? '',
              'city': _controllers['city']?.text ?? '',
              'state': _controllers['state']?.text ?? '',
              'country': _controllers['country']?.text ?? '',
              'pincode': _controllers['pincode']?.text ?? '',
            };
            try {
              await _processStripePayment(formData);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Plaćanje neuspješno: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          }
        },
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Nastavi na plaćanje",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _processStripePayment(Map<String, dynamic> formData) async {
    print('💳 [PAYMENT] Starting payment process...');
    print('💳 [PAYMENT] Appointment ID: ${widget.appointment.id}');
    print('💳 [PAYMENT] Amount: ${widget.amount} KM');
    print('💳 [PAYMENT] Form data: $formData');
    
    setState(() => _isLoading = true);

    try {
      print('💳 [PAYMENT] Step 1: Initializing payment sheet...');
      await initPaymentSheet(formData);
      print('✅ [PAYMENT] Payment sheet initialized successfully');

      print('💳 [PAYMENT] Step 2: Presenting payment sheet to user...');
      try {
        await Stripe.instance.presentPaymentSheet();
        print('✅ [PAYMENT] Payment sheet completed successfully');
      } on StripeException catch (e) {
        print('❌ [PAYMENT] Stripe exception occurred');
        print('❌ [PAYMENT] Stripe error code: ${e.error.code}');
        print('❌ [PAYMENT] Stripe error message: ${e.error.message}');
        print('❌ [PAYMENT] Stripe error type: ${e.error.type}');
        print('❌ [PAYMENT] Stripe error decline code: ${e.error.declineCode}');
        rethrow;
      } catch (e) {
        print('❌ [PAYMENT] Unexpected error presenting payment sheet: $e');
        print('❌ [PAYMENT] Error type: ${e.runtimeType}');
        rethrow;
      }

      print('💳 [PAYMENT] Step 3: Marking appointment as paid in backend...');
      try {
        final apiClient = serviceLocator.apiClient;
        final transactionId = 'pi_stripe_${widget.appointment.id}_${DateTime.now().millisecondsSinceEpoch}';
        print('💳 [PAYMENT] Transaction ID: $transactionId');
        
        await apiClient.markAppointmentAsPaid(
          widget.appointment.id,
          paymentMethod: 'Stripe',
          transactionId: transactionId,
        );
        print('✅ [PAYMENT] Appointment marked as paid successfully');
      } catch (e) {
        print('❌ [PAYMENT] Failed to mark appointment as paid: $e');
        print('❌ [PAYMENT] Error type: ${e.runtimeType}');
        print('❌ [PAYMENT] Stack trace: ${StackTrace.current}');
        rethrow; // Re-throw da korisnik vidi grešku
      }

      print('💳 [PAYMENT] Step 4: Updating UI state...');
      setState(() {
        _paymentCompleted = true;
        _generatedAppointmentCode = widget.appointment.appointmentNumber;
        _generatedAppointmentId = widget.appointment.id;
        _paidAppointment = widget.appointment;
      });
      print('✅ [PAYMENT] UI state updated');

      print('✅ [PAYMENT] Payment process completed successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plaćanje uspješno!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ [PAYMENT] Payment process failed!');
      print('❌ [PAYMENT] Error: $e');
      print('❌ [PAYMENT] Error type: ${e.runtimeType}');
      print('❌ [PAYMENT] Stack trace: ${StackTrace.current}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plaćanje neuspješno: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      print('💳 [PAYMENT] Payment process finished (loading state reset)');
    }
  }

  Future<void> initPaymentSheet(Map<String, dynamic> formData) async {
    print('💳 [PAYMENT SHEET] Initializing payment sheet...');
    try {
      // Provjeri da li je Stripe inicijalizovan
      print('💳 [PAYMENT SHEET] Step 0: Accessing dotenv...');
      String? publishableKey;
      
      // Koristi globalnu varijablu umjesto direktnog pristupa dotenv.env
      // Ovo izbjegava NotInitializedError i FileNotFoundError
      try {
        // Prvo pokušaj koristiti globalnu varijablu iz main.dart
        if (globalStripePublishableKey != null && globalStripePublishableKey!.isNotEmpty) {
          publishableKey = globalStripePublishableKey;
          print('💳 [PAYMENT SHEET] Using global Stripe publishable key from main.dart');
          print('💳 [PAYMENT SHEET] STRIPE_PUBLISHABLE_KEY value: ${publishableKey!.substring(0, 20)}...');
        } else {
          // Fallback na dotenv ako globalna varijabla nije postavljena
          print('⚠️ [PAYMENT SHEET] Global key not found, trying dotenv...');
          
          // Pokušaj pristupiti dotenv samo ako je već inicijalizovan
          // Ne pokušavaj učitati .env fajl ponovo jer to ne radi na Androidu
          if (dotenv.isInitialized) {
            publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
            print('💳 [PAYMENT SHEET] Successfully accessed dotenv.env (already initialized)');
            if (publishableKey != null) {
              print('💳 [PAYMENT SHEET] STRIPE_PUBLISHABLE_KEY value: ${publishableKey.substring(0, 20)}...');
            }
          } else {
            print('❌ [PAYMENT SHEET] dotenv is not initialized and cannot load .env file at runtime');
            print('💡 [PAYMENT SHEET] This usually means .env file was not loaded in main.dart');
            print('💡 [PAYMENT SHEET] Please check that .env file exists and is loaded in main() function');
            throw Exception('STRIPE_PUBLISHABLE_KEY is not available. Global variable is null and dotenv is not initialized.');
          }
        }
      } catch (e) {
        print('❌ [PAYMENT SHEET] Error accessing Stripe keys: $e');
        print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
        
        // Ako je FileNotFoundError, to znači da .env fajl nije dostupan
        if (e.toString().contains('FileNotFoundError') || e.runtimeType.toString().contains('FileNotFound')) {
          print('💡 [PAYMENT SHEET] FileNotFoundError - .env file cannot be loaded at runtime');
          print('💡 [PAYMENT SHEET] Trying to use global variable as fallback...');
          publishableKey = globalStripePublishableKey;
          if (publishableKey == null || publishableKey.isEmpty) {
            throw Exception('STRIPE_PUBLISHABLE_KEY is not available. Please restart the app to load .env file.');
          }
          print('✅ [PAYMENT SHEET] Using global key after FileNotFoundError');
        } 
        // Ako je NotInitializedError, pokušaj koristiti globalnu varijablu
        else if (e.toString().contains('NotInitializedError') || e.runtimeType.toString().contains('NotInitialized')) {
          print('💡 [PAYMENT SHEET] NotInitializedError detected - trying global variable...');
          publishableKey = globalStripePublishableKey;
          if (publishableKey == null || publishableKey.isEmpty) {
            throw Exception('STRIPE_PUBLISHABLE_KEY is not available. Please check your configuration.');
          }
          print('✅ [PAYMENT SHEET] Using global key after NotInitializedError');
        } else {
          throw Exception('Failed to access Stripe keys: $e');
        }
      }
      
      print('💳 [PAYMENT SHEET] Checking Stripe initialization...');
      print('💳 [PAYMENT SHEET] STRIPE_PUBLISHABLE_KEY exists: ${publishableKey != null}');
      print('💳 [PAYMENT SHEET] STRIPE_PUBLISHABLE_KEY length: ${publishableKey?.length ?? 0}');
      
      // Bezbedan pristup Stripe.publishableKey
      String? currentPublishableKey;
      try {
        currentPublishableKey = Stripe.publishableKey;
        print('💳 [PAYMENT SHEET] Successfully accessed Stripe.publishableKey');
      } catch (e) {
        print('❌ [PAYMENT SHEET] Error accessing Stripe.publishableKey: $e');
        print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
        currentPublishableKey = null;
      }
      print('💳 [PAYMENT SHEET] Current Stripe.publishableKey: ${currentPublishableKey ?? 'null'}');
      
      if (publishableKey == null || publishableKey.isEmpty) {
        print('❌ [PAYMENT SHEET] STRIPE_PUBLISHABLE_KEY is not set in .env file');
        throw Exception('STRIPE_PUBLISHABLE_KEY is not configured. Please check your .env file.');
      }
      
      if (currentPublishableKey == null || currentPublishableKey.isEmpty) {
        print('⚠️ [PAYMENT SHEET] Stripe.publishableKey is empty, re-initializing...');
        try {
          Stripe.publishableKey = publishableKey;
          Stripe.merchantIdentifier = 'merchant.com.4paw.veterinary';
          print('💳 [PAYMENT SHEET] Set Stripe.publishableKey and merchantIdentifier');
          await Stripe.instance.applySettings();
          print('✅ [PAYMENT SHEET] Stripe re-initialized successfully');
          final verifyKey = Stripe.publishableKey;
          if (verifyKey != null && verifyKey.isNotEmpty) {
            print('💳 [PAYMENT SHEET] Verifying Stripe.publishableKey after applySettings: ${verifyKey.substring(0, 20)}...');
          } else {
            print('❌ [PAYMENT SHEET] Stripe.publishableKey is still empty after applySettings!');
            throw Exception('Stripe SDK initialization failed - publishableKey is still empty');
          }
        } catch (e) {
          print('❌ [PAYMENT SHEET] Error applying Stripe settings: $e');
          print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
          if (e is NotInitializedError) {
            print('❌ [PAYMENT SHEET] NotInitializedError during applySettings!');
            print('💡 [PAYMENT SHEET] This might be a platform-specific issue. Trying alternative initialization...');
            // Pokušaj ponovo sa eksplicitnim postavljanjem
            Stripe.publishableKey = publishableKey;
            Stripe.merchantIdentifier = 'merchant.com.4paw.veterinary';
            await Future.delayed(const Duration(milliseconds: 100)); // Kratka pauza
            await Stripe.instance.applySettings();
            print('✅ [PAYMENT SHEET] Alternative initialization completed');
          } else {
            throw Exception('Failed to initialize Stripe SDK: $e');
          }
        }
      } else {
        print('✅ [PAYMENT SHEET] Stripe is already initialized');
        if (currentPublishableKey.length > 20) {
          print('💳 [PAYMENT SHEET] Current Stripe.publishableKey: ${currentPublishableKey.substring(0, 20)}...');
        } else {
          print('💳 [PAYMENT SHEET] Current Stripe.publishableKey: $currentPublishableKey');
        }
      }
      
      // Dodatna provjera - provjeri da li je Stripe SDK stvarno spreman
      String? finalCheckKey;
      try {
        finalCheckKey = Stripe.publishableKey;
      } catch (e) {
        print('❌ [PAYMENT SHEET] Error checking Stripe.publishableKey: $e');
        finalCheckKey = null;
      }
      
      if (finalCheckKey == null || finalCheckKey.isEmpty) {
        print('❌ [PAYMENT SHEET] Stripe.publishableKey is still empty after initialization!');
        throw Exception('Stripe SDK is not properly initialized. publishableKey is empty.');
      }
      
      final amountInCents = (widget.amount * 100).round();
      print('💳 [PAYMENT SHEET] Amount in cents: $amountInCents');
      print('💳 [PAYMENT SHEET] Currency: BAM');
      print('💳 [PAYMENT SHEET] Customer name: ${formData['name']}');
      print('💳 [PAYMENT SHEET] Customer email: ${formData['email']}');
      
      print('💳 [PAYMENT SHEET] Step 1: Creating payment intent...');
      final data = await createPaymentIntent(
        amount: amountInCents.toString(),
        currency: 'BAM',
        name: formData['name'],
        address: formData['address'],
        pin: formData['pincode'],
        city: formData['city'],
        state: formData['state'],
        country: formData['country'],
        email: formData['email'] ?? 'customer@example.com',
      );
      print('✅ [PAYMENT SHEET] Payment intent created');
      print('💳 [PAYMENT SHEET] Customer ID: ${data['id']}');
      print('💳 [PAYMENT SHEET] Client secret received: ${data['client_secret']?.substring(0, 20)}...');

      print('💳 [PAYMENT SHEET] Step 2: Initializing Stripe payment sheet...');
      
      // Finalna provjera prije pozivanja initPaymentSheet
      String? finalPublishableKey;
      try {
        finalPublishableKey = Stripe.publishableKey;
        if (finalPublishableKey != null && finalPublishableKey.isNotEmpty) {
          print('💳 [PAYMENT SHEET] Final check - Stripe.publishableKey: ${finalPublishableKey.substring(0, 20)}...');
        } else {
          print('❌ [PAYMENT SHEET] Final check - Stripe.publishableKey is empty!');
          throw Exception('Stripe.publishableKey is empty before initPaymentSheet');
        }
      } catch (e) {
        print('❌ [PAYMENT SHEET] Error accessing Stripe.publishableKey in final check: $e');
        print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
        if (e is NotInitializedError) {
          print('❌ [PAYMENT SHEET] NotInitializedError in final check! Re-initializing...');
          Stripe.publishableKey = publishableKey;
          Stripe.merchantIdentifier = 'merchant.com.4paw.veterinary';
          await Stripe.instance.applySettings();
          print('✅ [PAYMENT SHEET] Re-initialized after NotInitializedError');
        } else {
          rethrow;
        }
      }
      
      print('💳 [PAYMENT SHEET] Client secret: ${data['client_secret']?.substring(0, 20)}...');
      print('💳 [PAYMENT SHEET] Ephemeral key: ${data['ephemeralKey']?.substring(0, 20)}...');
      print('💳 [PAYMENT SHEET] Customer ID: ${data['id']}');
      
      try {
        print('💳 [PAYMENT SHEET] Calling Stripe.instance.initPaymentSheet...');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            customFlow: false,
            merchantDisplayName: '4Paw Veterinary',
            paymentIntentClientSecret: data['client_secret'],
            customerEphemeralKeySecret: data['ephemeralKey'],
            customerId: data['id'],
            style: ThemeMode.system,
          ),
        );
        print('✅ [PAYMENT SHEET] Payment sheet initialized successfully');
      } catch (e) {
        print('❌ [PAYMENT SHEET] Error calling initPaymentSheet: $e');
        print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
        print('❌ [PAYMENT SHEET] Stripe.publishableKey at error time: ${Stripe.publishableKey}');
        if (e is NotInitializedError) {
          print('❌ [PAYMENT SHEET] NotInitializedError detected! Stripe SDK is not initialized.');
          print('💡 [PAYMENT SHEET] Attempting to re-initialize Stripe...');
          Stripe.publishableKey = publishableKey;
          Stripe.merchantIdentifier = 'merchant.com.4paw.veterinary';
          await Stripe.instance.applySettings();
          print('✅ [PAYMENT SHEET] Stripe re-initialized, retrying initPaymentSheet...');
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              customFlow: false,
              merchantDisplayName: '4Paw Veterinary',
              paymentIntentClientSecret: data['client_secret'],
              customerEphemeralKeySecret: data['ephemeralKey'],
              customerId: data['id'],
              style: ThemeMode.system,
            ),
          );
          print('✅ [PAYMENT SHEET] Payment sheet initialized successfully after retry');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('❌ [PAYMENT SHEET] Error initializing payment sheet: $e');
      print('❌ [PAYMENT SHEET] Error type: ${e.runtimeType}');
      print('❌ [PAYMENT SHEET] Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    required String name,
    required String address,
    required String pin,
    required String city,
    required String state,
    required String country,
    required String email,
  }) async {
    print('💳 [STRIPE API] Creating payment intent...');
    print('💳 [STRIPE API] Amount: $amount, Currency: $currency');
    print('💳 [STRIPE API] Customer: $name ($email)');
    
    try {
      // Koristi globalnu varijablu umjesto direktnog pristupa dotenv.env
      String? secretKey = globalStripeSecretKey;
      print('💳 [STRIPE API] Checking secret key...');
      print('💳 [STRIPE API] globalStripeSecretKey is null: ${globalStripeSecretKey == null}');
      print('💳 [STRIPE API] globalStripeSecretKey length: ${globalStripeSecretKey?.length ?? 0}');
      if (globalStripeSecretKey != null) {
        print('💳 [STRIPE API] globalStripeSecretKey starts with: ${globalStripeSecretKey!.substring(0, 7)}');
        print('💳 [STRIPE API] globalStripeSecretKey ends with: ${globalStripeSecretKey!.substring(globalStripeSecretKey!.length - 3)}');
      }
      
      if (secretKey == null || secretKey.isEmpty) {
        // Fallback na dotenv
        print('⚠️ [STRIPE API] Global key not found, trying dotenv...');
        try {
          secretKey = dotenv.env['STRIPE_SECRET_KEY'];
          print('💳 [STRIPE API] dotenv key found: ${secretKey != null}');
          if (secretKey != null) {
            print('💳 [STRIPE API] dotenv key length: ${secretKey.length}');
          }
        } catch (e) {
          print('⚠️ [STRIPE API] Error accessing dotenv for secret key: $e');
        }
      }
      
      // Ako ni globalna ni dotenv nisu dostupni, koristi hardcoded
      if (secretKey == null || secretKey.isEmpty) {
        print('⚠️ [STRIPE API] Both global and dotenv keys are null, using hardcoded fallback...');
        secretKey = 'sk_test_51SNB9BCFslvIasyndmYsoK2xdZJlCh9XqY9zKFbiEnxhTtNdbVEzabMfyasUkwscnW5jM0Y0ZTXyIbWZUWu7XeJ200ngtQnmYO';
        print('✅ [STRIPE API] Using hardcoded secret key');
      }
      
      // Provjeri da li je key ispravan
      if (secretKey == null || secretKey.isEmpty) {
        print('❌ [STRIPE API] STRIPE_SECRET_KEY is still null or empty after all attempts');
        throw Exception('STRIPE_SECRET_KEY not found in environment variables');
      }
      
      // Trim key da uklonimo eventualne razmake
      secretKey = secretKey.trim();
      
      print('✅ [STRIPE API] Stripe secret key found (length: ${secretKey.length})');
      print('💳 [STRIPE API] Secret key starts with: ${secretKey.substring(0, 7)}');
      print('💳 [STRIPE API] Secret key ends with: ${secretKey.substring(secretKey.length - 3)}');
      
      // Provjeri da li je key ispravne dužine (Stripe secret key je obično 107-108 karaktera)
      if (secretKey.length < 100) {
        print('❌ [STRIPE API] WARNING: Secret key seems too short (${secretKey.length} chars). Expected ~107-108 chars.');
      }

      print('💳 [STRIPE API] Step 1: Creating Stripe customer...');
      print('💳 [STRIPE API] Final secret key before API call:');
      print('💳 [STRIPE API]   Length: ${secretKey.length}');
      print('💳 [STRIPE API]   First 20 chars: ${secretKey.substring(0, 20)}');
      print('💳 [STRIPE API]   Last 20 chars: ${secretKey.substring(secretKey.length - 20)}');
      print('💳 [STRIPE API]   Full key (for debugging): $secretKey');
      
      final customerResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
          'email': email,
          'metadata[address]': address,
          'metadata[city]': city,
          'metadata[state]': state,
          'metadata[country]': country,
        },
      );

      print('💳 [STRIPE API] Customer creation response status: ${customerResponse.statusCode}');
      if (customerResponse.statusCode != 200) {
        print('❌ [STRIPE API] Failed to create customer');
        print('❌ [STRIPE API] Response status: ${customerResponse.statusCode}');
        print('❌ [STRIPE API] Response headers: ${customerResponse.headers}');
        print('❌ [STRIPE API] Response body: ${customerResponse.body}');
        
        // Pokušaj parsirati error iz Stripe response
        try {
          final errorData = jsonDecode(customerResponse.body);
          print('❌ [STRIPE API] Parsed customer error: $errorData');
          if (errorData['error'] != null) {
            print('❌ [STRIPE API] Stripe error type: ${errorData['error']['type']}');
            print('❌ [STRIPE API] Stripe error code: ${errorData['error']['code']}');
            print('❌ [STRIPE API] Stripe error message: ${errorData['error']['message']}');
          }
        } catch (parseError) {
          print('❌ [STRIPE API] Could not parse customer error response: $parseError');
        }
        
        throw Exception('Failed to create customer: ${customerResponse.body}');
      }

      final customerData = jsonDecode(customerResponse.body);
      final customerId = customerData['id'];
      print('✅ [STRIPE API] Customer created: $customerId');

      print('💳 [STRIPE API] Step 2: Creating ephemeral key...');
      final ephemeralKeyResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Stripe-Version': '2023-10-16',
        },
        body: {'customer': customerId},
      );

      print('💳 [STRIPE API] Ephemeral key response status: ${ephemeralKeyResponse.statusCode}');
      if (ephemeralKeyResponse.statusCode != 200) {
        print('❌ [STRIPE API] Failed to create ephemeral key');
        print('❌ [STRIPE API] Response status: ${ephemeralKeyResponse.statusCode}');
        print('❌ [STRIPE API] Response headers: ${ephemeralKeyResponse.headers}');
        print('❌ [STRIPE API] Response body: ${ephemeralKeyResponse.body}');
        
        // Pokušaj parsirati error iz Stripe response
        try {
          final errorData = jsonDecode(ephemeralKeyResponse.body);
          print('❌ [STRIPE API] Parsed ephemeral key error: $errorData');
          if (errorData['error'] != null) {
            print('❌ [STRIPE API] Stripe error type: ${errorData['error']['type']}');
            print('❌ [STRIPE API] Stripe error code: ${errorData['error']['code']}');
            print('❌ [STRIPE API] Stripe error message: ${errorData['error']['message']}');
          }
        } catch (parseError) {
          print('❌ [STRIPE API] Could not parse ephemeral key error response: $parseError');
        }
        
        throw Exception('Failed to create ephemeral key: ${ephemeralKeyResponse.body}');
      }

      final ephemeralKeyData = jsonDecode(ephemeralKeyResponse.body);
      print('✅ [STRIPE API] Ephemeral key created');

      print('💳 [STRIPE API] Step 3: Creating payment intent...');
      final serviceName = widget.service?['name'] ?? 'Veterinary Service';
      final paymentIntentBody = {
        'amount': amount,
        'currency': currency.toLowerCase(),
        'customer': customerId,
        'payment_method_types[]': 'card',
        'description': '4Paw Veterinary Appointment Payment for $serviceName',
        'metadata[name]': name,
        'metadata[address]': address,
        'metadata[city]': city,
        'metadata[state]': state,
        'metadata[country]': country,
        'metadata[appointment]': widget.appointment.appointmentNumber,
        'metadata[pet]': widget.appointment.petName ?? 'Unknown',
      };
      print('💳 [STRIPE API] Payment intent body: $paymentIntentBody');

      final paymentIntentResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: paymentIntentBody,
      );

      print('💳 [STRIPE API] Payment intent response status: ${paymentIntentResponse.statusCode}');
      if (paymentIntentResponse.statusCode == 200) {
        final paymentIntentData = jsonDecode(paymentIntentResponse.body);
        print('✅ [STRIPE API] Payment intent created successfully');
        print('💳 [STRIPE API] Payment intent ID: ${paymentIntentData['id']}');
        print('💳 [STRIPE API] Client secret: ${paymentIntentData['client_secret']?.substring(0, 20)}...');
        
        return {
          'client_secret': paymentIntentData['client_secret'],
          'ephemeralKey': ephemeralKeyData['secret'],
          'id': customerId,
          'amount': amount,
          'currency': currency,
        };
      } else {
        print('❌ [STRIPE API] Failed to create payment intent');
        print('❌ [STRIPE API] Response status: ${paymentIntentResponse.statusCode}');
        print('❌ [STRIPE API] Response headers: ${paymentIntentResponse.headers}');
        print('❌ [STRIPE API] Response body: ${paymentIntentResponse.body}');
        
        // Pokušaj parsirati error iz Stripe response
        try {
          final errorData = jsonDecode(paymentIntentResponse.body);
          print('❌ [STRIPE API] Parsed error: $errorData');
          if (errorData['error'] != null) {
            print('❌ [STRIPE API] Stripe error type: ${errorData['error']['type']}');
            print('❌ [STRIPE API] Stripe error code: ${errorData['error']['code']}');
            print('❌ [STRIPE API] Stripe error message: ${errorData['error']['message']}');
          }
        } catch (parseError) {
          print('❌ [STRIPE API] Could not parse error response: $parseError');
        }
        
        throw Exception('Failed to create payment intent: ${paymentIntentResponse.body}');
      }
    } catch (e) {
      print('❌ [STRIPE API] Error creating payment intent: $e');
      print('❌ [STRIPE API] Error type: ${e.runtimeType}');
      print('❌ [STRIPE API] Stack trace: ${StackTrace.current}');
      throw Exception('Error creating payment intent: $e');
    }
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double startX = 0;
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


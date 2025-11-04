import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../../main.dart';

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
    setState(() => _isLoading = true);

    try {
      await initPaymentSheet(formData);
      await Stripe.instance.presentPaymentSheet();

      try {
        final apiClient = serviceLocator.apiClient;
        await apiClient.markAppointmentAsPaid(
          widget.appointment.id,
          paymentMethod: 'Stripe',
          transactionId: 'pi_stripe_${widget.appointment.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (e) {
        print('⚠️ Failed to mark appointment as paid: $e');
      }

      setState(() {
        _paymentCompleted = true;
        _generatedAppointmentCode = widget.appointment.appointmentNumber;
        _generatedAppointmentId = widget.appointment.id;
        _paidAppointment = widget.appointment;
      });

      // Offer rating after successful payment
      await _showRateVeterinarianDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plaćanje uspješno!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plaćanje neuspješno: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRateVeterinarianDialog() async {
    int selectedRating = 5;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Ocijenite veterinara'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filled = index < selectedRating;
                      return IconButton(
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: filled ? const Color(0xFFFFC107) : Colors.grey,
                        ),
                        onPressed: () {
                          setStateDialog(() => selectedRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text('Ocjena: $selectedRating/5'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Kasnije'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final api = serviceLocator.apiClient;
                      await api.createVeterinarianReview(
                        veterinarianId: widget.appointment.veterinarianId,
                        rating: selectedRating,
                        petName: widget.appointment.petName,
                        petSpecies: null,
                        title: widget.service?['name'],
                        comment: 'Ocjena iz mobilne aplikacije',
                      );
                      if (mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hvala na ocjeni!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Greška pri ocjenjivanju: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  child: const Text('Pošalji'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> initPaymentSheet(Map<String, dynamic> formData) async {
    try {
      final data = await createPaymentIntent(
        amount: (widget.amount * 100).round().toString(),
        currency: 'BAM',
        name: formData['name'],
        address: formData['address'],
        pin: formData['pincode'],
        city: formData['city'],
        state: formData['state'],
        country: formData['country'],
        email: formData['email'] ?? 'customer@example.com',
      );

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
    } catch (e) {
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
    try {
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
      if (secretKey == null) {
        throw Exception('STRIPE_SECRET_KEY not found in environment variables');
      }

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

      if (customerResponse.statusCode != 200) {
        throw Exception('Failed to create customer: ${customerResponse.body}');
      }

      final customerData = jsonDecode(customerResponse.body);
      final customerId = customerData['id'];

      final ephemeralKeyResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Stripe-Version': '2023-10-16',
        },
        body: {'customer': customerId},
      );

      if (ephemeralKeyResponse.statusCode != 200) {
        throw Exception('Failed to create ephemeral key: ${ephemeralKeyResponse.body}');
      }

      final ephemeralKeyData = jsonDecode(ephemeralKeyResponse.body);

      final paymentIntentResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'customer': customerId,
          'payment_method_types[]': 'card',
          'description': '4Paw Veterinary Appointment Payment for ${widget.service?['name']}',
          'metadata[name]': name,
          'metadata[address]': address,
          'metadata[city]': city,
          'metadata[state]': state,
          'metadata[country]': country,
          'metadata[appointment]': widget.appointment.appointmentNumber,
          'metadata[pet]': widget.appointment.petName ?? 'Unknown',
        },
      );

      if (paymentIntentResponse.statusCode == 200) {
        final paymentIntentData = jsonDecode(paymentIntentResponse.body);
        return {
          'client_secret': paymentIntentData['client_secret'],
          'ephemeralKey': ephemeralKeyData['secret'],
          'id': customerId,
          'amount': amount,
          'currency': currency,
        };
      } else {
        throw Exception('Failed to create payment intent: ${paymentIntentResponse.body}');
      }
    } catch (e) {
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


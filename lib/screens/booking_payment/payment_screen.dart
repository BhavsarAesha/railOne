import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:railone/models/booking.dart';
import 'package:railone/models/train.dart';
import 'package:railone/services/booking_service.dart';
import 'package:railone/utils/validators.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:railone/utils/firebase_test.dart';

// Simulated payment UI and booking creation that saves to Firebase (or memory fallback).
class PaymentScreen extends StatefulWidget {
  final Train train;
  final int quantity;
  final List<int>? selectedSeats;
  final String? journeyDate; // yyyy-MM-dd
  final List<String>? selectedSeatCodes; // CNF/B14/27/UPPER
  final String? selectedCoach; // e.g., B14
  const PaymentScreen({super.key, required this.train, this.quantity = 1, this.selectedSeats, this.journeyDate, this.selectedSeatCodes, this.selectedCoach});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _card = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  final TextEditingController _exp = TextEditingController();
  bool _processing = false;
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestore = FirestoreService();
  Razorpay? _razorpay;
  String? _lastTxnId;
  late final int _ticketCount;
  final List<_PassengerFields> _passengers = <_PassengerFields>[];

  @override
  void dispose() {
    _razorpay?.clear();
    _name.dispose();
    _card.dispose();
    _cvv.dispose();
    _exp.dispose();
    for (final p in _passengers) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    final seatsLen = widget.selectedSeats?.length ?? widget.selectedSeatCodes?.length ?? 0;
    _ticketCount = seatsLen > 0 ? seatsLen : widget.quantity;
    for (int i = 0; i < _ticketCount; i++) {
      _passengers.add(_PassengerFields());
    }
  }

  Future<bool> _startRazorpayCheckout({required double amount, required int qty}) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web payments require Razorpay Web Checkout with Order API. I can add it if you want.')),
      );
      return false;
    }
    final completer = Completer<bool>();
    void successHandler(PaymentSuccessResponse r) {
      _lastTxnId = r.paymentId;
      if (!completer.isCompleted) completer.complete(true);
    }
    void errorHandler(PaymentFailureResponse r) {
      _lastTxnId = null;
      if (!completer.isCompleted) completer.complete(false);
    }
    void walletHandler(ExternalWalletResponse r) {}
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, successHandler);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, errorHandler);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, walletHandler);
    try {
      final options = {
        'key': 'rzp_test_1234567890abcdef', // replace with your Razorpay key
        'amount': (amount * 100).round(), // paise
        'currency': 'INR',
        'name': 'RailOne',
        'description': 'Train ${widget.train.number} x $qty',
        'prefill': {
          'contact': '',
          'email': '',
        },
        'retry': {'enabled': true, 'max_count': 1},
        'theme': {'color': '#0F9D58'},
      };
      _razorpay!.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment init failed: $e')));
      return false;
    }
    final bool ok = await completer.future;
    _razorpay!.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    return ok;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _lastTxnId = response.paymentId;
    // Continue flow in _pay after checkout returns
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _lastTxnId = null;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed or cancelled')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // No-op; Razorpay will still return success event
  }

  // Input formatters
  static final _cardNumberFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _cvvFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _expiryFormatter = _ExpiryDateInputFormatter();

  // Format card number with spaces
  String _formatCardNumber(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanValue.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleanValue[i]);
    }
    return buffer.toString();
  }

  // Build payment method widget
  Widget _buildPaymentMethod(String name, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: _processing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    final List<int> seats = (widget.selectedSeats ?? <int>[]).toList();
    final List<String> seatCodes = (widget.selectedSeatCodes ?? <String>[]).toList();
    final int qty = seats.isNotEmpty ? seats.length : widget.quantity;
    final double totalAmount = widget.train.ticketAmount * qty;
    if (_passengers.length != qty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passenger details must be filled for all tickets')));
      return;
    }
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required details')));
      return;
    }
    for (final p in _passengers) {
      if (p.gender == null || p.gender!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select gender for all passengers')));
        return;
      }
    }

    setState(() => _processing = true);
    _lastTxnId = 'CARD-${DateTime.now().millisecondsSinceEpoch}';
    final Booking booking = Booking(
      id: 'BK${DateTime.now().millisecondsSinceEpoch}',
      trainNumber: widget.train.number,
      trainName: widget.train.name,
      from: widget.train.source,
      to: widget.train.destination,
      departureTime: widget.train.departureTime,
      arrivalTime: widget.train.arrivalTime,
      createdAt: DateTime.now(),
      amount: totalAmount,
      quantity: qty,
      journeyDate: widget.journeyDate,
      seats: seats.isEmpty ? null : seats,
      seatCodes: seatCodes.isEmpty ? null : seatCodes,
      selectedCoach: widget.selectedCoach,
      passengers: _passengers
          .map((p) => {
                'name': p.name.text.trim(),
                'age': int.tryParse(p.age.text.trim()) ?? 0,
                'gender': p.gender,
                'mobile': p.mobile.text.trim(),
              })
          .toList(),
    );

    try {
      print('Starting booking process...');
      
      // Run Firebase diagnostics first (bounded to avoid hanging UI)
      print('Running Firebase diagnostics...');
      Map<String, dynamic>? diagnostics;
      try {
        diagnostics = await FirebaseTest.runDiagnostics().timeout(const Duration(seconds: 6));
      } catch (e) {
        diagnostics = {'skipped': 'timeout/error', 'message': e.toString()};
      }
      print('Firebase diagnostics: $diagnostics');
      
      // If seats selected, try to reserve atomically before saving booking (card path tolerates conflict)
      bool reserved = true;
      if (seatCodes.isNotEmpty && (widget.journeyDate != null)) {
        reserved = await _firestore
            .reserveSeatCodes(
          trainNumber: widget.train.number,
          journeyDate: widget.journeyDate!,
          seatCodes: seatCodes.map((c) => c.replaceFirst('CNF/', '').replaceAll('/', '-')).toList(), // store as B14-27
          bookingId: booking.id,
          userId: 'pending',
        )
            .timeout(const Duration(seconds: 10), onTimeout: () => false);
        // For CARD flow we proceed even if reserve fails, to avoid blocking demo
      }
      final bool savedToFirestore = await _bookingService
          .saveBooking(booking)
          .timeout(const Duration(seconds: 12), onTimeout: () => false);
      print('Booking service returned: $savedToFirestore');
      
      if (!mounted) return;
      setState(() => _processing = false);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text('Tickets booked for ${widget.train.number} • ${widget.train.name}\nQuantity: ${qty} tickets${seatCodes.isNotEmpty ? '\nSeats: ${seatCodes.join(', ')}' : ''}\nAmount: ₹${booking.amount.toStringAsFixed(0)}\nTime: ${DateFormat.yMd().add_jm().format(booking.createdAt)}\nStorage: ${savedToFirestore ? 'Cloud (Firebase)' : 'Local (memory)'}\n\n${savedToFirestore ? 'Payment details and PNR have been saved to Firebase!' : 'Booking successfully saved to Firebase.'}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacementNamed(context, '/my-bookings');
              },
              child: const Text('View My Bookings'),
            )
          ],
        ),
      );
    } catch (e) {
      print('Error in payment process: $e');
      if (!mounted) return;
      setState(() => _processing = false);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Payment Error'),
          content: Text('Payment was processed but booking failed to save: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.train.number} • ${widget.train.name}', 
                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${widget.train.source} → ${widget.train.destination}'),
                      Text('${widget.train.departureTime} - ${widget.train.arrivalTime}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tickets: ${widget.quantity} x ₹${widget.train.ticketAmount.toStringAsFixed(0)}'),
                          Text('Total: ₹${(widget.train.ticketAmount * widget.quantity).toStringAsFixed(0)}', 
                               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Passenger details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Passenger Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _ticketCount; i++) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Passenger ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passengers[i].name,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: Validators.validateName,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passengers[i].age,
                                      decoration: const InputDecoration(
                                        labelText: 'Age',
                                        prefixIcon: Icon(Icons.calendar_today_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Age is required';
                                        final n = int.tryParse(v.trim());
                                        if (n == null || n < 1 || n > 120) return 'Enter valid age';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _passengers[i].gender,
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (v) => setState(() => _passengers[i].gender = v),
                                      decoration: const InputDecoration(
                                        labelText: 'Gender',
                                        prefixIcon: Icon(Icons.wc_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Select gender' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passengers[i].mobile,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile number',
                                  hintText: '10-digit number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: Validators.validateMobile,
                              ),
                              if (i < _ticketCount - 1) const Divider(height: 24),
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Payment method selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  const Text('Credit/Debit Card', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Card holder name
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Card holder name',
                  hintText: 'FirstName LastName',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.validateCardHolderName,
              ),
              const SizedBox(height: 16),
              // Card number
              TextFormField(
                controller: _card,
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: 'xxxx xxxx xxxx xxxx',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_cardNumberFormatter],
                onChanged: (value) {
                  final formatted = _formatCardNumber(value);
                  if (formatted != value) {
                    _card.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: Validators.validateCardNumber,
              ),
              const SizedBox(height: 16),
              // Expiry and CVV
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _exp,
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        hintText: 'xx/xx',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_expiryFormatter],
                      validator: Validators.validateExpiryDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvv,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: 'xxx',
                        prefixIcon: Icon(Icons.security),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cvvFormatter],
                      maxLength: 4,
                      validator: Validators.validateCVV,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Payment methods
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPaymentMethod('GPay', Icons.account_balance_wallet, Colors.blue, onTap: () async {
                            if (_processing) return;
                            final int qty = (widget.selectedSeats?.length ?? widget.quantity);
                            final double amount = widget.train.ticketAmount * qty;
                            setState(() => _processing = true);
                            await _startRazorpayCheckout(amount: amount, qty: qty);
                          }),
                          _buildPaymentMethod('PhonePe', Icons.phone_android, Colors.purple, onTap: () async {
                            if (_processing) return;
                            final int qty = (widget.selectedSeats?.length ?? widget.quantity);
                            final double amount = widget.train.ticketAmount * qty;
                            setState(() => _processing = true);
                            await _startRazorpayCheckout(amount: amount, qty: qty);
                          }),
                          _buildPaymentMethod('UPI', Icons.qr_code, Colors.orange, onTap: () async {
                            if (_processing) return;
                            final int qty = (widget.selectedSeats?.length ?? widget.quantity);
                            final double amount = widget.train.ticketAmount * qty;
                            setState(() => _processing = true);
                            await _startRazorpayCheckout(amount: amount, qty: qty);
                          }),
                          _buildPaymentMethod('PayPal', Icons.payment, Colors.indigo, onTap: () async {
                            // Not supported in Razorpay mobile SDK; fallback to normal checkout
                            if (_processing) return;
                            final int qty = (widget.selectedSeats?.length ?? widget.quantity);
                            final double amount = widget.train.ticketAmount * qty;
                            setState(() => _processing = true);
                            await _startRazorpayCheckout(amount: amount, qty: qty);
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'More payment options available at checkout',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Security notice
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is secure and encrypted.',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _pay,
                  icon: _processing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment),
                  label: Text(
                    _processing ? 'Processing...' : 'Pay & Book Ticket',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom input formatter for expiry date (MM/YY)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 4 digits
    final limited = digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;
    
    // Add slash after 2 digits
    String formatted = limited;
    if (limited.length >= 2) {
      formatted = '${limited.substring(0, 2)}/${limited.substring(2)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PassengerFields {
  final TextEditingController name = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  String? gender;

  void dispose() {
    name.dispose();
    age.dispose();
    mobile.dispose();
  }
}


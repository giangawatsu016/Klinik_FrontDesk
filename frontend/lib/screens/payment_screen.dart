import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/insurance_providers.dart';

class PaymentScreen extends StatefulWidget {
  final Patient patient;
  final ApiService apiService;

  const PaymentScreen({
    super.key,
    required this.patient,
    required this.apiService,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Cash'; // Cash, BPJS, Insurance
  final _formKey = GlobalKey<FormState>();

  // Method Details
  final TextEditingController _insuranceNameCtrl = TextEditingController();
  final TextEditingController _insuranceNumberCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController(
    text: "150000",
  ); // Default Fee
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if patient has insurance
    if (widget.patient.issuerId == 2) {
      _selectedMethod = 'BPJS';
      _insuranceNameCtrl.text = 'BPJS Kesehatan';
      _insuranceNumberCtrl.text = widget.patient.noAssuransi ?? '';
    } else if (widget.patient.issuerId == 3) {
      _selectedMethod = 'Insurance';
      _insuranceNameCtrl.text = widget.patient.insuranceName ?? '';
      _insuranceNumberCtrl.text = widget.patient.noAssuransi ?? '';
    }
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final payment = Payment(
        patientId: widget.patient.id!,
        amount:
            int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0,
        method: _selectedMethod,
        insuranceName: _selectedMethod == 'Cash'
            ? null
            : _insuranceNameCtrl.text,
        insuranceNumber: _selectedMethod == 'Cash'
            ? null
            : _insuranceNumberCtrl.text,
        notes: _notesCtrl.text,
      );

      try {
        await widget.apiService.processPayment(payment);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close Screen
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Process Payment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient Summary
              _buildPatientSummary(),
              SizedBox(height: 24),

              // 2. Payment Method
              Text(
                "Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: ['Cash', 'BPJS', 'Insurance', 'Debit', 'Credit Card']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMethod = val!;
                    // Auto-fill logic could go here if switching back and forth
                  });
                },
              ),
              SizedBox(height: 24),

              // 3. Conditional Fields
              if (_selectedMethod == 'BPJS' || _selectedMethod == 'Insurance')
                _buildInsuranceFields(),

              SizedBox(height: 24),

              // 4. Amount
              Text(
                "Total Amount",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              SizedBox(height: 24),

              Text(
                "Notes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "Optional transaction notes...",
                ),
              ),

              SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "CONFIRM PAYMENT",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildPatientSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(
              widget.patient.firstName[0],
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.patient.firstName} ${widget.patient.lastName}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              Text(
                "ID: ${widget.patient.identityCard}",
                style: TextStyle(color: Colors.teal.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Insurance Details",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        if (_selectedMethod == 'Insurance')
          DropdownButtonFormField<String>(
            initialValue:
                _insuranceNameCtrl.text.isNotEmpty &&
                    InsuranceProviders.all.contains(_insuranceNameCtrl.text)
                ? _insuranceNameCtrl.text
                : null,
            decoration: InputDecoration(
              labelText: "Insurance Provider",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: InsuranceProviders.all
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => _insuranceNameCtrl.text = v!,
            validator: (v) => v == null ? "Required for Insurance" : null,
          )
        else
          TextFormField(
            controller: _insuranceNameCtrl,
            decoration: InputDecoration(
              labelText: "BPJS Type / Other Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
        SizedBox(height: 16),
        TextFormField(
          controller: _insuranceNumberCtrl,
          decoration: InputDecoration(
            labelText: "Card / Policy Number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v!.isEmpty ? "Required for Insurance" : null,
        ),
      ],
    );
  }
}

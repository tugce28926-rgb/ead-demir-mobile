import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';

// Web'deki /bank/:bankName/fon-al-sat ekranının mobil karşılığı — sadece
// KUVEYT/VAKIF banka çiftlerinde çalışır (bkz. bankSupportsFonAlSat).
// Masaüstü çok satırlı toplu giriş yapıyor, mobilde tek seferde tek işlem girilir.
bool bankSupportsFonAlSat(String bankName) {
  final n = bankName.toUpperCase();
  return n.contains('KUVEYT') || n.contains('VAKIF');
}

class FonAlSatScreen extends StatefulWidget {
  final BankAccount bank;

  const FonAlSatScreen({super.key, required this.bank});

  @override
  State<FonAlSatScreen> createState() => _FonAlSatScreenState();
}

class _FonAlSatScreenState extends State<FonAlSatScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descController = TextEditingController();
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy');

  String _direction = 'alis';
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli bir tutar girin.')));
      return;
    }
    final fee = double.tryParse(_feeController.text.replaceAll(',', '.')) ?? 0;

    setState(() => _isSubmitting = true);
    try {
      final warning = await _apiService.createFonAlSat(
        bankName: widget.bank.bankName,
        direction: _direction,
        amount: amount,
        feeAmount: fee,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        date: _date,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: warning != null ? AppTheme.primaryAmber : AppTheme.primaryEmerald,
          content: Text(warning != null ? 'Kayıt Zirve\'ye işlendi ama: $warning' : 'Fon işlemi başarıyla kaydedildi.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $e')),
      );
    }
  }

  Widget _buildYonSecici() {
    Widget pill(String label, String value) {
      final selected = _direction == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _direction = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryBlue : AppTheme.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppTheme.slate600),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [pill('Alış', 'alis'), const SizedBox(width: 8), pill('Satış', 'satis')],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Text('Fon Alış / Satış — ${widget.bank.bankName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('İşlem Yönü', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
            const SizedBox(height: 8),
            _buildYonSecici(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tutar (₺)'),
              validator: (v) => (v == null || double.tryParse(v.trim().replaceAll(',', '.')) == null) ? 'Geçersiz tutar' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Masraf (₺) — isteğe bağlı'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Açıklama — isteğe bağlı'),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppTheme.slate300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                alignment: Alignment.centerLeft,
              ),
              child: Text('Tarih: ${_dateFmt.format(_date)}', style: const TextStyle(fontSize: 12, color: AppTheme.slate700)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

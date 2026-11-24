import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SalesmenScreen extends StatefulWidget {
  const SalesmenScreen({super.key});

  @override
  State<SalesmenScreen> createState() => _SalesmenScreenState();
}

class _SalesmenScreenState extends State<SalesmenScreen> {
  String _selectedBrand = 'Dettol';
  final _newSalesmanCtrl = TextEditingController();
  final _editSalesmanCtrl = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _salesmen = [];

  String? _editingId;
  String? _confirmDeleteId;

  final List<String> _brands = ['Dettol', 'Dabur', 'Diaper', 'Wholesale'];

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  Future<void> _loadSalesmen() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getSalesmen(productId: _selectedBrand);
      if (mounted) {
        setState(() => _salesmen = list);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSalesman() async {
    final name = _newSalesmanCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter sales man name')),
      );
      return;
    }

    final res = await ApiService.addSalesman(name, _selectedBrand);
    if (res != null) {
      _newSalesmanCtrl.clear();
      _loadSalesmen();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sales man added to $_selectedBrand')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add sales man')),
      );
    }
  }

  Future<void> _saveEditedSalesman(String id) async {
    final name = _editSalesmanCtrl.text.trim();
    if (name.isEmpty) return;

    final updated = await ApiService.updateSalesman(id, name: name);
    if (updated) {
      setState(() => _editingId = null);
      _loadSalesmen();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales man updated')),
      );
    }
  }

  Future<void> _deleteSalesman(String id) async {
    final deleted = await ApiService.deleteSalesman(id);
    if (deleted) {
      setState(() => _confirmDeleteId = null);
      _loadSalesmen();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales man deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(),
                  const SizedBox(height: 14),
                  _buildAddSalesmanCard(),
                  const SizedBox(height: 18),
                  Text(
                    '$_selectedBrand sales man',
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _buildSalesmenListCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 23, 58, 0.18),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sales man',
                  style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Add and manage salesmen for each brand',
                  style: GoogleFonts.mukta(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSalesmanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 23, 58, 0.07),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product', style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mut)),
          Wrap(
            spacing: 16,
            children: _brands.map((b) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: b,
                    groupValue: _selectedBrand,
                    activeColor: AppColors.pri,
                    onChanged: (val) {
                      setState(() => _selectedBrand = val!);
                      _loadSalesmen();
                    },
                  ),
                  Text(b, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('New $_selectedBrand sales man name', style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mut)),
          const SizedBox(height: 4),
          TextField(
            controller: _newSalesmanCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Ramesh',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _addSalesman,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Add sales man to $_selectedBrand',
                    style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesmenListCard() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_salesmen.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(20, 23, 58, 0.07),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          '$_selectedBrand me abhi koi sales man nahi hai.',
          style: GoogleFonts.mukta(color: AppColors.mut, fontSize: 14),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 23, 58, 0.07),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: _salesmen.map((sm) {
          final id = sm['id']?.toString() ?? '';
          final name = sm['name'] ?? '';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

          if (_editingId == id) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit sales man name', style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(controller: _editSalesmanCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(onPressed: () => setState(() => _editingId = null), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _saveEditedSalesman(id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.pri),
                        child: const Text('Save name', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Text(initial, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.pri)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text(_selectedBrand, style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _editingId = id;
                          _editSalesmanCtrl.text = name;
                        });
                      },
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    if (_confirmDeleteId == id) ...[
                      ElevatedButton(
                        onPressed: () => _deleteSalesman(id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.bad),
                        child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () => setState(() => _confirmDeleteId = id),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
                        child: const Text('Delete'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


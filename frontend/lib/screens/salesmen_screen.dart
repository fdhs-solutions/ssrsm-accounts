import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

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

  static const List<String> _brands = ['Dettol', 'Dabur', 'Diaper', 'Wholesale'];

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  @override
  void dispose() {
    _newSalesmanCtrl.dispose();
    _editSalesmanCtrl.dispose();
    super.dispose();
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
      showAppSnackBar(context, 'Enter sales man name', isError: true);
      return;
    }

    final (ok, errorMsg) = await ApiService.addSalesman(name, _selectedBrand);
    if (!mounted) return;

    if (ok) {
      _newSalesmanCtrl.clear();
      _loadSalesmen();
      showAppSnackBar(context, 'Sales man added to $_selectedBrand');
    } else {
      showAppSnackBar(context, errorMsg ?? 'Failed to add sales man', isError: true);
    }
  }

  Future<void> _saveEditedSalesman(String id) async {
    final name = _editSalesmanCtrl.text.trim();
    if (name.isEmpty) return;

    final updated = await ApiService.updateSalesman(id, name: name);
    if (!mounted) return;

    if (updated) {
      setState(() => _editingId = null);
      _loadSalesmen();
      showAppSnackBar(context, 'Sales man updated');
    }
  }

  Future<void> _deleteSalesman(String id) async {
    final deleted = await ApiService.deleteSalesman(id);
    if (!mounted) return;

    if (deleted) {
      setState(() => _confirmDeleteId = null);
      _loadSalesmen();
      showAppSnackBar(context, 'Sales man deleted');
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
                  const AppHeaderBanner(
                    title: 'Sales man',
                    subtitle: 'Add and manage salesmen for each brand',
                    icon: Icons.people,
                    gradientColors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
                  ),
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

  Widget _buildAddSalesmanCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel('Product'),
          ProductRadioSelector(
            options: _brands,
            selectedValue: _selectedBrand,
            onChanged: (val) {
              setState(() => _selectedBrand = val);
              _loadSalesmen();
            },
          ),
          const SizedBox(height: 12),
          AppFieldLabel('New $_selectedBrand sales man name'),
          const SizedBox(height: 4),
          TextField(
            controller: _newSalesmanCtrl,
            decoration: appInputDecoration(hintText: 'e.g. Ramesh'),
          ),
          const SizedBox(height: 16),
          AppGradientButton(
            label: 'Add sales man to $_selectedBrand',
            onPressed: _addSalesman,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesmenListCard() {
    if (_isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
      );
    }

    if (_salesmen.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          '$_selectedBrand me abhi koi sales man nahi hai.',
          style: GoogleFonts.mukta(color: AppColors.mut, fontSize: 14),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _salesmen.map((sm) {
          final id = sm['id']?.toString() ?? '';
          final name = sm['name'] ?? '';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

          if (_editingId == id) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit sales man name',
                    style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  TextField(controller: _editSalesmanCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _editingId = null),
                        child: const Text('Cancel'),
                      ),
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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pri,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          _selectedBrand,
                          style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut),
                        ),
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
                    if (_confirmDeleteId == id)
                      ElevatedButton(
                        onPressed: () => _deleteSalesman(id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.bad),
                        child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => setState(() => _confirmDeleteId = id),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
                        child: const Text('Delete'),
                      ),
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

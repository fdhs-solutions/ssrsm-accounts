import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';

class StockEntryScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const StockEntryScreen({super.key, required this.onSaved});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  String _selectedProduct = 'Dettol';
  DateTime _entryDate = DateTime.now();

  final _openingStockCtrl = TextEditingController();
  final _dailySalesCtrl = TextEditingController();
  final _stockReceivedCtrl = TextEditingController();
  final _newStockCtrl = TextEditingController();
  final _closingStockCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final Map<String, bool> _activeModes = {
    'Cash': false,
    'Cheque': false,
    'RTGS': false,
    'Auto': false,
    'Credit': false,
  };

  final Map<String, TextEditingController> _modeControllers = {
    'Cash': TextEditingController(),
    'Cheque': TextEditingController(),
    'RTGS': TextEditingController(),
    'Auto': TextEditingController(),
    'Credit': TextEditingController(),
  };

  List<dynamic> _salesmen = [];
  String? _selectedSalesmanId;
  bool _isLoading = false;

  static const List<String> _products = ['Dettol', 'Dabur', 'Diaper', 'Wholesale'];
  static const List<String> _modes = ['Cash', 'Cheque', 'RTGS', 'Auto', 'Credit'];

  @override
  void initState() {
    super.initState();
    _loadSalesmenAndOpeningStock();
  }

  @override
  void dispose() {
    _openingStockCtrl.dispose();
    _dailySalesCtrl.dispose();
    _stockReceivedCtrl.dispose();
    _newStockCtrl.dispose();
    _closingStockCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _modeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSalesmenAndOpeningStock() async {
    try {
      final list = await ApiService.getSalesmen(productId: _selectedProduct);
      final info = await ApiService.getOpeningStockInfo(
        productId: _selectedProduct,
        date: dateISO(_entryDate),
      );
      if (mounted) {
        setState(() {
          _salesmen = list;
          _selectedSalesmanId = null;

          final sameDay = info['sameDayEntry'];
          if (sameDay != null) {
            _openingStockCtrl.text = formatNum(sameDay['openingStock'] ?? 0);
            _newStockCtrl.text = formatNum(sameDay['newStock'] ?? 0);
            _dailySalesCtrl.text = formatNum(sameDay['dailySales'] ?? 0);
            _stockReceivedCtrl.text = formatNum(sameDay['stockReceived'] ?? 0);
          } else {
            final opening = info['openingStock'] as double? ?? 0.0;
            _openingStockCtrl.text = opening > 0
                ? (opening % 1 == 0 ? opening.toInt().toString() : opening.toString())
                : '';
          }
          _recalculateClosing();
        });
      }
    } catch (_) {}
  }

  double _parseCleanNum(String text) {
    final clean = text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _recalculateClosing() {
    final double open = _parseCleanNum(_openingStockCtrl.text);
    final double nw = _parseCleanNum(_newStockCtrl.text);
    final double sales = _parseCleanNum(_dailySalesCtrl.text);
    final double received = _parseCleanNum(_stockReceivedCtrl.text);

    final double closing = open + nw - sales + received;
    final formattedClosing =
        closing % 1 == 0 ? closing.toInt().toString() : closing.toStringAsFixed(2);
    _closingStockCtrl.text = formatIndianNumber(formattedClosing);
  }

  Future<void> _saveEntry() async {
    final double open = _parseCleanNum(_openingStockCtrl.text);
    final double nw = _parseCleanNum(_newStockCtrl.text);
    final double sales = _parseCleanNum(_dailySalesCtrl.text);
    final double received = _parseCleanNum(_stockReceivedCtrl.text);

    if (sales > (open + nw + received)) {
      showAppSnackBar(context, 'Daily sales cannot exceed available stock', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'entryDate': dateISO(_entryDate),
      'productId': _selectedProduct,
      'salesmanId': _selectedSalesmanId,
      'openingStock': open,
      'newStock': nw,
      'dailySales': sales,
      'stockReceived': received,
      'cashAmount': _parseCleanNum(_modeControllers['Cash']!.text),
      'chequeAmount': _parseCleanNum(_modeControllers['Cheque']!.text),
      'rtgsAmount': _parseCleanNum(_modeControllers['RTGS']!.text),
      'autoAmount': _parseCleanNum(_modeControllers['Auto']!.text),
      'creditAmount': _parseCleanNum(_modeControllers['Credit']!.text),
      'note': _noteCtrl.text.trim(),
    };

    final res = await ApiService.createEntry(payload);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res != null) {
      showAppSnackBar(context, 'Stock entry saved successfully!');
      _dailySalesCtrl.clear();
      _stockReceivedCtrl.clear();
      _newStockCtrl.clear();
      _noteCtrl.clear();
      _modeControllers.forEach((_, c) => c.clear());
      _recalculateClosing();
      widget.onSaved();
    } else {
      showAppSnackBar(context, 'Failed to save entry. Check values.', isError: true);
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
                    title: 'New stock entry',
                    subtitle: 'Add daily sales, stock received & collections',
                    icon: Icons.add_shopping_cart,
                    gradientColors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Product'),
                        ProductRadioSelector(
                          options: _products,
                          selectedValue: _selectedProduct,
                          onChanged: (val) {
                            setState(() => _selectedProduct = val);
                            _loadSalesmenAndOpeningStock();
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLabel('Date'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _entryDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _entryDate = picked);
                              _loadSalesmenAndOpeningStock();
                            }
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateLabel(_entryDate),
                                  style: GoogleFonts.mukta(fontSize: 15, color: AppColors.ink),
                                ),
                                const Icon(Icons.calendar_today, size: 18, color: AppColors.mut),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildInput('Opening Stock', _openingStockCtrl, 'Auto: previous closing stock', isNumber: true),
                        _buildInput('Daily Sales', _dailySalesCtrl, 'Enter sales quantity', isNumber: true),
                        _buildInput('Stock Received', _stockReceivedCtrl, 'Enter stock received', isNumber: true),
                        _buildInput('New Stock', _newStockCtrl, 'Enter new arrival stock', isNumber: true),
                        _buildInput('Total Closing Stock (automatic)', _closingStockCtrl, 'Calculated closing stock', readOnly: true),
                        const SizedBox(height: 18),
                        Text(
                          'Collection',
                          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Tick one or more modes, then enter the amount for each.',
                          style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          children: _modes.map((m) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _activeModes[m],
                                  activeColor: AppColors.pri,
                                  onChanged: (val) {
                                    setState(() => _activeModes[m] = val ?? false);
                                  },
                                ),
                                Text(
                                  m,
                                  style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        ..._modes.where((m) => _activeModes[m] == true).map((m) {
                          return _buildInput('$m amount', _modeControllers[m]!, '₹ $m amount', isNumber: true);
                        }),
                        const SizedBox(height: 14),
                        _buildLabel('Sales man'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSalesmanId,
                              hint: Text('Select sales man', style: GoogleFonts.mukta(color: AppColors.mut)),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('None / Unassigned'),
                                ),
                                ..._salesmen.map((sm) {
                                  return DropdownMenuItem<String>(
                                    value: sm['id']?.toString(),
                                    child: Text(sm['name'] ?? ''),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedSalesmanId = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Note (optional)'),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          decoration: appInputDecoration(
                            hintText: 'Enter notes here...',
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 22),
                        AppGradientButton(
                          label: 'Save entry',
                          height: 52,
                          isLoading: _isLoading,
                          onPressed: _saveEntry,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppFieldLabel(text),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isNumber ? [IndianNumberTextInputFormatter()] : null,
            onChanged: (_) => _recalculateClosing(),
            decoration: appInputDecoration(hintText: hint).copyWith(
              fillColor: readOnly ? AppColors.tint : AppColors.card,
            ),
          ),
        ],
      ),
    );
  }
}

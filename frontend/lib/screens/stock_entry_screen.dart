import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

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

  final List<String> _products = ['Dettol', 'Dabur', 'Diaper', 'Wholesale'];
  final List<String> _modes = ['Cash', 'Cheque', 'RTGS', 'Auto', 'Credit'];

  @override
  void initState() {
    super.initState();
    _loadSalesmenAndOpeningStock();
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
            // Same date entry exists: Auto-fill stock figures
            final open = sameDay['openingStock'] ?? 0;
            final nw = sameDay['newStock'] ?? 0;
            final sales = sameDay['dailySales'] ?? 0;
            final received = sameDay['stockReceived'] ?? 0;

            _openingStockCtrl.text = formatNum(open);
            _newStockCtrl.text = formatNum(nw);
            _dailySalesCtrl.text = formatNum(sales);
            _stockReceivedCtrl.text = formatNum(received);
          } else {
            // First entry for this date: Get previous day's closing stock or 0
            final opening = info['openingStock'] as double? ?? 0.0;
            _openingStockCtrl.text = opening > 0 ? (opening % 1 == 0 ? opening.toInt().toString() : opening.toString()) : '';
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

    // Formula: Closing = Opening + New - Daily Sales + Stock Received
    final double closing = open + nw - sales + received;
    final formattedClosing = closing % 1 == 0 ? closing.toInt().toString() : closing.toStringAsFixed(2);
    _closingStockCtrl.text = formatIndianNumber(formattedClosing);
  }

  Future<void> _saveEntry() async {
    final double open = _parseCleanNum(_openingStockCtrl.text);
    final double nw = _parseCleanNum(_newStockCtrl.text);
    final double sales = _parseCleanNum(_dailySalesCtrl.text);
    final double received = _parseCleanNum(_stockReceivedCtrl.text);

    if (sales > (open + nw + received)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily sales cannot exceed available stock')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock entry saved successfully!')),
      );
      // Clear form
      _dailySalesCtrl.clear();
      _stockReceivedCtrl.clear();
      _newStockCtrl.clear();
      _noteCtrl.clear();
      _modeControllers.forEach((_, c) => c.clear());
      _recalculateClosing();
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry. Check values.')),
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
                  Container(
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
                        _buildLabel('Product'),
                        Wrap(
                          spacing: 16,
                          children: _products.map((p) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: p,
                                  groupValue: _selectedProduct,
                                  activeColor: AppColors.pri,
                                  onChanged: (val) {
                                    setState(() => _selectedProduct = val!);
                                    _loadSalesmenAndOpeningStock();
                                  },
                                ),
                                Text(
                                  p,
                                  style: GoogleFonts.mukta(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
                          decoration: InputDecoration(
                            hintText: 'Enter notes here...',
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEntry,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color.fromRGBO(79, 70, 229, 0.35),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppColors.buttonGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Save entry',
                                        style: GoogleFonts.mukta(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
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

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
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
            child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New stock entry',
                  style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Add daily sales, stock received & collections',
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mut),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, String hint, {bool isNumber = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: isNumber
                ? [IndianNumberTextInputFormatter()]
                : null,
            onChanged: (_) => _recalculateClosing(),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: readOnly ? AppColors.tint : AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

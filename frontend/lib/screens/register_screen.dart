import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedFilter = 'Today';
  String _selectedBrand = 'Dettol';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = true;
  List<dynamic> _entries = [];

  // Edit / Delete State
  String? _editingId;
  String? _confirmDeleteId;
  DateTime? _searchByDate;

  final _editSalesCtrl = TextEditingController();
  final _editStockReceivedCtrl = TextEditingController();
  final _editNewStockCtrl = TextEditingController();
  final _editCashCtrl = TextEditingController();
  final _editChequeCtrl = TextEditingController();
  final _editRtgsCtrl = TextEditingController();
  final _editAutoCtrl = TextEditingController();
  final _editCreditCtrl = TextEditingController();
  final _editNoteCtrl = TextEditingController();

  final List<String> _filters = ['Today', 'Week', 'Month', 'Year', 'Custom'];
  final List<String> _brands = ['Dettol', 'Dabur', 'Diaper'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    String? startDate;
    String? endDate;

    if (_selectedFilter == 'Today') {
      startDate = todayISO();
      endDate = todayISO();
    } else if (_selectedFilter == 'Week') {
      final range = thisWeekRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedFilter == 'Month') {
      final range = thisMonthRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedFilter == 'Year') {
      final range = thisYearRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedFilter == 'Custom') {
      if (_customStartDate != null) startDate = dateISO(_customStartDate!);
      if (_customEndDate != null) endDate = dateISO(_customEndDate!);
    }

    try {
      final list = await ApiService.getEntries(
        productId: _selectedBrand,
        startDate: startDate,
        endDate: endDate,
      );
      if (mounted) {
        setState(() => _entries = list);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getRegisterDateSubtitle() {
    if (_selectedFilter == 'Today') {
      return 'Date: ${dateLabel(DateTime.now())}';
    } else if (_selectedFilter == 'Week') {
      final range = thisWeekRange();
      return 'Week: ${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedFilter == 'Month') {
      final range = thisMonthRange();
      return 'Month: ${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedFilter == 'Year') {
      final range = thisYearRange();
      return 'Year: ${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedFilter == 'Custom') {
      final s = _customStartDate != null ? dateLabel(_customStartDate!) : '...';
      final e = _customEndDate != null ? dateLabel(_customEndDate!) : '...';
      return 'Date: $s - $e';
    }
    return '';
  }

  void _startEditing(dynamic row) {
    setState(() {
      _editingId = row['id'];
      _confirmDeleteId = null;
      _editSalesCtrl.text = formatNum(row['daily_sales']);
      _editStockReceivedCtrl.text = formatNum(row['stock_received']);
      _editNewStockCtrl.text = formatNum(row['new_stock']);
      _editCashCtrl.text = formatNum(row['cash_amount']);
      _editChequeCtrl.text = formatNum(row['cheque_amount']);
      _editRtgsCtrl.text = formatNum(row['rtgs_amount']);
      _editAutoCtrl.text = formatNum(row['auto_amount']);
      _editCreditCtrl.text = formatNum(row['credit_amount']);
      _editNoteCtrl.text = (row['note'] ?? '').toString();
    });
  }

  Future<void> _saveChanges() async {
    if (_editingId == null) return;

    final updated = await ApiService.updateEntry(_editingId!, {
      'dailySales': double.tryParse(_editSalesCtrl.text) ?? 0,
      'stockReceived': double.tryParse(_editStockReceivedCtrl.text) ?? 0,
      'newStock': double.tryParse(_editNewStockCtrl.text) ?? 0,
      'cashAmount': double.tryParse(_editCashCtrl.text) ?? 0,
      'chequeAmount': double.tryParse(_editChequeCtrl.text) ?? 0,
      'rtgsAmount': double.tryParse(_editRtgsCtrl.text) ?? 0,
      'autoAmount': double.tryParse(_editAutoCtrl.text) ?? 0,
      'creditAmount': double.tryParse(_editCreditCtrl.text) ?? 0,
      'note': _editNoteCtrl.text.trim(),
    });

    if (updated) {
      setState(() => _editingId = null);
      _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated successfully!')),
      );
    }
  }

  Future<void> _deleteEntry(String id) async {
    final deleted = await ApiService.deleteEntry(id);
    if (deleted) {
      setState(() => _confirmDeleteId = null);
      _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted successfully!')),
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
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(),
                  const SizedBox(height: 14),
                  _buildFilterCard(),
                  const SizedBox(height: 12),
                  _buildBrandCard(),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'SSRSM Register ($_selectedBrand)',
                          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRegisterDateSubtitle(),
                          style: GoogleFonts.mukta(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mut),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTableCard(),
                  const SizedBox(height: 20),
                  _buildEditDeleteCard(),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.table_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register & Ledger',
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                'View, filter, edit & manage stock ledger entries',
                style: GoogleFonts.mukta(fontSize: 13, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Date Range', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedFilter = f);
                      _loadEntries();
                    },
                    selectedColor: AppColors.pri,
                    backgroundColor: AppColors.bg,
                    labelStyle: GoogleFonts.mukta(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedFilter == 'Custom') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _customStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _customStartDate = picked);
                        _loadEntries();
                      }
                    },
                    child: Text(_customStartDate != null ? dateLabel(_customStartDate!) : 'From Date'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _customEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _customEndDate = picked);
                        _loadEntries();
                      }
                    },
                    child: Text(_customEndDate != null ? dateLabel(_customEndDate!) : 'To Date'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrandCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which register?', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
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
                      _loadEntries();
                    },
                  ),
                  Text(b, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Exact 2-tier Blue Table matching Demo App
  Widget _buildTableCard() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
    }

    if (_entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text('No entries found for this selection.', style: GoogleFonts.mukta(color: AppColors.mut, fontSize: 15)),
      );
    }

    // Totals accumulation
    // Business Rule: For same date multiple entries, Opening Stock, New Stock, Daily Sales,
    // Stock Received and Closing Stock should be counted only ONCE per date (from the first entry).
    // Collection amounts (Cash, Cheque, RTGS, Auto, Credit) are summed across all entries.
    double totOpen = 0, totNew = 0, totSales = 0, totRec = 0, totClose = 0;
    double totCash = 0, totCheque = 0, totRtgs = 0, totAuto = 0, totCredit = 0;

    final Set<String> countedDates = {};

    for (var e in _entries) {
      final dateKey = (e['entry_date'] ?? '').toString().split('T')[0];
      if (!countedDates.contains(dateKey)) {
        countedDates.add(dateKey);
        totOpen += double.tryParse((e['opening_stock'] ?? 0).toString()) ?? 0;
        totNew += double.tryParse((e['new_stock'] ?? 0).toString()) ?? 0;
        totSales += double.tryParse((e['daily_sales'] ?? 0).toString()) ?? 0;
        totRec += double.tryParse((e['stock_received'] ?? 0).toString()) ?? 0;
        totClose += double.tryParse((e['closing_stock'] ?? 0).toString()) ?? 0;
      }
      totCash += double.tryParse((e['cash_amount'] ?? 0).toString()) ?? 0;
      totCheque += double.tryParse((e['cheque_amount'] ?? 0).toString()) ?? 0;
      totRtgs += double.tryParse((e['rtgs_amount'] ?? 0).toString()) ?? 0;
      totAuto += double.tryParse((e['auto_amount'] ?? 0).toString()) ?? 0;
      totCredit += double.tryParse((e['credit_amount'] ?? 0).toString()) ?? 0;
    }

    const borderColor = Color(0xFF1F2F8F);
    const headerBg = Color(0xFFEEF0FF);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(20, 23, 58, 0.08), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: borderColor, width: 1.2),
          columnWidths: const {
            0: FixedColumnWidth(44),   // S.No.
            1: FixedColumnWidth(85),   // Date
            2: FixedColumnWidth(75),   // Opening Stock
            3: FixedColumnWidth(65),   // New Stock
            4: FixedColumnWidth(70),   // Daily Sales
            5: FixedColumnWidth(75),   // Stock Received
            6: FixedColumnWidth(95),   // Total Closing Stock
            7: FixedColumnWidth(65),   // Cash
            8: FixedColumnWidth(65),   // Cheque
            9: FixedColumnWidth(65),   // RTGS
            10: FixedColumnWidth(65),  // Auto
            11: FixedColumnWidth(65),  // Credit
            12: FixedColumnWidth(95),  // Sales man
            13: FixedColumnWidth(110), // Note
          },
          children: [
            // Header Row 1
            TableRow(
              decoration: const BoxDecoration(color: headerBg),
              children: [
                _th2('S.NO.', rowspan: true),
                _th2('DATE', rowspan: true),
                _th2('OPENING\nSTOCK', rowspan: true),
                _th2('NEW\nSTOCK', rowspan: true),
                _th2('DAILY\nSALES', rowspan: true),
                _th2('STOCK\nRECEIVED', rowspan: true), // strictly Stock Received
                _th2('TOTAL CLOSING\nSTOCK', rowspan: true),
                _thGroup('COLLECTION'),
                _thGroup(''),
                _thGroup(''),
                _thGroup(''),
                _thGroup(''),
                _thGroup(''),
                _th2('NOTE', rowspan: true),
              ],
            ),
            // Header Row 2 (Sub-headers under COLLECTION)
            TableRow(
              decoration: const BoxDecoration(color: headerBg),
              children: [
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                _thSub('CASH'),
                _thSub('CHEQUE'),
                _thSub('RTGS'),
                _thSub('AUTO'),
                _thSub('CREDIT'),
                _thSub('SALES MAN'),
                const SizedBox(height: 0),
              ],
            ),
            // Data Rows
            ..._entries.asMap().entries.map((item) {
              final idx = item.key + 1;
              final e = item.value;
              return TableRow(
                children: [
                  _td('$idx.', align: TextAlign.center),
                  _td(formatDate((e['entry_date'] ?? '').toString()), align: TextAlign.center),
                  _td(formatNumWithZero(e['opening_stock'])),
                  _td(formatNum(e['new_stock'])),
                  _td(formatNumWithZero(e['daily_sales'])),
                  _td(formatNum(e['stock_received'])),
                  _td(formatNumWithZero(e['closing_stock'])),
                  _td(formatNum(e['cash_amount'])),
                  _td(formatNum(e['cheque_amount'])),
                  _td(formatNum(e['rtgs_amount'])),
                  _td(formatNum(e['auto_amount'])),
                  _td(formatNum(e['credit_amount'])),
                  _td(e['salesman_name'] ?? '', align: TextAlign.left),
                  _td(e['note'] ?? '', align: TextAlign.left),
                ],
              );
            }),
            // Footer Totals Row
            TableRow(
              decoration: const BoxDecoration(color: headerBg),
              children: [
                _tdBold('Total', align: TextAlign.center),
                _tdBold(''),
                _tdBold(formatNumWithZero(totOpen)),
                _tdBold(formatNumWithZero(totNew)),
                _tdBold(formatNumWithZero(totSales)),
                _tdBold(formatNumWithZero(totRec)),
                _tdBold(formatNumWithZero(totClose)),
                _tdBold(formatNumWithZero(totCash)),
                _tdBold(formatNumWithZero(totCheque)),
                _tdBold(formatNumWithZero(totRtgs)),
                _tdBold(formatNumWithZero(totAuto)),
                _tdBold(formatNumWithZero(totCredit)),
                _tdBold(''),
                _tdBold(''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _th2(String title, {bool rowspan = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.mukta(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF14243A),
          height: 1.15,
        ),
      ),
    );
  }

  Widget _thGroup(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.mukta(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF14243A),
        ),
      ),
    );
  }

  Widget _thSub(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.mukta(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF14243A),
        ),
      ),
    );
  }

  Widget _td(String text, {TextAlign align = TextAlign.right}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      alignment: align == TextAlign.center
          ? Alignment.center
          : (align == TextAlign.left ? Alignment.centerLeft : Alignment.centerRight),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.mukta(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF14243A),
        ),
      ),
    );
  }

  Widget _tdBold(String text, {TextAlign align = TextAlign.right}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      alignment: align == TextAlign.center
          ? Alignment.center
          : (align == TextAlign.left ? Alignment.centerLeft : Alignment.centerRight),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.mukta(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF14243A),
        ),
      ),
    );
  }

  // Exact Edit or Delete Card with Date Search like Demo App
  Widget _buildEditDeleteCard() {
    List<dynamic> filteredForEdit = _entries;
    if (_searchByDate != null) {
      final searchIso = dateISO(_searchByDate!);
      final searchDisplay = dateLabel(_searchByDate!);
      filteredForEdit = _entries.where((e) {
        final raw = (e['entry_date'] ?? '').toString();
        final dIso = raw.split('T')[0];
        final dDisplay = formatDate(raw);
        return dIso == searchIso || dDisplay == searchDisplay;
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(20, 23, 58, 0.07), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, color: AppColors.pri),
              const SizedBox(width: 8),
              Text(
                'Edit or delete entries',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Find entry by date',
            style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mut),
          ),
          const SizedBox(height: 4),
          // Date Filter Search Bar like Demo App
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _searchByDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _searchByDate = picked);
                    }
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line, width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchByDate != null ? dateLabel(_searchByDate!) : 'mm/dd/yyyy',
                          style: GoogleFonts.mukta(
                            fontSize: 14,
                            color: _searchByDate != null ? AppColors.ink : AppColors.mut,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.mut),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => setState(() => _searchByDate = null),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inline Edit Form if selected
          if (_editingId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Entry Details', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _buildEditField('Daily Sales', _editSalesCtrl),
                  _buildEditField('Stock Received', _editStockReceivedCtrl),
                  _buildEditField('New Stock', _editNewStockCtrl),
                  _buildEditField('Cash', _editCashCtrl),
                  _buildEditField('Cheque', _editChequeCtrl),
                  _buildEditField('RTGS', _editRtgsCtrl),
                  _buildEditField('Auto', _editAutoCtrl),
                  _buildEditField('Credit', _editCreditCtrl),
                  _buildEditField('Note', _editNoteCtrl, isNumber: false),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _editingId = null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.pri),
                        child: const Text('Save changes', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Entries List
          if (filteredForEdit.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _searchByDate != null ? 'No entry on ${dateLabel(_searchByDate!)}.' : 'No entries found.',
                style: GoogleFonts.mukta(color: AppColors.mut),
              ),
            ),
          ...filteredForEdit.map((e) {
            final id = e['id'];
            final dateStr = formatDate((e['entry_date'] ?? '').toString());
            final sales = formatNumWithZero(e['daily_sales']);
            final closing = formatNumWithZero(e['closing_stock']);
            final sm = e['salesman_name'] != null ? '${e['salesman_name']} · ' : '';

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink),
                        ),
                        Text(
                          '$sm Sales $sales · Closing $closing',
                          style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _startEditing(e),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      if (_confirmDeleteId == id) ...[
                        ElevatedButton(
                          onPressed: () => _deleteEntry(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bad,
                            minimumSize: const Size(70, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () => setState(() => _confirmDeleteId = null),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(60, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                        ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: () => setState(() => _confirmDeleteId = id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.bad,
                            minimumSize: const Size(60, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl, {bool isNumber = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

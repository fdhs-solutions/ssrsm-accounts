import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/platform_util.dart';
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
  final List<String> _brands = ['Dettol', 'Dabur', 'Diaper', 'Wholesale'];

  // Selection mode for deleting entries (photo gallery style)
  final Set<String> _selectedEntryIds = {};
  bool _isSelectionMode = false;
  bool _isBulkDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    String? startDate;
    String? endDate;

    // If a search date is selected in "Find entry by date", fetch for that date specifically
    if (_searchByDate != null) {
      final s = dateISO(_searchByDate!);
      startDate = s;
      endDate = s;
    } else if (_selectedFilter == 'Today') {
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
        productName: _selectedBrand,
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
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully!')),
        );
      }
    }
  }

  void _toggleSelectEntry(String id) {
    setState(() {
      if (_selectedEntryIds.contains(id)) {
        _selectedEntryIds.remove(id);
        if (_selectedEntryIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEntryIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAllEntries(List<dynamic> list) {
    setState(() {
      final allIds = list.map((e) => e['id'].toString()).toSet();
      if (_selectedEntryIds.length == allIds.length) {
        _selectedEntryIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedEntryIds.addAll(allIds);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEntryIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedEntries() async {
    if (_selectedEntryIds.isEmpty) return;

    final count = _selectedEntryIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count ${count > 1 ? "Entries" : "Entry"}?'),
        content: Text('Are you sure you want to delete $count selected ${count > 1 ? "entries" : "entry"}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bad),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBulkDeleting = true);
    final idsToDelete = List<String>.from(_selectedEntryIds);
    final successCount = await ApiService.deleteEntriesBulk(idsToDelete);

    if (mounted) {
      setState(() {
        _isBulkDeleting = false;
        _selectedEntryIds.clear();
        _isSelectionMode = false;
      });
      _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount ${successCount > 1 ? "entries" : "entry"} deleted successfully!')),
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
                  _buildExportActionsCard(),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.table_chart, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Register & Ledger',
                  style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'View, filter, edit & manage stock ledger entries',
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
              children: [
                ..._filters.map((f) {
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
                }),
                // Clear Filter Button
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'Today';
                        _customStartDate = null;
                        _customEndDate = null;
                        _searchByDate = null;
                      });
                      _loadEntries();
                    },
                    icon: const Icon(Icons.filter_alt_off, size: 16, color: Colors.white),
                    label: const Text('Clear Filter', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444), // Red color
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _customStartDate != null ? dateLabel(_customStartDate!) : 'From Date',
                      style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _customEndDate != null ? dateLabel(_customEndDate!) : 'To Date',
                      style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'Today';
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                    _loadEntries();
                  },
                  icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                  tooltip: 'Close Custom',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.tint,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      width: double.infinity,
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
    const double totalCollectionWidth = 65 + 65 + 65 + 65 + 65 + 95; // 420px

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border.fromBorderSide(BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(20, 23, 58, 0.08), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tier 1 & 2 Header Row ──
            Container(
              decoration: const BoxDecoration(
                color: headerBg,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  _buildStandaloneTh('S.NO.', 44),
                  _buildStandaloneTh('DATE', 85),
                  _buildStandaloneTh('OPENING\nSTOCK', 75),
                  _buildStandaloneTh('NEW\nSTOCK', 65),
                  _buildStandaloneTh('DAILY\nSALES', 70),
                  _buildStandaloneTh('STOCK\nRECEIVED', 75),
                  _buildStandaloneTh('TOTAL CLOSING\nSTOCK', 95),
                  // Unified COLLECTION block (Top Header + 6 Sub-headers)
                  SizedBox(
                    width: totalCollectionWidth,
                    height: 56,
                    child: Column(
                      children: [
                        Container(
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: borderColor, width: 1.2),
                              right: BorderSide(color: borderColor, width: 1.2),
                            ),
                          ),
                          child: Text(
                            'COLLECTION',
                            style: GoogleFonts.mukta(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: const Color(0xFF14243A),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Row(
                            children: [
                              _buildSubTh('CASH', 65),
                              _buildSubTh('CHEQUE', 65),
                              _buildSubTh('RTGS', 65),
                              _buildSubTh('AUTO', 65),
                              _buildSubTh('CREDIT', 65),
                              _buildSubTh('SALES MAN', 95),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStandaloneTh('NOTE', 110, isLast: true),
                ],
              ),
            ),
            // ── Data Rows ──
            ...() {
              int currentSno = 0;
              String? lastDate;

              return _entries.map((e) {
                final dateStr = (e['entry_date'] ?? '').toString().split('T')[0];
                final bool isSubsequentEntry = (dateStr == lastDate);

                String displaySno = '';
                if (!isSubsequentEntry) {
                  currentSno++;
                  lastDate = dateStr;
                  displaySno = '$currentSno.';
                }

                final rowColor = isSubsequentEntry ? const Color(0xFFFFF3DC) : Colors.transparent;

                return Container(
                  decoration: BoxDecoration(
                    color: rowColor,
                    border: const Border(
                      bottom: BorderSide(color: borderColor, width: 1.2),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _cell(displaySno, 44, align: TextAlign.center),
                        _cell(formatDate((e['entry_date'] ?? '').toString()), 85, align: TextAlign.center),
                        _cell(formatNumWithZero(e['opening_stock']), 75),
                        _cell(formatNum(e['new_stock']), 65),
                        _cell(formatNumWithZero(e['daily_sales']), 70),
                        _cell(formatNum(e['stock_received']), 75),
                        _cell(formatNumWithZero(e['closing_stock']), 95),
                        _cell(formatNum(e['cash_amount']), 65),
                        _cell(formatNum(e['cheque_amount']), 65),
                        _cell(formatNum(e['rtgs_amount']), 65),
                        _cell(formatNum(e['auto_amount']), 65),
                        _cell(formatNum(e['credit_amount']), 65),
                        _cell(e['salesman_name']?.toString() ?? '', 95, align: TextAlign.left),
                        _cell(e['note']?.toString() ?? '', 110, align: TextAlign.left, isLast: true),
                      ],
                    ),
                  ),
                );
              }).toList();
            }(),
            // ── Footer Totals Row ──
            Container(
              decoration: const BoxDecoration(
                color: headerBg,
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _cell('Total', 44, align: TextAlign.center, isBold: true),
                    _cell('', 85, isBold: true),
                    _cell(formatNumWithZero(totOpen), 75, isBold: true),
                    _cell(formatNumWithZero(totNew), 65, isBold: true),
                    _cell(formatNumWithZero(totSales), 70, isBold: true),
                    _cell(formatNumWithZero(totRec), 75, isBold: true),
                    _cell(formatNumWithZero(totClose), 95, isBold: true),
                    _cell(formatNumWithZero(totCash), 65, isBold: true),
                    _cell(formatNumWithZero(totCheque), 65, isBold: true),
                    _cell(formatNumWithZero(totRtgs), 65, isBold: true),
                    _cell(formatNumWithZero(totAuto), 65, isBold: true),
                    _cell(formatNumWithZero(totCredit), 65, isBold: true),
                    _cell('', 95, isBold: true),
                    _cell('', 110, isBold: true, isLast: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandaloneTh(String title, double width, {bool isLast = false}) {
    const borderColor = Color(0xFF1F2F8F);
    return Container(
      width: width,
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: isLast ? BorderSide.none : const BorderSide(color: borderColor, width: 1.2),
        ),
      ),
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

  Widget _buildSubTh(String title, double width, {bool isLast = false}) {
    const borderColor = Color(0xFF1F2F8F);
    return Container(
      width: width,
      height: 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          right: isLast ? BorderSide.none : const BorderSide(color: borderColor, width: 1.2),
        ),
      ),
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

  Widget _cell(String text, double width, {TextAlign align = TextAlign.right, bool isBold = false, bool isLast = false}) {
    const borderColor = Color(0xFF1F2F8F);
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      alignment: align == TextAlign.center
          ? Alignment.center
          : (align == TextAlign.left ? Alignment.centerLeft : Alignment.centerRight),
      decoration: BoxDecoration(
        border: Border(
          right: isLast ? BorderSide.none : const BorderSide(color: borderColor, width: 1.2),
        ),
      ),
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.mukta(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
          // Bulk Selection Action Bar (appears when entries are selected or long-pressed)
          if (_isSelectionMode) ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Soft Indigo/Blue tint
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 330,
                  child: Row(
                    children: [
                      // Selected count pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pri,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_selectedEntryIds.length} Selected',
                          style: GoogleFonts.mukta(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Select All / Deselect All Button
                      InkWell(
                        onTap: () => _selectAllEntries(filteredForEdit),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedEntryIds.length == filteredForEdit.length ? Icons.deselect : Icons.select_all,
                                size: 16,
                                color: AppColors.pri,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _selectedEntryIds.length == filteredForEdit.length ? 'Deselect' : 'Select All',
                                style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.pri),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Delete Selected Button (Clean, single-line pill button)
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: _isBulkDeleting ? null : _deleteSelectedEntries,
                          icon: _isBulkDeleting
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Close selection mode
                      InkWell(
                        onTap: _clearSelection,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                      _loadEntries(); // triggers GET /api/entries API call with that date
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
                          _searchByDate != null ? dateLabel(_searchByDate!) : 'dd/mm/yyyy',
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
                onPressed: () {
                  setState(() => _searchByDate = null);
                  _loadEntries();
                },
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
            final id = e['id'].toString();
            final isSelected = _selectedEntryIds.contains(id);
            final dateStr = formatDate((e['entry_date'] ?? '').toString());
            final sales = formatNumWithZero(e['daily_sales']);
            final closing = formatNumWithZero(e['closing_stock']);
            final sm = e['salesman_name'] != null ? '${e['salesman_name']} · ' : '';

            return InkWell(
              onLongPress: () {
                _toggleSelectEntry(id);
              },
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelectEntry(id);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
                      : const Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Checkbox or Selection Indicator (like photo gallery selection)
                    if (_isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          _toggleSelectEntry(id);
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
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
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExportActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 23, 58, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with left accent bar
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4338CA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Preview, print or download',
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Full-width Preview Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: _handlePdfPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E293B),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Preview',
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Row with Print and Download PDF buttons
          Row(
            children: [
              // Print Button (Outlined)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _handlePdfPrint,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Print',
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Download PDF Button (Filled Gradient / Brand Blue)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _handlePdfDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Download PDF',
                        maxLines: 1,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Caption
          Text(
            'Print and PDF contain only the entries shown above.',
            style: GoogleFonts.mukta(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  (String?, String?) _getActiveDateRange() {
    String? startDate;
    String? endDate;
    if (_searchByDate != null) {
      final s = dateISO(_searchByDate!);
      startDate = s;
      endDate = s;
    } else if (_selectedFilter == 'Today') {
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
    return (startDate, endDate);
  }

  void _handlePdfPreview() {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries in this selection to preview')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 700),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Header Toolbar matching Demo (#pv .pvt)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(20, 23, 58, 0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Preview',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      // Close button
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      // Print button
                      OutlinedButton(
                        onPressed: () {
                          _handlePdfPrint();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text('Print'),
                      ),
                      const SizedBox(width: 8),
                      // Download PDF button
                      ElevatedButton(
                        onPressed: () {
                          _handlePdfDownload();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text('Download PDF'),
                      ),
                    ],
                  ),
                ),

                // Body Paper Card matching Demo (#pv .pvb .paper)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.15),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SSRSM Register ($_selectedBrand)',
                              style: GoogleFonts.sora(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getRegisterDateSubtitle(),
                              style: GoogleFonts.mukta(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTableCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePdfDownload() async {
    final (startDate, endDate) = _getActiveDateRange();
    final url = await ApiService.getPdfUrl(
      productId: _selectedBrand,
      productName: _selectedBrand,
      startDate: startDate,
      endDate: endDate,
      download: true,
    );

    if (kIsWeb) {
      downloadWebPdf(url, 'SSRSM_Register_$_selectedBrand.pdf');
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch: $url')),
        );
      }
    }
  }

  Future<void> _handlePdfPrint() async {
    final (startDate, endDate) = _getActiveDateRange();
    final url = await ApiService.getPdfUrl(
      productId: _selectedBrand,
      productName: _selectedBrand,
      startDate: startDate,
      endDate: endDate,
      download: false,
    );

    if (kIsWeb) {
      // In web browser, opening the PDF in a new tab allows direct viewing and Ctrl+P / native print
      openWebUrl(url);
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch: $url')),
        );
      }
    }
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

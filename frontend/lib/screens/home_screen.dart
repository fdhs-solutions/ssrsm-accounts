import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPeriod = 'Today';
  String _selectedProduct = 'All';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  final List<String> _periods = ['Today', 'Week', '1 Month', '1 Year', 'Custom'];
  final List<String> _products = ['All', 'Dettol', 'Dabur', 'Diaper', 'Wholesale'];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    String? date;
    String? startDate;
    String? endDate;

    if (_selectedPeriod == 'Today') {
      date = todayISO();
    } else if (_selectedPeriod == 'Week') {
      final range = thisWeekRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedPeriod == '1 Month') {
      final range = thisMonthRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedPeriod == '1 Year') {
      final range = thisYearRange();
      startDate = dateISO(range.start);
      endDate = dateISO(range.end);
    } else if (_selectedPeriod == 'Custom') {
      if (_customStartDate != null) startDate = dateISO(_customStartDate!);
      if (_customEndDate != null) endDate = dateISO(_customEndDate!);
    }

    try {
      final res = await ApiService.getDashboard(
        date: date,
        startDate: startDate,
        endDate: endDate,
        productId: _selectedProduct == 'All' ? null : _selectedProduct,
      );
      if (res['success'] == true) {
        setState(() {
          _dashboardData = res['data'] ?? {};
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.mukta(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.mut,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // No Button (Cancel)
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('No', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          // Yes Button (Logout confirm)
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), // Red
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  String _getChartPeriodSubtitle() {
    if (_selectedPeriod == 'Today') {
      return dateLabel(DateTime.now());
    } else if (_selectedPeriod == 'Week') {
      final range = thisWeekRange();
      return '${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedPeriod == '1 Month') {
      final range = thisMonthRange();
      return '${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedPeriod == '1 Year') {
      final range = thisYearRange();
      return '${dateLabel(range.start)} - ${dateLabel(range.end)}';
    } else if (_selectedPeriod == 'Custom') {
      final s = _customStartDate != null ? dateLabel(_customStartDate!) : '...';
      final e = _customEndDate != null ? dateLabel(_customEndDate!) : '...';
      return '$s - $e';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 14),
                    _buildChartCard(),
                    const SizedBox(height: 18),
                    _buildSectionHeader('Collection by mode · $_selectedPeriod'),
                    const SizedBox(height: 10),
                    _buildCollectionByModeGrid(isTablet),
                    const SizedBox(height: 18),
                    _buildSectionHeader('Collection by sales man · $_selectedPeriod'),
                    const SizedBox(height: 10),
                    _buildCollectionBySalesmanGrid(isTablet),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${dayNames[now.weekday - 1]} ${monthNames[now.month - 1]} ${now.day} ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.mukta(
                fontSize: 14,
                color: AppColors.mut,
              ),
            ),
            Text(
              'SSRSM Accounts',
              style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout, size: 18, color: AppColors.bad),
          label: Text(
            'Logout',
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.bad,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            elevation: 2,
            shadowColor: const Color.fromRGBO(20, 23, 58, 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.pri,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final summary = _dashboardData['summary'] ?? {};
    final double openStock = (summary['totalOpeningStock'] ?? 0).toDouble();
    final double newStock = (summary['totalNewStock'] ?? 0).toDouble();
    final double sales = (summary['totalSales'] ?? 0).toDouble();
    final double stockReceived = (summary['totalStockReceived'] ?? 0).toDouble();
    final double closingStock = openStock + newStock - sales + stockReceived;

    final double maxVal = [openStock, newStock, sales, stockReceived, closingStock, 1.0]
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
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
          // Period Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedPeriod = p);
                      _loadDashboard();
                    },
                    selectedColor: AppColors.pri,
                    backgroundColor: AppColors.bg,
                    labelStyle: GoogleFonts.mukta(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedPeriod == 'Custom') ...[
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
                        _loadDashboard();
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
                        _loadDashboard();
                      }
                    },
                    child: Text(_customEndDate != null ? dateLabel(_customEndDate!) : 'To Date'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Product Radio Selector
          Wrap(
            spacing: 14,
            children: _products.map((prod) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: prod,
                    groupValue: _selectedProduct,
                    activeColor: AppColors.pri,
                    onChanged: (val) {
                      setState(() => _selectedProduct = val!);
                      _loadDashboard();
                    },
                  ),
                  Text(
                    prod,
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
          const SizedBox(height: 10),
          // Header with Title & Date range above the chart (like Register page)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock chart · $_selectedProduct',
                style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                _getChartPeriodSubtitle(),
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable Bar Chart with fixed bar height and equal baseline
          _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBarCol('Opening\nstock', openStock, maxVal, AppColors.pri),
                        _buildBarCol('New\nstock', newStock, maxVal, AppColors.autoColor),
                        _buildBarCol('Daily\nsales', sales, maxVal, AppColors.acc),
                        _buildBarCol('Stock\nReceived', stockReceived, maxVal, AppColors.ok),
                        _buildBarCol('Total closing\nstock', closingStock, maxVal, AppColors.ink),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBarCol(String label, double val, double maxVal, Color color) {
    const double maxBarHeight = 120.0;
    // Calculate exact height so all bars sit on the EXACT SAME bottom baseline
    final double barHeight = maxVal > 0 ? (val / maxVal).clamp(0.04, 1.0) * maxBarHeight : 5.0;

    return Container(
      width: 78,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Amount text on top of bar (SingleChildScrollView prevents ellipsis truncation like 500...)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatNumWithZero(val),
              style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 6),
          // Bar container with fixed height canvas to guarantee equal baseline
          SizedBox(
            height: maxBarHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 44,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
          ),
          // Common horizontal baseline line
          Container(
            height: 2,
            width: double.infinity,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 6),
          // Column label below baseline
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.mut,
              height: 1.15,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionByModeGrid(bool isTablet) {
    final mode = _dashboardData['collectionByMode'] ?? {};
    final cash = (mode['cash'] ?? 0).toDouble();
    final cheque = (mode['cheque'] ?? 0).toDouble();
    final rtgs = (mode['rtgs'] ?? 0).toDouble();
    final auto = (mode['auto'] ?? 0).toDouble();
    final credit = (mode['credit'] ?? 0).toDouble();

    final items = [
      {'label': 'Cash', 'val': cash, 'color': AppColors.cashColor},
      {'label': 'Cheque', 'val': cheque, 'color': AppColors.chequeColor},
      {'label': 'RTGS', 'val': rtgs, 'color': AppColors.rtgsColor},
      {'label': 'Auto collection', 'val': auto, 'color': AppColors.autoColor},
      {'label': 'Credit', 'val': credit, 'color': AppColors.creditColor},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border(top: BorderSide(color: it['color'] as Color, width: 4)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(20, 23, 58, 0.06),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                it['label'] as String,
                style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                inr(it['val'] as num),
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionBySalesmanGrid(bool isTablet) {
    final list = _dashboardData['collectionBySalesman'] as List<dynamic>? ?? [];

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Sales man tab me naam jodo, phir yaha collection dikhega.',
          style: GoogleFonts.mukta(fontSize: 14, color: AppColors.mut),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, i) {
        final sm = list[i];
        final name = sm['salesmanName'] ?? 'Unassigned';
        final total = (sm['totalCollection'] ?? 0).toDouble();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: const Border(top: BorderSide(color: AppColors.autoColor, width: 4)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(20, 23, 58, 0.06),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: GoogleFonts.mukta(fontSize: 13, color: AppColors.mut, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                inr(total),
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

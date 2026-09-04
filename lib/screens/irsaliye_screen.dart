import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/fatura_irsaliye_model.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class IrsaliyeScreen extends StatefulWidget {
  const IrsaliyeScreen({super.key});

  @override
  State<IrsaliyeScreen> createState() => _IrsaliyeScreenState();
}

class _IrsaliyeScreenState extends State<IrsaliyeScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');
  final TextEditingController _searchController = TextEditingController();

  List<RecentWaybill> _waybills = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWaybills();
  }

  Future<void> _loadWaybills() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getRecentWaybills();
      setState(() {
        _waybills = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _waybills.where((w) {
      if (_searchQuery.isEmpty) return true;
      return w.cariAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.evrakRef.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('e-İrsaliyeler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadWaybills,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.slate700),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'İrsaliye no veya müşteri unvanı ile ara...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.slate200)),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadWaybills,
                    color: AppTheme.primaryBlue,
                    child: filtered.isEmpty
                        ? const Center(child: Text('Kayıtlı irsaliye bulunamadı.', style: TextStyle(color: AppTheme.slate400)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final way = filtered[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.slate200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            way.cariAd,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '${way.evrakRef} • ' + DateFormat('dd.MM.yyyy').format(way.date),
                                                style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                                                child: const Text('GİB Onaylı', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_kgFormat.format(way.miktarKg)} KG',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PdfViewerScreen(
                                                  documentId: way.id.toString(),
                                                  documentNo: way.evrakRef,
                                                  title: way.cariAd,
                                                  type: 'irsaliye',
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.print_rounded, size: 11, color: AppTheme.primaryEmerald),
                                                SizedBox(width: 3),
                                                Text('PDF / GİB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

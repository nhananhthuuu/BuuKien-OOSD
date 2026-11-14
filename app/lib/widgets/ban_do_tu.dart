import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

num _so(dynamic v) => v is num ? v : (num.tryParse('$v') ?? 0);

class BanDoTu extends StatefulWidget {
  const BanDoTu({super.key});

  @override
  State<BanDoTu> createState() => _BanDoTuState();
}

class _BanDoTuState extends State<BanDoTu> {
  // Vị trí giả lập của người dùng: sảnh giữa hai tòa (demo)
  static const double _kinhDo = 106.7010;
  static const double _viDo = 10.7770;

  late Future<dynamic> _future;
  Map? _chon;
  String _kichCo = 'S';
  String? _ketQuaGanNhat;
  bool _dangTim = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu('/api/ban-do/tu');
  }

  void _taiLai() {
    setState(() {
      _chon = null;
      _future = ApiService.layDuLieu('/api/ban-do/tu');
    });
  }

  Future<void> _timGanNhat() async {
    setState(() {
      _dangTim = true;
      _ketQuaGanNhat = null;
    });
    String kq;
    try {
      var d = await ApiService.layDuLieu(
          '/api/ban-do/tu-gan-nhat?kinhDo=$_kinhDo&viDo=$_viDo&kichCo=$_kichCo');
      if (d is List) d = d.isEmpty ? null : d.first;
      if (d is Map && d['ma_tu'] != null) {
        kq = 'Tủ gần nhất cho cỡ $_kichCo: ${d['ma_tu']} (${d['vi_tri']})\n'
            'Cách khoảng ${_so(d['khoang_cach_m']).round()} m, còn ${_so(d['so_ngan_trong'])} ngăn phù hợp';
      } else {
        kq = 'Hiện không còn tủ nào có ngăn trống cỡ $_kichCo';
      }
    } catch (_) {
      kq = 'Không tìm được tủ gần nhất';
    }
    if (!mounted) return;
    setState(() {
      _dangTim = false;
      _ketQuaGanNhat = kq;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Không tải được bản đồ'),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: _taiLai, child: const Text('Thử lại')),
              ],
            ),
          );
        }
        final ds = ((snap.data as List?) ?? []).whereType<Map>().toList();

        final markers = ds.map((t) {
          final conTrong = _so(t['con_trong']);
          final mau = conTrong > 0 ? Colors.green : Colors.red;
          return Marker(
            point: LatLng(_so(t['vi_do']).toDouble(), _so(t['kinh_do']).toDouble()),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: () => setState(() => _chon = t),
              child: Icon(Icons.location_on, color: mau, size: 48),
            ),
          );
        }).toList();

        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(_viDo, _kinhDo),
                initialZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  maxNativeZoom: 19,
                  userAgentPackageName: 'com.doan.buukien_app',
                ),
                // Vị trí giả lập của người dùng
                const MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_viDo, _kinhDo),
                    width: 30,
                    height: 30,
                    child: Icon(Icons.my_location, color: Colors.blue, size: 28),
                  ),
                ]),
                MarkerLayer(markers: markers),
              ],
            ),
            // Khung tìm tủ gần nhất
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 'S', label: Text('S')),
                              ButtonSegment(value: 'M', label: Text('M')),
                              ButtonSegment(value: 'L', label: Text('L')),
                            ],
                            selected: {_kichCo},
                            onSelectionChanged: (s) =>
                                setState(() => _kichCo = s.first),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _dangTim ? null : _timGanNhat,
                            icon: const Icon(Icons.near_me, size: 18),
                            label: const Text('Tủ gần nhất'),
                          ),
                        ],
                      ),
                      if (_ketQuaGanNhat != null) ...[
                        const SizedBox(height: 8),
                        Text(_ketQuaGanNhat!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Thông tin tủ đang chọn
            if (_chon != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(
                      Icons.view_module_outlined,
                      color: _so(_chon!['con_trong']) > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text('${_chon!['ma_tu']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${_chon!['vi_tri']}\nCòn ${_so(_chon!['con_trong'])} ngăn trống'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _chon = null),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
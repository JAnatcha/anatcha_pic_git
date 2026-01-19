import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart.dart';

class KapraoPage extends StatefulWidget {
  const KapraoPage({super.key});

  @override
  State<KapraoPage> createState() => _KapraoPageState();
}

class _KapraoPageState extends State<KapraoPage> {
  late YoutubePlayerController _ytController;

  final int price = 50;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController commentCtrl = TextEditingController();
  int totalPrice = 0;

  final double shopLatitude = 18.273041486031918;
  final double shopLongitude = 99.50163563543747;

  double? currentLat;
  double? currentLng;
  double distance = 0;
  String travelTime = '';

  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];

  final String orsApiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImZmYTVkY2ZiYzY4ODQ0ZDI5YjBhZjI0YTIzYTYxMDY2IiwiaCI6Im11cm11cjY0In0="; // ใส่คีย์จริง

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId('https://youtu.be/16Odh9KFPK0');
    _ytController = YoutubePlayerController(
      initialVideoId: videoId ?? 'dQw4w9WgXcQ',
      flags: const YoutubePlayerFlags(autoPlay: false),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    qtyCtrl.dispose();
    commentCtrl.dispose();
    super.dispose();
  }

  void calcPrice() {
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    setState(() {
      totalPrice = qty * price;
    });
  }

  Future<void> _getCurrentLocationSafe() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("กรุณาเปิด GPS / Location");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage("กรุณาเปิดสิทธิ์ Location ใน Settings");
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
        distance = Geolocator.distanceBetween(
              currentLat ?? 0,
              currentLng ?? 0,
              shopLatitude,
              shopLongitude,
            ) / 1000;
      });

      if (currentLat != null && currentLng != null) {
        _mapController.move(LatLng(currentLat!, currentLng!), 15);
        await _fetchRoute();
      }
    } catch (e) {
      _showMessage("ไม่สามารถอ่านพิกัดได้: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchRoute() async {
    if (currentLat == null || currentLng == null) return;

    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');
    final body = jsonEncode({
      "coordinates": [
        [currentLng!, currentLat!],
        [shopLongitude, shopLatitude]
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {"Authorization": orsApiKey, "Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['geometry']['coordinates'] as List<dynamic>;
          final summary = data['features'][0]['properties']?['summary'];

          setState(() {
            routePoints = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();

            if (summary != null && summary['duration'] != null) {
              travelTime = "${(summary['duration'] / 60).toStringAsFixed(0)} นาที";
            }
          });
        }
      } else {
        _showMessage("ไม่สามารถดึงเส้นทางได้");
      }
    } catch (e) {
      _showMessage("เกิดข้อผิดพลาดในการดึงเส้นทาง");
    }
  }

  void _addToCart() {
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final comment = commentCtrl.text.trim();
    if (qty <= 0) {
      _showMessage("กรุณากรอกจำนวนมากกว่า 0");
      return;
    }

    Cart.addItem(
        "กะเพราหมูกรอบ${comment.isNotEmpty ? ' ($comment)' : ''}",
        price,
        qty);

    qtyCtrl.clear();
    commentCtrl.clear();
    setState(() {
      totalPrice = 0;
    });

    _showMessage("เพิ่มลงตะกร้าแล้ว");
  }

  Future<void> _submitCart() async {
    if (Cart.items.isEmpty) {
      _showMessage("ตะกร้าว่าง");
      return;
    }

    try {
      final data = {
        "items": Cart.items
            .map((item) => {
                  "name": item.name,
                  "price": item.price,
                  "qty": item.qty,
                  "total": item.price * item.qty,
                })
            .toList(),
        "totalPrice": Cart.totalPrice(),
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("orders").add(data);
      _showMessage("สั่งอาหารเรียบร้อยแล้ว");

      Cart.clear();
      setState(() {});
    } catch (e) {
      _showMessage("เกิดข้อผิดพลาดในการบันทึก: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng shopPoint = LatLng(shopLatitude, shopLongitude);

    return Scaffold(
      appBar: AppBar(title: const Text("กะเพราหมูกรอบ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // วัตถุดิบ
            ExpansionTile(
              leading: const Icon(Icons.kitchen),
              title: const Text("วัตถุดิบ (สำหรับ 1 จาน)"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "- หมูกรอบ 150 กรัม\n- ใบกะเพรา 1 กำมือ\n- พริก 3-5 เม็ด\n- กระเทียม 2 กลีบ\n- ข้าวสวย 1 จาน\n- ไข่ดาว (ถ้ามี)\n- น้ำปลา, น้ำตาล, ซอสปรุงรส",
                  ),
                )
              ],
            ),

            // วิธีทำ
            ExpansionTile(
              leading: const Icon(Icons.menu_book),
              title: const Text("วิธีทำ"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "1. ผัดกระเทียม พริก ใส่หมูกรอบจนสุก\n"
                    "2. ปรุงรส น้ำปลา น้ำตาล ซอส\n"
                    "3. ใส่ใบกะเพราผัดเร็ว ๆ\n"
                    "4. เสิร์ฟร้อน ๆ คู่ข้าวสวย และไข่ดาว",
                  ),
                )
              ],
            ),

            // วิดีโอ
            ExpansionTile(
              leading: const Icon(Icons.play_circle_fill),
              title: const Text("วิดีโอสอนทำอาหาร"),
              children: [
                SizedBox(
                  height: 220,
                  child: YoutubePlayer(
                      controller: _ytController,
                      showVideoProgressIndicator: true),
                ),
              ],
            ),

            const Divider(height: 30),

            // แผนที่ร้าน
            ExpansionTile(
              leading: const Icon(Icons.map),
              title: const Text("แผนที่ร้าน & พิกัด"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(center: shopPoint, zoom: 14),
                          children: [
                            TileLayer(
                              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: shopPoint,
                                  width: 40,
                                  height: 40,
                                  builder: (_) => const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                                if (currentLat != null && currentLng != null)
                                  Marker(
                                    point: LatLng(currentLat!, currentLng!),
                                    width: 40,
                                    height: 40,
                                    builder: (_) => const Icon(Icons.my_location, color: Colors.blue, size: 40),
                                  ),
                              ],
                            ),
                            if (routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [Polyline(points: routePoints, color: Colors.blue, strokeWidth: 4)],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _getCurrentLocationSafe, child: const Text("อ่านพิกัดปัจจุบัน")),
                      const SizedBox(height: 6),
                      Text(
                        "ระยะทางจากคุณถึงร้าน: ${distance.toStringAsFixed(2)} กม.",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (travelTime.isNotEmpty)
                        Text(
                          "เวลาเดินทางโดยรถยนต์: $travelTime",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            // สั่งอาหาร
            const Text("สั่งอาหาร", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("ราคา $price บาท / จาน"),
            const SizedBox(height: 6),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "จำนวน"),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(hintText: "ใส่หมายเหตุ เช่น ขอเผ็ดน้อย"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: calcPrice, child: const Text("คำนวณราคา")),
            Text("รวม: $totalPrice บาท", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text("เพิ่มลงตะกร้า"),
                    onPressed: _addToCart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("สั่งอาหารทั้งหมด"),
                    onPressed: _submitCart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

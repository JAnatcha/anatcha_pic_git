import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart.dart';

class NoodlePage extends StatefulWidget {
  const NoodlePage({super.key});

  @override
  State<NoodlePage> createState() => _NoodlePageState();
}

class _NoodlePageState extends State<NoodlePage> {
  late YoutubePlayerController _ytController;

  final int price = 45;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController commentCtrl = TextEditingController();
  int totalPrice = 0;

  final double shopLatitude = 18.28169;
  final double shopLongitude = 99.51068;

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
    final videoId = YoutubePlayer.convertUrlToId('https://youtu.be/oFLJyxRsxvQ');
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
        final coords = data['features'][0]['geometry']['coordinates'] as List<dynamic>;
        final summary = data['features'][0]['properties']['summary'];

        final points = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        setState(() {
          routePoints = points;
          travelTime = "${(summary['duration'] / 60).toStringAsFixed(0)} นาที";
        });

        if (routePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(routePoints);
          _mapController.fitBounds(bounds,
              options: const FitBoundsOptions(padding: EdgeInsets.all(50)));
        }
      } else {
        _showMessage("ไม่สามารถดึงเส้นทางได้ ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("ไม่สามารถดึงเส้นทางได้: $e");
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
      "ก๋วยเตี๋ยว${comment.isNotEmpty ? ' ($comment)' : ''}",
      price,
      qty,
    );

    qtyCtrl.clear();
    commentCtrl.clear();
    setState(() => totalPrice = 0);

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
      appBar: AppBar(title: const Text("ก๋วยเตี๋ยว")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // วัตถุดิบ
          ExpansionTile(
            leading: const Icon(Icons.kitchen),
            title: const Text("วัตถุดิบ (1 ชาม)"),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "- เส้นก๋วยเตี๋ยว\n- หมู/ลูกชิ้น\n- ผักลวก\n- น้ำซุป\n- ซีอิ๊ว\n- น้ำปลา\n- พริก\n- ไข่ต้ม/ลวก",
                ),
              ),
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
                  "1. ต้มหมู ลูกชิ้น ในน้ำซุป\n"
                  "2. ลวกเส้น ใส่ชาม พร้อมผัก\n"
                  "3. ปรุงรสด้วยซีอิ๊ว น้ำปลา น้ำตาล\n"
                  "4. ราดน้ำซุปร้อน ๆ โรยหน้ากระเทียมเจียว ต้นหอม ผักชี และพริก\n"
                  "5. เสิร์ฟร้อน ๆ",
                ),
              ),
            ],
          ),

          // วิดีโอ
          ExpansionTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text("วิดีโอสอนทำอาหาร"),
            children: [
              SizedBox(
                height: 220,
                child: YoutubePlayer(controller: _ytController, showVideoProgressIndicator: true),
              ),
            ],
          ),

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
                            PolylineLayer(polylines: [Polyline(points: routePoints, color: Colors.blue, strokeWidth: 4)]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _getCurrentLocationSafe, child: const Text("อ่านพิกัดปัจจุบัน")),
                    Text("ระยะทางจากคุณถึงร้าน: ${distance.toStringAsFixed(2)} กม.", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (travelTime.isNotEmpty)
                      Text("เวลาเดินทางโดยรถยนต์: $travelTime", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 30),

          // สั่งอาหาร
          const Text("สั่งอาหาร", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("ราคา $price บาท / ชาม"),
          const SizedBox(height: 6),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "จำนวน"),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: commentCtrl,
            decoration: const InputDecoration(hintText: "หมายเหตุ เช่น ไม่ใส่ผัก"),
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
        ]),
      ),
    );
  }
}

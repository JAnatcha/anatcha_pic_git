import 'package:flutter/material.dart';

void main() => runApp(const FoodApp());

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const FoodMenuPage(),
    );
  }
}

class FoodMenuPage extends StatelessWidget {
  const FoodMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("FOOD APP", 
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView( // ใช้ ListView ธรรมดาเพื่อให้โค้ดสั้นและไฟล์เล็กลง
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const _Header(title: "อาหารคาว"),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.8,
            children: const [
              _Card(name: "ข้าวมันไก่", price: "50", img: "kanomkro.jpg"),
              _Card(name: "ผัดกะเพรา", price: "50", img: "krapao.jpg"),
              _Card(name: "ส้มตำไทย", price: "40", img: "somtum.jpg"),
              _Card(name: "ลาบหมู", price: "40", img: "larb.jpg"),
            ],
          ),
          const _Header(title: "ของหวาน"),
          const _ListTile(name: "ขนมครก", price: "20"),
          const _ListTile(name: "ข้าวเหนียวสังขยา", price: "10"),
          const _ListTile(name: "สาคูน้ำกะทิ", price: "20"),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.black,
        icon: const Icon(Icons.shopping_basket, color: Colors.white),
        label: const Text("ตะกร้า", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ส่วนหัวข้อหมวดหมู่
class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Container(width: 40, height: 2.5, color: Colors.orange),
        ],
      ),
    );
  }
}

// การ์ดอาหารคาว
class _Card extends StatelessWidget {
  final String name, price, img;
  const _Card({required this.name, required this.price, required this.img});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                ),
              ),
              CircleAvatar(
                radius: 14, backgroundColor: Colors.orange,
                child: Text(price, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ลิสต์ของหวาน
class _ListTile extends StatelessWidget {
  final String name, price;
  const _ListTile({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.cookie, color: Colors.orange),
          const SizedBox(width: 15),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text("฿$price", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
        ],
      ),
    );
  }
}
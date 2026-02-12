import 'package:flutter/material.dart';

void main() {
  runApp(const FoodApp());
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food App UI Demo',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Kanit', 
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
      ),
      // กำหนด Routes ไปยังหน้าจำลองที่เราสร้างไว้ด้านล่าง
      routes: {
        '/details': (_) => const MockDetailPage(title: 'รายละเอียดเมนู'),
        '/bill': (_) => const MockDetailPage(title: 'หน้าตะกร้าสินค้า / Bill'),
      },
      home: const FoodMenuPage(),
    );
  }
}

// --- หน้าจำลอง (ใช้แทนไฟล์ที่เคย import) ---
class MockDetailPage extends StatelessWidget {
  final String title;
  const MockDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('กลับหน้าหลัก'),
            )
          ],
        ),
      ),
    );
  }
}

// โมเดลข้อมูลเมนู
class MenuItem {
  final String title;
  final String image;
  final String route;
  final String price;

  MenuItem({
    required this.title,
    required this.image,
    required this.route,
    this.price = "50",
  });
}

class FoodMenuPage extends StatelessWidget {
  const FoodMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ข้อมูลจำลองสำหรับแสดงผล UI
    final savoryFoods = [
      MenuItem(title: 'ข้าวมันไก่', image: 'https://images.unsplash.com/photo-1626074353765-517a681e40be?q=80&w=500', route: '/details', price: "55"),
      MenuItem(title: 'กะเพราหมู', image: 'https://images.unsplash.com/photo-1562967914-608f82629710?q=80&w=500', route: '/details', price: "60"),
      MenuItem(title: 'ราดหน้า', image: 'https://images.unsplash.com/photo-1512058560366-cd242d416fcd?q=80&w=500', route: '/details', price: "50"),
      MenuItem(title: 'ผัดไทย', image: 'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=500', route: '/details', price: "65"),
    ];

    final desserts = [
      MenuItem(title: 'บราวนี่', image: 'https://images.unsplash.com/photo-1541783245831-57d6fb0926d3?q=80&w=500', route: '/details', price: "45"),
      MenuItem(title: 'เค้กช็อกโกแลต', image: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=500', route: '/details', price: "85"),
      MenuItem(title: 'ไอศกรีม', image: 'https://images.unsplash.com/photo-1501443762994-82bd5dabb892?q=80&w=500', route: '/details', price: "35"),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 60,
            backgroundColor: const Color.fromARGB(255, 146, 220, 243).withOpacity(0.9),
            title: const Text(
              'Food Delivery UI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/bill'),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              ),
              const SizedBox(width: 10),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildHeroBanner(),
                
                _buildSectionHeader('Recommended for You'),
                _buildHorizontalList(savoryFoods),
                
                _buildSectionHeader('Delicious Desserts'),
                _buildDessertGrid(desserts),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.orange),
          SizedBox(width: 10),
          Text('Search your favorite food...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Special Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            Text('Discount up to 50%!', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('See All', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<MenuItem> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 5),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, item.route),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15, bottom: 10, top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(item.image, height: 120, width: 160, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('฿${item.price}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDessertGrid(List<MenuItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, i) => _buildModernCard(context, items[i]),
    );
  }

  Widget _buildModernCard(BuildContext context, MenuItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(item.image, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('฿${item.price}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
                      const Icon(Icons.add_circle, color: Colors.black, size: 24),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
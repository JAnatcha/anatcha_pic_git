import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ไฟล์จาก FlutterFire CLI

import 'foods/noodle_page.dart';
import 'foods/somtum_page.dart';
import 'foods/kaprao_page.dart';
import 'foods/seafood_page.dart';
import 'snacks/bingsu_page.dart';
import 'snacks/durian_cake_page.dart';
import 'snacks/kanombueng_page.dart';
import 'pages/bill_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FoodApp());
}

class FoodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Food App',
      routes: {
        '/noodle': (_) => NoodlePage(),
        '/somtum': (_) => SomTumPage(),
        '/kaprao': (_) => KapraoPage(),
        '/seafood': (_) => SeafoodPage(),
        '/bingsu': (_) => BingsuPage(),
        '/durian': (_) => DurianCakePage(),
        '/kanom': (_) => KanomBuengPage(),
      },
      home: FoodMenuPage(),
    );
  }
}

class FoodMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายการอาหาร"),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillPage()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("อาหารคาว"),
            gridMenu([
              menu("ก๋วยเตี๋ยว", "assets/food1.jpg", "/noodle"),
              menu("ส้มตำ", "assets/food2.jpg", "/somtum"),
              menu("กะเพราหมูกรอบ", "assets/food3.jpg", "/kaprao"),
              menu("ยำทะเล", "assets/food4.jpg", "/seafood"),
            ]),
            sectionTitle("อาหารหวาน"),
            gridMenu([
              menu("บิงซู", "assets/a1.jpg", "/bingsu"),
              menu("เค้กทุเรียน", "assets/a2.jpg", "/durian"),
              menu("ขนมเบื้อง", "assets/a3.jpg", "/kanom"),
            ]),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );

  Widget gridMenu(List<Widget> children) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 10),
        children: children,
      );

  Widget menu(String title, String img, String route) => GestureDetector(
        onTap: () => Navigator.pushNamed(
          navigatorKey.currentContext!,
          route,
        ),
        child: Card(
          child: Column(
            children: [
              Expanded(
                child: Image.asset(img, fit: BoxFit.cover),
              ),
              SizedBox(height: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
            ],
          ),
        ),
      );  
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';

class ImageHomePage extends StatefulWidget {
  const ImageHomePage({Key? key}) : super(key: key);

  @override
  State<ImageHomePage> createState() => _ImageHomePageState();
}

class _ImageHomePageState extends State<ImageHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.all(20),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
        children: List.generate(10, (index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context,
                  CupertinoPageRoute(builder: (_) => const ImageView()));
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(10)),
            ),
          );
        }),
      ),
    ));
  }
}

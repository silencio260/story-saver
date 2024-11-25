import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';

class ImageHomePage extends StatefulWidget {
  const ImageHomePage({Key? key}) : super(key: key);

  @override
  State<ImageHomePage> createState() => _ImageHomePageState();
}

class _ImageHomePageState extends State<ImageHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
  }

  bool _isFetched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<GetStatusProvider>(builder: (context, file, child) {
      if (_isFetched == false) {
        file.getStatus('.jpg');
        Future.delayed(const Duration(microseconds: 1), () {
          _isFetched = true;
        });
      }
      return file.isWhatsappAvailable == false
          ? const Center(
              child: Text('Whatsapp not available'),
            )
          : file.getImages.isEmpty
              ? Center(
                  child: Text("No images available"),
                )
              : Container(
                  padding: const EdgeInsets.all(20),
                  child: GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8),
                    children: List.generate(file.getImages.length, (index) {
                      final data = file.getImages[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) =>
                                      ImageView(imagePath: data.path)));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(data.path)),
                                fit: BoxFit.cover,
                              ),
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }),
                  ),
                );
    }));
  }
}

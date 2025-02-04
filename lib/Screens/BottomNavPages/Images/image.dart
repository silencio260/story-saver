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

class _ImageHomePageState extends State<ImageHomePage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Provider.of<GetStatusProvider>(context, listen: false).getStatus('.jpg');
  }

  bool _isFetched = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        body: Consumer<GetStatusProvider>(builder: (context, file, child) {
      // if (_isFetched == false) {
      //   file.getStatus('.jpg');
      //   Future.delayed(const Duration(microseconds: 1), () {
      //     _isFetched = true;
      //   });
      // }
      return file.isWhatsappAvailable == false
          ? const Center(
              child: Text('Whatsapp not available'),
            )
          : file.getImages.isEmpty
              ? Center(
                  child: Text("No images available"),
                )
              : Container(
                  padding: const EdgeInsets.all(5),
                  child: GridView(
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300, // Each item max width = 150
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    children: List.generate(file.getImages.length, (index) {
                      final data = file.getImages[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) =>
                                      ImageView(imagePath: data.path),
                              ),
                           );

                          // print('--+++--- ' +
                          //     data.toString());
                          // print(
                          //     data);
                          // print('--+++--- ' +
                          //     data.path);
                          // print(
                          //     '--+++ ' + snapshot.data.toString());
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(data.path)),
                                fit: BoxFit.cover,
                              ),
                              color: const Color.fromARGB(255, 236, 235, 230),
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      );
                    }),
                  ),
                );
    }));
  }
}

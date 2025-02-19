import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storysaver/Screens/BottomNavPages/Images/Image_view.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Widget/LocalCachedImage.dart';

class MediaListItem extends StatefulWidget {
  final String mediaPath;
  // final Future<bool> Function(String mediaPath) checkMediaSaved;

  const MediaListItem({
    Key? key,
    required this.mediaPath,
    // required this.checkMediaSaved,
  }) : super(key: key);

  @override
  _MediaListItemState createState() => _MediaListItemState();
}

class _MediaListItemState extends State<MediaListItem> {
  late bool isAlreadySaved;
  late Future<bool> _future;
  final mediaManager = SavedMediaManager();


  @override
  void initState() {
    super.initState();
    _future = mediaManager.isMediaSaved(widget.mediaPath); //widget.checkMediaSaved(widget.mediaPath);
    isAlreadySaved = false;
  }

  void _toggleSavedStatus() async {

    // Handle the click event here
    print("Icon tapped!");
    final result = await mediaManager.saveMedia(widget.mediaPath);

    // isAlreadySaved = true;
    print('Aready Saved');
    setState(() {

      isAlreadySaved = !isAlreadySaved; // Toggle the state
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: mediaManager.isMediaSaved(widget.mediaPath),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
           return Container();
         }

          if (snapshot.hasError) {
            // If there was an error, show an error widget
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          bool isAlreadySaved = snapshot.data ?? false;


         return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) =>
                      ImageView(imagePath: widget.mediaPath),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: LocalImageCache(
                    widget.mediaPath, // Cached image widget
                  ),
                ),
                Positioned(
                  // top: 10, // Adjust the position as needed
                  right: 10,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () async {

                      _toggleSavedStatus();
                    },
                    child: Container(
                      color: isAlreadySaved ? Colors.green : Colors.grey,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.download, // Replace with your desired icon
                        color: const Color.fromARGB(255, 236, 235, 230),
                        size: 20,
                      ),
                    ),

                  ),
                ),
              ],
            ),


            // Container(
            //   decoration: BoxDecoration(
            //       image: DecorationImage(
            //         image: FileImage(File(data.path)),
            //         fit: BoxFit.cover,
            //       ),
            //       color: const Color.fromARGB(
            //           255, 255, 255, 255),
            //       borderRadius: BorderRadius.circular(2)),
            // ),
          );
        }
    );




      FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text("Loading..."),
            trailing: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text("Error loading"),
          );
        } else if (snapshot.hasData) {
          isAlreadySaved = snapshot.data!; // Initialize the state
          return ListTile(
            title: Text(widget.mediaPath),
            trailing: IconButton(
              icon: Icon(
                Icons.download,
                color: isAlreadySaved
                    ? Colors.green // Change color if saved
                    : Colors.grey,
              ),
              onPressed: () {
                _toggleSavedStatus(); // Toggle and rebuild
              },
            ),
          );
        } else {
          return ListTile(
            title: Text("No data available"),
          );
        }
      },
    );
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/TopNavPages//SavedMedia/Widget/GridMediaItems.dart';
import 'package:storysaver/Utils/SavedMediaManager.dart';
import 'package:storysaver/Utils/saveStatus.dart';
import 'package:storysaver/Widget/SavedMediaPhotoViewWrapper.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SavedMediaPage extends StatefulWidget {
  const SavedMediaPage({Key? key}) : super(key: key);

  @override
  _SavedMediaPageState createState() => _SavedMediaPageState();
}

class _SavedMediaPageState extends State<SavedMediaPage> with AutomaticKeepAliveClientMixin {
  List<AssetEntity> videoAssets = [];
  bool isLoading = true;
  int reBuildCount = 0;
  final ScrollController _scrollController = ScrollController();
  final mediaManager = SavedMediaManager();

  bool _keepWidgetAlive = true;

  void toggleKeepAlive(bool value) {
    if(_keepWidgetAlive != value)
    setState(() {
      _keepWidgetAlive = value;
    });
  }

  @override
  bool get wantKeepAlive => true;


  @override
  void initState() {
    super.initState();
    // loadVideos();

    // print("SavedMediaPage initState");
  }

  Future<void> clearOldCachedFiles() async {
    final cacheDir = await getTemporaryDirectory();
    final now = DateTime.now();

    if (cacheDir.existsSync()) {
      final files = cacheDir.listSync(); // List all files in the cache directory

      for (final file in files) {
        final stat = file.statSync(); // Get file stats
        final lastModified = stat.modified; // Get last modified time

        print("temp dir $file $lastModified ${files.length}");

        print("file life ${now.difference(lastModified).inHours }");

        // Check if the file is older than 24 hours
        if (now.difference(lastModified) > const Duration(hours: 24)) {
          print("file life ${now.difference(lastModified) }");
          file.deleteSync(); // Delete the file
        }
      }
    }
  }

  String extractKeyString(Key key) {
    if (key is ValueKey<String>) {
      return key.value;
    }
    return 'Unknown Key';
  }

  int? extractNumberAsInt(String input) {
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(input);
    return match != null ? int.parse(match.group(0)!) : null;
  }

  void loadMoreItem () {
    Provider.of<GetSavedMediaProvider>(context, listen: false).loadVMediaInStaggeredBatches();
  }

  void confirmFileDeleteDialog(BuildContext context, String message, String fileName, GetSavedMediaProvider file, int index) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        // barrierDismissible: false, // Prevents user from tapping outside to dismiss
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("Cancel", style: TextStyle(color: Colors.grey),),
              ),
              TextButton(
                onPressed: () {
                  // _deleteMedia(context, file.getMediaFile[index])
                  deleteMedia(fileName, file, index);
                  Navigator.popUntil(dialogContext, (route) => route.isFirst);
                },
                child: Text("OK", style: TextStyle(color: Colors.red),),
              ),
            ],
          );
        },
      );
    });
  }

  void deleteMedia(String fileName, GetSavedMediaProvider file, int index) async {

    File? fileToDelete = await file.getMediaFile[index].file;
    String? filePath = fileToDelete?.path;
    // print('delete_path ${filePath?.path}');

    deleteSaveStatusFromDevice(context, filePath!);
    mediaManager.deleteMediaFromCache(fileName);
    file.removeFrom(index);
  }

  // void _deleteMedia(BuildContext context, AssetEntity entity){
  //   deleteSaveStatusWithPhotoManager(context, entity);
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // appBar: AppBar(title: Text("MediaStore Videos")),
      body: Consumer<GetSavedMediaProvider>(builder: (context, file, child) {
          return file.isLoading
              ? Center(child: CircularProgressIndicator())
              : file.getMediaFile.isNotEmpty
              ?
          GridView.builder(
            // key: ValueKey(file.getMediaFile.length),
            gridDelegate:
            const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300, // Each item max width = 150
              crossAxisSpacing: 5,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemCount: file.getMediaFile.length,
              itemBuilder: (BuildContext context, int index) {

                // print('GetSavedMediaProvider().getMediaFile[index] $video');

                final mediaFile = file.getMediaFile[index];


                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  key: ValueKey(file.getMediaFile[index]),
                  child: VisibilityDetector(
                    key: Key('item_$index'),
                    onVisibilityChanged: (visibilityInfo) {
                      var visiblePercentage = visibilityInfo.visibleFraction * 100;
                      String nextLoadTriggerItem = 'item_${file.nextLoadTrigger}';

                      debugPrint(
                          'Widget ${visibilityInfo.key} is ${visiblePercentage}% visible');


                      debugPrint(
                          'NextTrigger - $nextLoadTriggerItem - ${file.nextLoadTrigger} = extractKeyString key is ${extractKeyString(visibilityInfo.key)} // key = ${visibilityInfo.key}');
                      print('file.getMediaFile.length ${file.getMediaFile.length}');

                      String keyAsString = extractKeyString(visibilityInfo.key);
                      int? keyAsInt = extractNumberAsInt(keyAsString);

                      if((keyAsString == nextLoadTriggerItem && visiblePercentage >= 50) ||
                          ( keyAsInt != null && keyAsInt >= file.nextLoadTrigger) ){

                        if(file.numLoadedAssets <= file.totalNumAssets && !file.isProcessingMedia){
                          loadMoreItem();
                          file.setNewLoadTrigger();
                          print('Load More Media Files nextLoadTrigger = ${file.nextLoadTrigger} - numLoadedAssets = ${file.numLoadedAssets} ');
                        }

                      }
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 160,
                            child: GestureDetector(
                              // behavior: HitTestBehavior.opaque,
                              onTap: () {
                              // print('--------------------*******************---------------------------');

                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (_) =>
                                        SavedMediaPhotoViewWrapper(
                                            initialIndex: index,
                                            isVideoView: true,
                                            file: file,
                                            galleryItems: Provider.of<GetSavedMediaProvider>(context, listen: false).getMediaFile
                                        ),
                                ),
                              );
                          },
                          child: Container(child: SavedMediaGridItem(mediaFile: mediaFile)),
                            ),
                          ),//160),


                          GestureDetector(

                            onTap: () =>
                            {
                              // deleteSaveStatus(context, file.getMediaFile[index]),
                              print('Media Manger ${file.getMediaFile[index].title.toString()}'),

                              confirmFileDeleteDialog(
                                  context,
                                  'Are you sure you want to delete?',
                                  file.getMediaFile[index].title.toString(),
                                file,
                                index
                              ),

                              // _deleteMedia(context, file.getMediaFile[index])
                              // mediaManager.deleteMedia(file.getMediaFile[index].title.toString()),
                              // file.removeFrom(index)
                            },
                            child:  Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0), // Adjust distance
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
          )
              : Center(child: Text("No Videos Found"));
        }
      ),
    );
  }
}

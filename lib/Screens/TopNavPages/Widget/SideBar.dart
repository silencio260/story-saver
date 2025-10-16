import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';

// class SidebarXExampleApp extends StatelessWidget {
//   SidebarXExampleApp({Key? key}) : super(key: key);
//
//   final _controller = SidebarXController(selectedIndex: 0, extended: true);
//   final _key = GlobalKey<ScaffoldState>();
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SidebarX Example',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: primaryColor,
//         canvasColor: canvasColor,
//         scaffoldBackgroundColor: scaffoldBackgroundColor,
//         textTheme: const TextTheme(
//           headlineSmall: TextStyle(
//             color: Colors.white,
//             fontSize: 46,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//       home: Builder(
//         builder: (context) {
//           final isSmallScreen = MediaQuery.of(context).size.width < 600;
//           return Scaffold(
//             key: _key,
//             appBar: isSmallScreen
//                 ? AppBar(
//               backgroundColor: canvasColor,
//               title: Text(_getTitleByIndex(_controller.selectedIndex)),
//               leading: IconButton(
//                 onPressed: () {
//                   // if (!Platform.isAndroid && !Platform.isIOS) {
//                   //   _controller.setExtended(true);
//                   // }
//                   _key.currentState?.openDrawer();
//                 },
//                 icon: const Icon(Icons.menu),
//               ),
//             )
//                 : null,
//             drawer: ExampleSidebarX(controller: _controller),
//             body: Row(
//               children: [
//                 if (!isSmallScreen) ExampleSidebarX(controller: _controller),
//                 Expanded(
//                   child: Center(
//                     child: _ScreensExample(
//                       controller: _controller,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SidebarX(
        controller: _controller,
        showToggleButton: false,
        theme: SidebarXTheme(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: canvasColor,
            borderRadius: BorderRadius.circular(20),
          ),
          hoverColor: scaffoldBackgroundColor,
          textStyle:
              TextStyle(color: Colors.white.withOpacity(1), fontSize: 18),
          selectedTextStyle: const TextStyle(color: Colors.white),
          hoverTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          itemTextPadding: const EdgeInsets.only(left: 30),
          selectedItemTextPadding: const EdgeInsets.only(left: 30),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: canvasColor),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: actionColor.withOpacity(0.37),
            ),
            gradient: const LinearGradient(
              colors: [accentCanvasColor, canvasColor],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 30,
              )
            ],
          ),
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
            size: 20,
          ),
        ),
        extendedTheme: const SidebarXTheme(
          width: 280,
          decoration: BoxDecoration(
            color: canvasColor,
          ),
        ),
        // footerDivider: Divider(color: white.withOpacity(0.3), height: 1),
        footerBuilder: (context, extended) {
          return Positioned(
              top: 0,
              child: Divider(color: white.withOpacity(0.3), height: 20));
          // return Padding( padding: EdgeInsets.only(top: 250), child: Divider(color: white.withOpacity(0.3), height: 20));
        },
        footerItems: [
          SidebarXItem(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {
              debugPrint('Help tapped');
              // if (Navigator.canPop(context)) {
              //   Navigator.pop(context);
              // }
            },
          ),
          SidebarXItem(
            icon: Icons.feedback_outlined,
            label: 'Feedback',
            onTap: () {
              FeedBackHelper().showFancyRatings(context);
              debugPrint('Feedback tapped');
              // if (Navigator.canPop(context)) {
              //   Navigator.pop(context);
              // }
            },
          ),
          // divider,
          SidebarXItem(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () {
              debugPrint('About tapped');
              // if (Navigator.canPop(context)) {
              //   Navigator.pop(context);
              // }
            },
          ),
        ],
        // footerBuilder: (context, extended) {
        //   return Column();
        // },
        headerBuilder: (context, extended) {
          return Container(
            height: 60, // Adjust height as needed
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0), // Overall padding for the header
            alignment: Alignment.centerLeft, // Align content to the center-left
            child: Row(
              children: [
                // Title: "Story Saver"
                Expanded(
                  // Allows text to take available space and potentially wrap
                  child: Text(
                    'Story Saver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Adjust font size
                      fontWeight: FontWeight.w600, // Make it a bit bolder
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long text
                  ),
                ),
                // Spacer(), // Pushes the close button to the right, use if Expanded is not used for Text
                if (Navigator.canPop(
                    context)) // Only show if it can be popped (like a drawer)
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 24), // Adjusted size
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Close the drawer
                      }
                    },
                    tooltip: 'Close Drawer',
                    padding:
                        EdgeInsets.zero, // Minimal padding for the icon button
                    constraints: const BoxConstraints(), // Minimal constraints
                  ),
              ],
            ),
          );
        },

        // headerBuilder: (context, extended) {
        //   return SizedBox(
        //     height: 100,
        //     child: Padding(
        //       padding: const EdgeInsets.all(5.0),
        //       child: Image.asset('assets/images/app-logo.png'),
        //     ),
        //   );
        // },
        items: [
          SidebarXItem(
            icon: Icons.home,
            label: 'Home',
            onTap: () {
              debugPrint('Home');
            },
          ),
          const SidebarXItem(
            icon: Icons.search,
            label: 'Search',
          ),
          const SidebarXItem(
            icon: Icons.people,
            label: 'People',
          ),
          SidebarXItem(
            icon: Icons.favorite,
            label: 'Favorites',
            selectable: false,
            onTap: () => _showDisabledAlert(context),
          ),
          const SidebarXItem(
            iconWidget: FlutterLogo(size: 20),
            label: 'Flutter',
          ),
        ],
      ),
    );
  }

  void _showDisabledAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Item disabled for selecting',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _ScreensExample extends StatelessWidget {
  const _ScreensExample({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pageTitle = _getTitleByIndex(controller.selectedIndex);
        switch (controller.selectedIndex) {
          case 0:
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemBuilder: (context, index) => Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).canvasColor,
                  boxShadow: const [BoxShadow()],
                ),
              ),
            );
          default:
            return Text(
              pageTitle,
              style: theme.textTheme.headlineSmall,
            );
        }
      },
    );
  }
}

String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Home';
    case 1:
      return 'Search';
    case 2:
      return 'People';
    case 3:
      return 'Favorites';
    case 4:
      return 'Custom iconWidget';
    case 5:
      return 'Profile';
    case 6:
      return 'Settings';
    default:
      return 'Not found page';
  }
}

const primaryColor = Color(0xFF685BFF);
const canvasColor = Color(
    0xff154734); //Color(CustomColors.AppBarColor);///Color(0xA8FFFFFF);//Colors.black87;//Color(CustomColors.AppBarColor);
const scaffoldBackgroundColor = Color(0xFF464667);
const accentCanvasColor = Color(0xFF3E3E61);
const white = Colors.white;
final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);
final divider = Divider(color: white.withOpacity(0.3), height: 1);

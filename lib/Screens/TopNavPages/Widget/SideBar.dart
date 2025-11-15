import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:storysaver/Utils/checkBusinessMode.dart';
import 'package:storysaver/Widget/HelpModal.dart';
import 'package:storysaver/Widget/svgIcons.dart';
////////////////////////////////////

class AppSideBar extends StatelessWidget {
  const AppSideBar({
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
        animationDuration: Duration.zero, // Disable animation
        theme: SidebarXTheme(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          decoration: const BoxDecoration(
            color: canvasColor,
          ),
          hoverColor: Colors.white.withOpacity(0.1),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
          hoverTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
          itemTextPadding: const EdgeInsets.only(left: 20),
          selectedItemTextPadding: const EdgeInsets.only(left: 20),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.12),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 26,
          ),
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
            size: 26,
          ),
          itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          selectedItemPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        extendedTheme: const SidebarXTheme(
          width: 280,
          decoration: BoxDecoration(
            color: canvasColor,
          ),
          padding: EdgeInsets.all(0),
        ),
        headerBuilder: (context, extended) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 15.0),
                decoration: const BoxDecoration(
                  color: canvasColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Story Saver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (Navigator.canPop(context))
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 32),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              Divider(
                color: white.withOpacity(0.2),
                height: 1,
                thickness: 1,
              ),
            ],
          );
        },
        items: [
          SidebarXItem(
            // icon: Icons.calendar_today_outlined,
            // // label: 'Statuses',
            iconWidget: checkIsBusinessMode(context) == false
                ? businessWhatsAppsSvgIcon
                : whatsAppsSvgIcon,
            label: checkIsBusinessMode(context) == false
                ? 'Business Mode'
                : 'Personal Status',
            onTap: () {
              switchToBusinessMode(context);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          SidebarXItem(
            icon: Icons.workspace_premium,
            label: 'Remove Ads',
            onTap: () {
              RevenueCatService().PresentRevenueCatPayWallIfNeeded();

              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          SidebarXItem(
            icon: Icons.feedback_outlined,
            label: 'Contact Us',
            onTap: () {
              // debugPrint('Feedback tapped');

              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              Future.delayed(const Duration(milliseconds: 100), () {
                _controller.selectIndex(0); // Select first item (Statuses)
              });

              FeedBackHelper().showContactUsDialog(context);
            },
          ),
          // SidebarXItem(
          //   icon: Icons.settings_outlined,
          //   label: 'Settings',
          //   onTap: () {
          //     debugPrint('Settings');
          //     if (Navigator.canPop(context)) {
          //       Navigator.pop(context);
          //     }
          //   },
          // ),
        ],

        footerItems: [
          SidebarXItem(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {
              debugPrint('Help tapped');

              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              Future.delayed(const Duration(milliseconds: 100), () {
                _controller.selectIndex(0); // Select first item (Statuses)
              });

              HelpModal().showHelpDialog(context);
            },
          ),
          SidebarXItem(
            icon: Icons.star_border_outlined,
            label: 'Rate Us',
            onTap: () {
              debugPrint('Feedback tapped');

              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              Future.delayed(const Duration(milliseconds: 100), () {
                _controller.selectIndex(0); // Select first item (Statuses)
              });

              FeedBackHelper().showFancyRatings(context);
            },
          ),
          SidebarXItem(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              debugPrint('About tapped');

              shareAppLink(context);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              Future.delayed(const Duration(milliseconds: 100), () {
                _controller.selectIndex(0); // Select first item (Statuses)
              });
            },
          ),
          // SidebarXItem(
          //   icon: Icons.info_outline,
          //   label: 'About',
          //   onTap: () {
          //     debugPrint('About tapped');
          //     // _controller.selectIndex(0);
          //     // if (Navigator.canPop(context)) {
          //     //   Navigator.pop(context);
          //     // }
          //     Future.delayed(const Duration(milliseconds: 100), () {
          //       _controller.selectIndex(0); // Select first item (Statuses)
          //     });
          //   },
          // ),
        ],
      ),
    );
  }
}

const primaryColor = Color(0xFF685BFF);
const canvasColor = Color(0xff154734);
const scaffoldBackgroundColor = Color(0xFF464667);
const accentCanvasColor = Color(0xFF0D6E4F); // Lighter green for selection
const white = Colors.white;
final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);
final divider = Divider(color: white.withOpacity(0.3), height: 1);

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/themeProvider.dart';

// class DarkModeToggleButton extends StatelessWidget {
//   const DarkModeToggleButton({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // super.build(context);
//     return Consumer<ThemeProvider>(
//       builder: (cont, themeProvider, child) {
//         final isDarkMode = true; //themeProvider.themeMode == ThemeMode.dark;
//
//         return IconButton(
//           icon: Icon(
//             isDarkMode ? Icons.light_mode : Icons.dark_mode,
//           ),
//           onPressed: () {
//             themeProvider.toggleTheme();
//           },
//           // tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
//         );
//       },
//     );
//   }
// }

class DarkModeToggleButton extends StatelessWidget {
  const DarkModeToggleButton({Key? key}) : super(key: key);

  // ThemeMode getCurrentTheme(BuildContext context) {
  //   final theme = Provider.of<ThemeProvider>(context, listen: false).themeMode;
  //
  //   return theme;
  // }

  // bool isDarkMode (BuildContext context){
  //   final theme = Provider.of<ThemeProvider>(context, listen: false).themeMode;
  //
  //   bool isDarkMode ? Icons.light_mode : Icons.dark_mode,
  //
  //   return theme;
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

        return IconButton(
          iconSize: 11 ?? 24, // Default 24
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}
// import 'package:flutter/material.dart';
//
// class DarkModeToggleButton extends StatelessWidget {
//   const DarkModeToggleButton({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // Check current theme mode
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return IconButton(
//       icon: Icon(
//         isDarkMode ? Icons.light_mode : Icons.dark_mode,
//       ),
//       onPressed: () {
//         // Toggle theme mode
//         // This requires your app to support theme switching
//         // See implementation below
//       },
//       tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
//     );
//   }

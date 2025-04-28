import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpModal {
  void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Center(
            child: Text(
              'Help',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              helpBullet('Go to Whatsapp or Whatsapp Business and watch any status.'),
              SizedBox(height: 8),
              helpBullet('Come back to story saver app. Choose Photo or Video Status to download.'),
              // SizedBox(height: 8),
              // helpBullet('Click on save button to save or choose another option for Share and Repost.'),
              SizedBox(height: 8),
              helpBullet('You can check your saved status in last tab (Gallery).'),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.teal)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget helpBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(fontSize: 20)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}



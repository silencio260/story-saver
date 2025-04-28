import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';

class LoadStatusUtils {
  Widget TextWithStatusRefresh({
    required BuildContext context,
    String text = ''}) {

    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 16), // base style
          children: [
            TextSpan(text: '$text. '),
            TextSpan(
              text: 'Click to refresh',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // handle tap here
                  Provider.of<GetStatusProvider>(context, listen: false).getAllStatusesWithSaf();
                },
            ),
          ],
        ),
      ),
    );

    // return GestureDetector(
    //   onTap: () {
    //
    //   },
    //   child: Center(
    //     child: Text(text),
    //   ),
    // );
  }
}
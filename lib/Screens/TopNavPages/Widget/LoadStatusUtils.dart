import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';

class LoadStatusUtils {
  Widget TextWithStatusRefresh({
    required BuildContext context,
    String text = ''}) {

    return GestureDetector(
      onTap: () {
        Provider.of<GetStatusProvider>(context, listen: false).getStatusWithSaf();
      },
      child: Center(
        child: Text(text),
      ),
    );
  }
}
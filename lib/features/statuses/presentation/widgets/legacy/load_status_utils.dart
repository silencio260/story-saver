import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/status_bloc/status_bloc.dart';

class LoadStatusUtils {
  Widget TextWithStatusRefresh({
    required BuildContext context,
    String text = '',
  }) => Center(
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: <InlineSpan>[
          TextSpan(text: '$text. '),
          TextSpan(
            text: 'Click to refresh',
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap =
                      () => context.read<StatusBloc>().add(
                        const StatusLoadRequested(),
                      ),
          ),
        ],
      ),
    ),
  );
}

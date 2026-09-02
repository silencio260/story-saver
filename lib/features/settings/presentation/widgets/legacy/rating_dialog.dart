import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({Key? key}) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
          margin: EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Enjoying the app?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 15),
              Text(
                "Tap a star to rate it on the App Store.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.green,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        RatingDialogResponse(
                          rating: _rating,
                          action: RatingAction.never,
                        ),
                      );
                    },
                    child: Text(
                      "Never",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withOpacity(0.4),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        RatingDialogResponse(
                          rating: _rating,
                          action: RatingAction.maybeLater,
                        ),
                      );
                    },
                    child: Text(
                      "Maybe Later",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _rating > 0
                            ? () {
                              Navigator.of(context).pop(
                                RatingDialogResponse(
                                  rating: _rating,
                                  action: RatingAction.continue_,
                                ),
                              );
                            }
                            : null,
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 14,
                        color: _rating > 0 ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum RatingAction { maybeLater, never, continue_ }

class RatingDialogResponse {
  final int rating;
  final RatingAction action;

  RatingDialogResponse({required this.rating, required this.action});
}

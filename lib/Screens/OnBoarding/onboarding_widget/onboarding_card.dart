

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingCard extends StatelessWidget {
  final String image, title, description, buttonText;
  final Function onPressed;

  const OnboardingCard({
    Key? key,
    required this.image,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.80,
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: EdgeInsets.all(50),
              child: Image.asset(image, fit: BoxFit.contain,),
          ),
          Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                 description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

            ],
          ),
          MaterialButton(
            minWidth: 300,
            onPressed: () => onPressed(),
            color: Theme.of(context).colorScheme.primary,
            child: Text(
              buttonText,
              style: TextStyle(
                color: Colors.white
              ),
            ),
          )
        ],
      ),
    );
  }
}

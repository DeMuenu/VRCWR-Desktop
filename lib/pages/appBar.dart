

import 'package:flutter/material.dart';

Widget appBar() {
    return Container(
      decoration: BoxDecoration(color: const Color.fromARGB(255, 47, 47, 47)),
      width: 90,
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 10,),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 120,
              child: Material(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("Worlds clicked");
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Worlds", textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 10,),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 120,
              child: Material(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("Vote clicked");
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Vote", textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
        ],),
    );
  }
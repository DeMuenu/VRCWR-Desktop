
import 'package:flutter/material.dart';
import 'package:VRCWR/backend/vrchatApiHandler.dart';

class Template extends StatefulWidget {
  final VrchatApiHandler vrcApi;


  const Template(this.vrcApi, {super.key});

  @override
  State<Template> createState() => _TemplateState();
}


class _TemplateState extends State<Template> {
  late VrchatApiHandler vrcApi;

  @override
  void initState(){
    super.initState();
    vrcApi = widget.vrcApi;

  }


  @override
  Widget build(BuildContext context) {
    return Container(color: const Color.fromARGB(255, 20, 20, 20),
        child:
          Center(child: 
            Column(
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: CircularProgressIndicator(year2023: true),
                ),
              ]
            ),
        )
    );
  }

}
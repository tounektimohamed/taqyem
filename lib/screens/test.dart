import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dynamic Input Boxes'),
        ),
        body: DynamicInputList(),
      ),
    );
  }
}

class DynamicInputList extends StatefulWidget {
  @override
  _DynamicInputListState createState() => _DynamicInputListState();
}

class _DynamicInputListState extends State<DynamicInputList> {
  List<Widget> inputBoxes = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: inputBoxes.length,
            itemBuilder: (context, index) {
              return inputBoxes[index];
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              inputBoxes.add(InputBox());
            });
          },
          child: Icon(Icons.add),
        ),
        Text('Number of Boxes: ${inputBoxes.length}'),
      ],
    );
  }
}

class InputBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Enter something',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}




// DropdownMenu(
//                       controller: _genderController,
//                       textStyle: GoogleFonts.roboto(
//                         height: 2,
//                         color: const Color.fromARGB(255, 16, 15, 15),
//                       ),
//                       width: MediaQuery.of(context).size.width * 0.82,
//                       menuStyle: const MenuStyle(
//                         shape: MaterialStatePropertyAll(
//                           RoundedRectangleBorder(
//                             borderRadius: BorderRadius.all(
//                               Radius.circular(20),
//                             ),
//                           ),
//                         ),
//                       ),
//                       inputDecorationTheme: const InputDecorationTheme(
//                         filled: true,
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.all(
//                             Radius.circular(
//                               20,
//                             ),
//                           ),
//                           borderSide: BorderSide(
//                             color: Color.fromARGB(255, 7, 82, 96),
//                           ),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.all(
//                             Radius.circular(
//                               20,
//                             ),
//                           ),
//                           borderSide: BorderSide(
//                             color: Colors.transparent,
//                           ),
//                         ),
//                       ),
//                       dropdownMenuEntries: const [
//                         DropdownMenuEntry(value: 'Male', label: 'Male'),
//                         DropdownMenuEntry(value: 'Female', label: 'Female'),
//                         DropdownMenuEntry(value: 'Other', label: 'Other'),
//                       ],
//                       label: const Text('Gender'),
//                     ),
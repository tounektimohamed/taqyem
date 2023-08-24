import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:flutter/material.dart';
import 'package:weekday_selector/weekday_selector.dart';

class AddMediFrequency extends StatefulWidget {
  const AddMediFrequency({Key? key}) : super(key: key);

  @override
  _AddMediFrequencyState createState() => _AddMediFrequencyState();
}

List<bool> values = List.filled(7, false);
bool showMessage = false; // Initially hidden
Key gifKey = UniqueKey(); // Key for the Image widget

class _AddMediFrequencyState extends State<AddMediFrequency> {
  final _formKey = GlobalKey<FormState>();
  final _medicationTimeOfDayController = TextEditingController();

  bool showFrequencySection = false;
  bool showDaysSection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Frequency',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          padding: const EdgeInsets.only(left: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          showMessage = true;
                          gifKey = UniqueKey(); // Generate a new key
                          Future.delayed(Duration(seconds: 2), () {
                            setState(() {
                              showMessage = false;
                            });
                            Navigator.pop(context);
                          });
                        });
                      }
                    },
                    child: Text('Done'),
                  ),
                ],
              ),
              CustomRadioButton(
                elevation: 4,
                unSelectedColor: Theme.of(context).canvasColor,
                buttonLables: [
                  'At Regular Intervals',
                  'On Specific Days of the Week',
                ],
                buttonValues: [
                  "At Regular Intervals",
                  "On Specific Days of the Week",
                ],
                buttonTextStyle: ButtonTextStyle(
                    selectedColor: Colors.white,
                    unSelectedColor: Colors.black,
                    textStyle: TextStyle(fontSize: 16)),
                radioButtonValue: (value) {
                  setState(() {
                    showFrequencySection = value == "At Regular Intervals";
                    showDaysSection = value == "On Specific Days of the Week";
                  });
                },
                selectedColor: Theme.of(context).colorScheme.secondary,
                unSelectedBorderColor: Theme.of(context).colorScheme.secondary,
                selectedBorderColor: Theme.of(context).colorScheme.secondary,
                padding: 5,
                height: 50,
                width: 150,
                enableShape: true,
                enableButtonWrap: true,
                wrapAlignment: WrapAlignment.center,
                horizontal: true,
              ),
              if (showFrequencySection) ...[
                SizedBox(height: 16),
                Text(
                  'Select the Frequency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  onTap: () async {},
                  controller: _medicationTimeOfDayController,
                  readOnly: true,
                  style: TextStyle(
                    height: 2,
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  cursorColor: const Color.fromARGB(255, 7, 82, 96),
                  decoration: InputDecoration(
                    hintText: 'Choose from the list',
                    labelText: 'Select the Frequency',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 16, 15, 15),
                    ),
                    filled: true,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 7, 82, 96),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
              if (showDaysSection) ...[
                SizedBox(height: 16),
                Text(
                  'Select the Days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                ),
                SizedBox(height: 16),
                WeekdaySelector(
                  onChanged: (int day) {
                    setState(() {
                      values[day % 7] = !values[day % 7];
                    });
                  },
                  values: values,
                ),
              ],
              SizedBox(height: 50),
              if (showMessage)
                Column(
                  children: [
                    Visibility(
                      visible: showMessage,
                      child: TextFormField(
                        initialValue: "Saved Successfully",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: Duration(seconds: 3),
                      child: Image.asset(
                        'lib/assets/images/done.gif', // Change this path to your actual GIF image
                        key: gifKey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: AddMediFrequency(),
//   ));
// }

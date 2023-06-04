import 'dart:async';
import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/medicine.dart';
import 'medicine_details.dart';

class EXtendedSection extends StatefulWidget {
  const EXtendedSection({Key? key, required this.medicine}) : super(key: key);

  final Medicine medicine;

  @override
  _EXtendedSectionState createState() => _EXtendedSectionState();
}

class _EXtendedSectionState extends State<EXtendedSection> {
  String _medicineState = '';
  double _medicineTemp=0.0;
  @override
  void initState() {
    super.initState();
    initializeFirebase(); // Initialize Firebase
    _listenToDataChanges();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  void _listenToDataChanges() {
    print('listen');
    String _medicineName =widget.medicine.medicineName.toString();
    DatabaseReference databaseReference = FirebaseDatabase.instance.reference().child('medicine_entry/$_medicineName');
    databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        var data = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        setState(() {
          _medicineState = data['state'].toString();
          _medicineTemp = data['temp'].toDouble();
        });

        print(_medicineTemp);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ExtendedInfoTab(
          fieldTitle: 'Medicine Type',
          fieldInfo: widget.medicine.medicineType == 'none' ? 'Not specified' : widget.medicine.medicineType.toString(),
        ),
        ExtendedInfoTab(
          fieldTitle: 'Dose Interval',
          fieldInfo:
          'Every ${widget.medicine.interval?.toString() ?? '0'} hours | ${widget.medicine.interval == 24 ? "" : "${(24 / (widget.medicine.interval ?? 1)).floor()}"} times a day',
        ),
        ExtendedInfoTab(
          fieldTitle: 'Start Time',
          fieldInfo: widget.medicine.startTime.toString(),
        ),
        ExtendedInfoTab(
          fieldTitle: 'State',
          fieldInfo: _medicineState,
        ),
        ExtendedInfoTab(
          fieldTitle: 'Temperature',
          fieldInfo: _medicineTemp.toString(),
        ),
      ],
    );
  }
}

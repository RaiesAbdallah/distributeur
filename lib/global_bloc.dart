import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/medicine.dart';

class GlobalBloc {
  BehaviorSubject<List<Medicine>>? _medicineList$;
  BehaviorSubject<List<Medicine>>? get medicineList$ => _medicineList$;

  GlobalBloc() {
    _medicineList$ = BehaviorSubject<List<Medicine>>.seeded([]);
    makeMedicineList();
  }

  void saveDataToFirebase(String key, dynamic value) {
    final databaseRef = FirebaseDatabase.instance.ref().child("medicines");
    databaseRef.child(key).set(value).then((_) {}).catchError((error) {
      print('Failed to save data: $error');
    });
  }

  Future removeMedicine(Medicine tobeRemoved) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    SharedPreferences sharedUser = await SharedPreferences.getInstance();
    List<String> medicineJsonList = [];
    var blockList = _medicineList$!.value;
    blockList.removeWhere(
        (medicine) => medicine.medicineName == tobeRemoved.medicineName);

    for (int i = 0; i < (24 / tobeRemoved.interval!).floor(); i++) {
      flutterLocalNotificationsPlugin
          .cancel(int.parse(tobeRemoved.notificationIDs![i]));
    }
    if (blockList.isNotEmpty) {
      for (var blockMedicine in blockList) {
        String medicineJson = jsonEncode(blockMedicine.toJson());
        medicineJsonList.add(medicineJson);
      }
    }
    sharedUser.setStringList('medicine', medicineJsonList);
    _medicineList$!.add(blockList);
  }

  Future updateMedicineList(Medicine newMedicine) async {
    saveDataToFirebase(
        UniqueKey()
            .toString()
            .replaceAll("#", "")
            .replaceAll("[", "")
            .replaceAll("]", ""),
        newMedicine.toJson());
    var blocList = _medicineList$!.value;
    blocList.add(newMedicine);
    _medicineList$!.add(blocList);
  }

  Future makeMedicineList() async {
    _medicineList$!.close();
    DatabaseReference ref = FirebaseDatabase.instance.ref('medicines');
    List<Medicine> prefList = [];

    try {
      ref.onValue.listen((event) {
        var data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          Medicine tempMedicine = Medicine(
              dosage: value['dosage'],
              interval: value['interval'],
              medicineName: value['name'],
              medicineType: value['type'],
              notificationIDs: value['ids'],
              startTime: value['start']);
          prefList.add(tempMedicine);
        });
      });
      _medicineList$!.add(prefList);
    } catch (e) {
      print('Error retrieving data: $e');
    }
  }

  void dispose() {
    _medicineList$!.close();
  }
}

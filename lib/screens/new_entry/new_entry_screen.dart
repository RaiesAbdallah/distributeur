import 'dart:math';
import 'package:reminder/global_bloc.dart';
import 'package:reminder/models/errors.dart';
import 'package:reminder/models/medicine.dart';
import 'package:reminder/screens/constants.dart';
import 'package:reminder/screens/home_screen.dart';
import 'package:reminder/screens/new_entry/new_entry_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../common/convert_time.dart';
import '../../models/medicine_types.dart';
import 'package:firebase_database/firebase_database.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({Key? key}) : super(key: key);

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  late TextEditingController nameController;
  late TextEditingController dosageController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late NewEntryBloc _newEntryBloc;
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    dosageController.dispose();
    _newEntryBloc.dispose();
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    dosageController = TextEditingController();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _newEntryBloc = NewEntryBloc();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    initializeNotifications();
    initializeErrorListen();
  }

  void saveData(String key, Map<String, dynamic> data) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child(key).set(data);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalBloc globalBloc = Provider.of<GlobalBloc>(context);
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Add New'),
        ),
        body: Provider<NewEntryBloc>.value(
          value: _newEntryBloc,
          child: Padding(
            padding: EdgeInsets.all(2.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle(
                    title: 'Medicine Name',
                    isRequired: true,
                  ),
                  TextFormField(
                    maxLength: 12,
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: kPrimaryColor),
                  ),
                  const PanelTitle(
                    title: 'Dosage In mg',
                    isRequired: false,
                  ),
                  TextFormField(
                    maxLength: 12,
                    controller: dosageController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: kPrimaryColor),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  const PanelTitle(title: 'Medicine Type', isRequired: false),
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: StreamBuilder<MedicineType>(
                      stream: _newEntryBloc.selectedMedicineType,
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MedicineTypeColumn(
                                medicineType: MedicineType.Bottle,
                                name: 'Bottle',
                                iconValue: 'assets/icons/bottle (3).svg',
                                isSelected: snapshot.data == MedicineType.Bottle
                                    ? true
                                    : false),
                            MedicineTypeColumn(
                                medicineType: MedicineType.Pill,
                                name: 'Pill',
                                iconValue: 'assets/icons/pill.svg',
                                isSelected: snapshot.data == MedicineType.Pill
                                    ? true
                                    : false),
                            MedicineTypeColumn(
                                medicineType: MedicineType.Syringe,
                                name: 'Syringe',
                                iconValue: 'assets/icons/syringe.svg',
                                isSelected:
                                    snapshot.data == MedicineType.Syringe
                                        ? true
                                        : false),
                            MedicineTypeColumn(
                                medicineType: MedicineType.Tablet,
                                name: 'Tablet',
                                iconValue: 'assets/icons/tablet.svg',
                                isSelected: snapshot.data == MedicineType.Tablet
                                    ? true
                                    : false),
                          ],
                        );
                      },
                    ),
                  ),
                  const PanelTitle(
                      title: 'Interval Selection', isRequired: true),
                  const IntervalSelection(),
                  const PanelTitle(title: 'Starting Time', isRequired: true),
                  const SelectTime(),
                  SizedBox(
                    height: 2.h,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 8.w,
                      right: 8.w,
                    ),
                    child: SizedBox(
                      width: 80.w,
                      height: 8.h,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: const StadiumBorder(),
                        ),
                        child: Center(
                          child: Text(
                            'Confirm',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  color: kScaffoldColor,
                                ),
                          ),
                        ),
                        onPressed: () {
                          String? medicineName;
                          int? dosage;
                          if (nameController.text == "") {
                            _newEntryBloc.submitError(EntryError.nameNull);
                            return;
                          }
                          if (nameController.text != "") {
                            medicineName = nameController.text;
                          }
                          if (dosageController.text == "") {
                            dosage = 0;
                          }
                          if (dosageController.text != "") {
                            dosage = int.parse(dosageController.text);
                          }
                          for (var medicine
                              in globalBloc.medicineList$!.value) {
                            if (medicineName == medicine.medicineName) {
                              _newEntryBloc
                                  .submitError(EntryError.nameDuplicate);
                              return;
                            }
                          }

                          if (_newEntryBloc.selectIntervals!.value == 0) {
                            _newEntryBloc.submitError(EntryError.interval);
                            return;
                          }
                          if (_newEntryBloc.selectedTimeOfDay$!.value ==
                              'none') {
                            _newEntryBloc.submitError(EntryError.startTime);
                            return;
                          }

                          String medicineType = _newEntryBloc
                              .selectedMedicineType!.value
                              .toString()
                              .substring(13);

                          int interval = _newEntryBloc.selectIntervals!.value;
                          String startTime =
                              _newEntryBloc.selectedTimeOfDay$!.value;

                          List<int> intIDs = makeIDS(
                              24 / _newEntryBloc.selectIntervals!.value);

                          List<String> notificationIDs =
                              intIDs.map((i) => i.toString()).toList();

                          Medicine newEntryMedicine = Medicine(
                            notificationIDs: notificationIDs,
                            medicineName: medicineName,
                            dosage: dosage,
                            medicineType: medicineType,
                            interval: interval,
                            startTime: startTime,
                          );
                          globalBloc.updateMedicineList(newEntryMedicine);
                          scheduleNotification(newEntryMedicine);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              content: Row(children: const [
                                Icon(
                                  Icons.verified_user_sharp,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Success adding medicine to database',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ])));


                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()));
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  void initializeErrorListen() {
    _newEntryBloc.errorState$!.listen((EntryError error) {
      switch (error) {
        case EntryError.nameNull:
          displayError("Please enter the medicine's name");
          break;

        case EntryError.nameDuplicate:
          displayError("Medicine name already exist");
          break;

        case EntryError.dosage:
          displayError("Please enter the dosage required");
          break;
        case EntryError.interval:
          displayError("Please select the reminder's interval");
          break;
        // case EntryError.startTime:
        //displayError("Please select the reminder's starting time");
        // break;
        default:
      }
    });
  }

  void displayError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kOtherColor,
        content: Text(error),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  List<int> makeIDS(double n) {
    var rng = Random();
    List<int> ids = [];
    for (int i = 0; i < n; i++) {
      ids.add(rng.nextInt(1000000000));
    }
    return ids;
  }

  initializeNotifications() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/launcher_icon');
    var initializationSettingsIOS = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future onSelectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    var hour = int.parse(medicine.startTime![0] + medicine.startTime![1]);
    var ogValue = hour;
    var minute = int.parse(medicine.startTime![3] + medicine.startTime![4]);

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'repeatDAilyAtTime channel id', 'repeatDAilyAtTime channel name',
        importance: Importance.max,
        ledColor: kOtherColor,
        ledOffMs: 1000,
        ledOnMs: 1000,
        enableLights: true);

    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    for (int i = 0; i < (24 / medicine.interval!).floor(); i++) {
      if (hour + (medicine.interval! * i) > 23) {
        hour = hour + (medicine.interval! * i) - 24;
      } else {
        hour = hour + (medicine.interval! * i);
      }
      await flutterLocalNotificationsPlugin.showDailyAtTime(
          int.parse(medicine.notificationIDs![i]),
          'Reminder:${medicine.medicineName}',
          medicine.medicineType.toString() != MedicineType.None.toString()
              ? 'it is time to take ur ${medicine.medicineType!.toLowerCase()}, according to schedule'
              : 'it is time to take ur medicine, according to schedule ',
          Time(hour, minute, 0),
          platformChannelSpecifics);
      hour = ogValue;
    }
  }
}

class SelectTime extends StatefulWidget {
  const SelectTime({Key? key}) : super(key: key);

  @override
  State<SelectTime> createState() => _SelectTimeState();
}

class _SelectTimeState extends State<SelectTime> {
  TimeOfDay _time = const TimeOfDay(hour: 0, minute: 00);
  bool _clicked = false;

  Future<TimeOfDay> _selectTime() async {
    final NewEntryBloc newEntryBloc =
        Provider.of<NewEntryBloc>(context, listen: false);

    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
        _clicked = true;
        newEntryBloc.updateTime(
            "${convertTime(_time.hour.toString())}:${convertTime(_time.minute.toString())}");
      });
    }
    return picked!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8.h,
      child: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: kPrimaryColor, shape: const StadiumBorder()),
          onPressed: () {
            _selectTime();
          },
          child: Center(
            child: Text(
              _clicked == false
                  ? 'Select Time'
                  : "${convertTime(_time.hour.toString())}:${convertTime(_time.minute.toString())}",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: kScaffoldColor),
            ),
          ),
        ),
      ),
    );
  }
}

class IntervalSelection extends StatefulWidget {
  const IntervalSelection({Key? key}) : super(key: key);

  @override
  State<IntervalSelection> createState() => _IntervalSelectionState();
}

class _IntervalSelectionState extends State<IntervalSelection> {
  final _intervals = [6, 8, 12, 24];
  var _selected = 0;
  @override
  Widget build(BuildContext context) {
    final NewEntryBloc newEntryBloc = Provider.of<NewEntryBloc>(context);
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Remind Me Every',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kTextColor,
                ),
          ),
          DropdownButton(
            iconEnabledColor: kOtherColor,
            dropdownColor: kScaffoldColor,
            itemHeight: 8.h,
            hint: _selected == 0
                ? Text(
                    'Select An Interval',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kPrimaryColor,
                        ),
                  )
                : null,
            elevation: 4,
            value: _selected == 0 ? null : _selected,
            items: _intervals.map(
              (int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kSecondaryColor,
                        ),
                  ),
                );
              },
            ).toList(),
            onChanged: (newVal) {
              setState(
                () {
                  _selected = newVal! as int;
                  newEntryBloc.updateInterval(newVal as int);
                },
              );
            },
          ),
          Text(
            _selected == 1 ? "hour" : "hours",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kTextColor,
                ),
          ),
        ],
      ),
    );
  }
}

class MedicineTypeColumn extends StatelessWidget {
  const MedicineTypeColumn(
      {Key? key,
      required this.medicineType,
      required this.name,
      required this.iconValue,
      required this.isSelected})
      : super(key: key);
  final MedicineType medicineType;
  final String name;
  final String iconValue;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    final NewEntryBloc newEntryBloc = Provider.of<NewEntryBloc>(context);
    return GestureDetector(
      onTap: () {
        newEntryBloc.updateSelectedMedicine(medicineType);
      },
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 10.h,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.h),
                color: isSelected ? kOtherColor : Colors.white),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 1.h,
                  bottom: 1.h,
                ),
                child: SvgPicture.asset(
                  iconValue,
                  height: 7.h,
                  color: isSelected ? Colors.white : kOtherColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Container(
              alignment: Alignment.center,
              width: 20.w,
              decoration: BoxDecoration(
                color: isSelected ? kOtherColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                  child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: isSelected ? Colors.white : kOtherColor,
                    ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelTitle extends StatelessWidget {
  const PanelTitle({Key? key, required this.title, required this.isRequired})
      : super(key: key);
  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: title,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: kTextColor),
            ),
            TextSpan(
                text: isRequired ? "*" : "",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kPrimaryColor,
                    ))
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_database/firebase_database.dart';

class ApiProvider {
final databaseReference = FirebaseDatabase.instance.ref().child('medicines');

 void getData() {
  databaseReference.once().then((data) {
    print(data.snapshot.value);
  });
}
}
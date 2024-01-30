import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

final CollectionReference busCollection =
    FirebaseFirestore.instance.collection('TrackBus');

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus Crowd Tracker'),
      ),
      body: RealTimeDataTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class RealTimeDataTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: busCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return Text('No data available.');
          }

          return DataTable(
            columns: <DataColumn>[
              DataColumn(label: Text('Bus Name')),
              DataColumn(label: Text('Passengers Count')),
            ],
            rows: data.map(
              (doc) {
                final docData = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(doc.id)), // Document name is the bus name
                    DataCell(Text(docData['PassengersCount']
                        .toString())), // Passenger count field
                  ],
                );
              },
            ).toList(),
          );
        }
      },
    );
  }
}

class UploadPage extends StatelessWidget {
  final busNameController = TextEditingController();
  final passengersCountController = TextEditingController();

  void uploadData(BuildContext context) {
    String busName = busNameController.text;
    String passengersCount = passengersCountController.text;

    if (busName.isEmpty || passengersCount.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in all fields.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    busCollection.doc(busName).set({
      'PassengersCount': int.parse(passengersCount),
    });

    busNameController.clear();
    passengersCountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: busNameController,
              decoration: InputDecoration(labelText: 'Bus Name'),
            ),
            TextField(
              controller: passengersCountController,
              decoration: InputDecoration(labelText: 'Passengers Count'),
            ),
            ElevatedButton(
              onPressed: () => uploadData(context),
              child: Text('Upload Data'),
            ),
          ],
        ),
      ),
    );
  }
}

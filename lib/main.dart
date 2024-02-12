import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

// void main() {
//   String rawJson = '{"name":"Mary","phoneNumber": "7029833335"}';
//
//   Map<String, dynamic> map = jsonDecode(rawJson); // import 'dart:convert';
//
//   String name = map['name'];
//   String phoneNumber = map['phoneNumber'];
//
//   Contact person = Contact(name: name, phoneNumber: phoneNumber);
//   print("Person name: $name, Phone number: $phoneNumber");
// }

bool dbIsInitialized = false;

class Contact {
  String name;
  String phoneNumber;
  Contact({ required this.name, required this.phoneNumber });

  // named constructor
  Contact.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        phoneNumber = json['phoneNumber'];

  // method
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

}

final storage = FlutterSecureStorage();
class ContactItem extends StatelessWidget {
  ContactItem({required this.contact, required this.removeContact}) : super(key: ObjectKey(contact));

  final Contact contact;
  final Function removeContact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      title: Row(children: <Widget>[
        Expanded(
          child: Text(contact.name),
          // child: Column(
          //   children: [
          //     Text(contact.name),
          //     Text(contact.phoneNumber)
          //   ]
          // )
        ),
        IconButton(
          iconSize: 30,
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          alignment: Alignment.centerRight,
          onPressed: () {
            removeContact(contact);
          },
        ),
      ]),
    );
  }
}


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GroupMessageApp());
}

class GroupMessageApp extends StatelessWidget {
  const GroupMessageApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GroupList(title: 'Group List'),
    );
  }
}

class GroupList extends StatefulWidget {
  const GroupList({super.key, required this.title});
  final String title;

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  final List<Contact> _contacts = <Contact>[];
  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _phoneNumberFieldController = TextEditingController();
  final TextEditingController _sendGroupMessageFieldController = TextEditingController();

  void _readAllContacts() async {
    Map<String, String> allValues = await storage.readAll();

    for (var v in allValues.values) {
      print(v);
      Map<String, dynamic> jsonString = jsonDecode(v);
      final Contact contact = Contact(name: jsonString['name'], phoneNumber: jsonString['phoneNumber']);
      _contacts.add(contact);
    }
  }

  void _deleteContact(Contact contact) async {
    var key = '${contact.name}${contact.phoneNumber}';
    await storage.delete(key: key);

    setState(() {
      _contacts.removeWhere((element) => element.name == contact.name);
    });
  }

  void _sendFlutterSMSMessage(String phoneNumber, String message) async {
    await Permission.sms.request();
    List<String> recipients = [phoneNumber];
    String result = await sendSMS(message: message, recipients: recipients, sendDirect: true)
        .catchError((onError) {
      print(onError);
      return onError;
    });
    print("Done sending SMS");
    print(result);
  }

  void _sendGroupMessage(String message) async {
    for (var contact in _contacts) {
      print('Sending message ($message) for ${contact.phoneNumber}');
      _sendFlutterSMSMessage(contact.phoneNumber, message);
    }
    _sendGroupMessageFieldController.clear();
  }

  void _addContact(String name, String phoneNumber) async {
    Contact contact = Contact(name: name, phoneNumber: phoneNumber);
    // Write value
    await storage.write(key: '$name$phoneNumber', value: jsonEncode(contact));
    setState(() {
      _contacts.add(contact);
    });
    _nameFieldController.clear();
    _phoneNumberFieldController.clear();
  }

  Future<void> _displaySendMessageDialog() {
    print("clicked send message");
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send group message'),
          content: Column(
            children: [
              TextField(
                controller: _sendGroupMessageFieldController,
                decoration: const InputDecoration(hintText: 'Group Message'),
                autofocus: true,
              ),
            ]
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _sendGroupMessage(_sendGroupMessageFieldController.text);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _displayAddContactDialog() {
    print("clicked add contact");
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a contact'),
          content: Column(
            children: [
              TextField(
                controller: _nameFieldController,
                decoration: const InputDecoration(hintText: 'Name'),
                autofocus: true,
              ),
              TextField(
                controller: _phoneNumberFieldController,
                decoration: const InputDecoration(hintText: 'Phone Number'),
                autofocus: true,
              ),
            ]
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _addContact(_nameFieldController.text, _phoneNumberFieldController.text);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (!dbIsInitialized) {
      _readAllContacts();
      dbIsInitialized = true;
    }
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          Column(
            children: [
              SingleChildScrollView(
                  physics: const ScrollPhysics(),
                  child: Column(
                    children: [
                      for (var contact in _contacts) ContactItem(contact: contact, removeContact: _deleteContact),
                    ]
                  )
              ),
            ]
          )
        ]
      ),
      bottomNavigationBar: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _displaySendMessageDialog(),
              child: const Icon(Icons.message),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _displayAddContactDialog(),
              child: const Icon(Icons.add),
            ),
          ),
        ]
      ),
    );
  }
}

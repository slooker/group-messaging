import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';

class Contact {
  Contact({ required this.name, required this.phoneNumber });
  String name;
  String phoneNumber;
}

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GroupList(title: 'Group List'),
    );
  }
}

class GroupList extends StatefulWidget {
  const GroupList({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  final List<Contact> _contacts = <Contact>[
    Contact(name: 'Tisha', phoneNumber: '7025094335'),
    Contact(name: 'Maria', phoneNumber: '4233585595'),
    Contact(name: 'Ray', phoneNumber: '4238337481'),
  ];
  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _phoneNumberFieldController = TextEditingController();
  final TextEditingController _sendGroupMessageFieldController = TextEditingController();

  void _deleteContact(Contact contact) {
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
      print('Sending message (${message}) for ${contact.phoneNumber}');
      _sendFlutterSMSMessage(contact.phoneNumber, message);
    }
    _sendGroupMessageFieldController.clear();
  }

  void _addContact(String name, String phoneNumber) {
    setState(() {
      _contacts.add(Contact(name: name, phoneNumber: phoneNumber));
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
          content: Container(
              child: Column(
                  children: [
                    TextField(
                      controller: _sendGroupMessageFieldController,
                      decoration: const InputDecoration(hintText: 'Group Message'),
                      autofocus: true,
                    ),
                  ]
              )
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
          content: Container(
            child: Column(
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
            )
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
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _displaySendMessageDialog(),
              child: const Icon(Icons.message),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
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

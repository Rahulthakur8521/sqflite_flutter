import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_handler.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  TextEditingController name = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();

  File? _image;
  Future getImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('SQLITE OPERATION'),
      ),
      drawer: Drawer(),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Center(
              child: Card(
                margin: EdgeInsets.all(10.0),
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: getImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _image != null ? FileImage(_image!)  : null,
                        ),
                      ),
                      SizedBox(height: 10,),
                      TextField(
                        controller: name,
                        decoration: InputDecoration(
                          labelText: "Name",
                          prefixIcon: Icon(Icons.person),
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: title,
                        decoration: InputDecoration(
                          labelText: "Title",
                          prefixIcon: Icon(Icons.title),
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: description,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.description),
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent, width: 2.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 30,),
                      ElevatedButton(
                        onPressed: () async {
                          String nameValue = name.text;
                          String titleValue = title.text;
                          String descriptionValue = description.text;
                          String imagePath = _image != null ? _image!.path : '';

                          if(imagePath.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your image.'),
                              ),
                            );
                          }else if(nameValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your name.'),
                              ),
                            );
                          } else if (titleValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your title.'),
                              ),
                            );
                          } else if (descriptionValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your description.'),
                              ),
                            );
                          } else {
                            await DatabaseHelper().insertData(
                                nameValue, titleValue, descriptionValue,
                                imagePath);

                            List<Map<String,
                                dynamic>> dataList = await DatabaseHelper()
                                .getData();
                            print(dataList);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayData(),));
                            name.clear();
                            title.clear();
                            description.clear();
                            _image = null;
                          };
                          },
                        style: ElevatedButton.styleFrom(
                          // primary: Colors.greenAccent,
                          // onPrimary: Colors.pink,
                          minimumSize: Size(270, 60),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            children: [
                              Text(
                                "Add Data",
                                style: TextStyle (fontSize: 15,color: Colors.blue),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'my_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE my_table(id INTEGER PRIMARY KEY, name TEXT, title TEXT, description TEXT, image_path TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertData(String name, String title, String description, String imagePath) async {
    final Database db = await database;

    int id = await db.insert(
      'my_table',
      {
        'name': name,
        'title': title,
        'description': description,
        'image_path': imagePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Inserted id: $id');
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final Database db = await database;

    return db.query('my_table');
    }
}
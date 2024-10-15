import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DisplayData extends StatefulWidget {
  const DisplayData({Key? key}) : super(key: key);

  @override
  _DisplayDataState createState() => _DisplayDataState();
}

class _DisplayDataState extends State<DisplayData> {
  List<Map<String, dynamic>> _dataList = [];

  @override
  void initState() {
    super.initState();
    getDataFromDatabase();
  }

  Future<void> getDataFromDatabase() async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'my_database.db'),
    );
    final List<Map<String, dynamic>> dataList = await db.query('my_table');
    setState(() {
      _dataList = dataList;
    });
  }

  Future<void> deleteData(int index) async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'my_database.db'),
    );
    await db.delete(
      'my_table',
      where: 'id = ?',
      whereArgs: [_dataList[index]['id']],
    );
    getDataFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Display Data'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: _dataList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text('Name: ${_dataList[index]['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${_dataList[index]['title']}'),
                Text('Description: ${_dataList[index]['description']}'),
              ],
            ),
            leading: _dataList[index]['image_path'] != null
                ? CircleAvatar(
              backgroundImage: FileImage(File(_dataList[index]['image_path'])),
            )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDataPage(data: _dataList[index]),
                      ),
                    ).then((_) {
                      // Refresh data after returning from EditDataPage
                      getDataFromDatabase();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirm Delete"),
                          content: Text("Are you sure you want to delete this details?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                deleteData(index); // Delete the item
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text("Delete"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class EditDataPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditDataPage({Key? key, required this.data}) : super(key: key);

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name']);
    _titleController = TextEditingController(text: widget.data['title']);
    _descriptionController = TextEditingController(text: widget.data['description']);
    _image = widget.data['image_path'] != null ? File(widget.data['image_path']) : null;
  }

  void _getImage() async {
    final pickerImage = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      if (pickerImage != null) {
        _image = File(pickerImage.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Update Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _getImage,
              child: CircleAvatar(
                backgroundImage: _image != null ? FileImage(_image!) : null,
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(left: 150),
              child: ElevatedButton(
                onPressed: () async {
                  final db = await openDatabase(
                    join(await getDatabasesPath(), 'my_database.db'),
                  );
                  await db.update(
                    'my_table',
                    {
                      'name': _nameController.text,
                      'title': _titleController.text,
                      'description': _descriptionController.text,
                      'image_path': _image?.path.toString(),
                    },
                    where: 'id = ?',
                    whereArgs: [widget.data['id']],
                  );
                  await db.close();
                  Navigator.pop(context);
                },
                child: Text(
                  'Update',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

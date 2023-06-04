import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and get the application documents directory
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  // Register the adapter for your data model class
  Hive.registerAdapter(TaskAdapter());

  // Open the Hive box
  await Hive.openBox<Task>('tasks');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListPage(),
    );
  }
}

class Task {
  final String title;
  final String description;

  Task({required this.title, required this.description});
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) i: reader.read(),
    };
    return Task(
      title: fields[0] as String,
      description: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description);
  }
}

class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final Box<Task> _taskBox = Hive.box<Task>('tasks');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: ListView.builder(
        itemCount: _taskBox.length,
        itemBuilder: (context, index) {
          final task = _taskBox.getAt(index);
          return ListTile(
            title: Text(task?.title ?? ''),
            subtitle: Text(task?.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditTaskDialog(context, index),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTask(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addTask();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, int index) {
    final task = _taskBox.getAt(index);
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateTask(index);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() {
    final title = _titleController.text;
    final description = _descriptionController.text;

    final task = Task(title: title, description: description);

    _taskBox.add(task);

    _titleController.clear();
    _descriptionController.clear();
    setState(() {}); // Update the widget state
  }

  void _updateTask(int index) {
    final title = _titleController.text;
    final description = _descriptionController.text;

    final task = Task(title: title, description: description);

    _taskBox.putAt(index, task);

    _titleController.clear();
    _descriptionController.clear();
    setState(() {}); // Update the widget state
  }

  void _deleteTask(int index) {
    _taskBox.deleteAt(index);
    setState(() {}); // Update the widget state
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
}

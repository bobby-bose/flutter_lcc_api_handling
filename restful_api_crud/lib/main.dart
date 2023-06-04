import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class Book {
  final int id;
  final String title;
  final String author;

  Book({required this.id, required this.title, required this.author});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
    };
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String apiUrl = 'http://127.0.0.1:5000/books';
  late List<Book> _books;

  @override
  void initState() {
    super.initState();
    _fetchAndRefreshBooks();
  }

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(Uri.parse(apiUrl));
    print(response.body);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Book.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch books');
    }
  }

  Future<Book> createBook(Book book) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(book.toJson()),
    );

    if (response.statusCode == 201) {
      dynamic data = jsonDecode(response.body);
      await _fetchAndRefreshBooks();
      return Book.fromJson(data);
    } else {
      throw Exception('Failed to create book');
    }
  }

  Future<Book> updateBook(Book book) async {
    final url = Uri.parse('$apiUrl/${book.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(book.toJson()),
    );

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      Book updatedBook = Book.fromJson(data);
      await _fetchAndRefreshBooks(); // Fetch and refresh books after update
      return updatedBook;
    } else {
      throw Exception('Failed to update book');
    }
  }

  Future<void> deleteBook(int id) async {
    final url = Uri.parse('$apiUrl/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      await _fetchAndRefreshBooks(); // Fetch and refresh books after delete
    } else {
      throw Exception('Failed to delete book');
    }
  }

  Future<void> _fetchAndRefreshBooks() async {
    try {
      List<Book> books = await fetchBooks();
      setState(() {
        _books = books;
      });
    } catch (e) {
      print('Failed to fetch books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Books')),
        body: FutureBuilder<List<Book>>(
          future: fetchBooks(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Book> books = snapshot.data!;
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  Book book = books[index];
                  return ListTile(
                    title: Text(book.title),
                    subtitle: Text(book.author),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            Book updatedBook = await showDialog(
                              context: context,
                              builder: (context) =>
                                  UpdateBookDialog(book: book),
                            );
                            if (updatedBook != null) {
                              await updateBook(updatedBook);
                              print('Updated Book: ${updatedBook.title}');
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            bool confirmed = await showDialog(
                              context: context,
                              builder: (context) =>
                                  DeleteConfirmationDialog(book: book),
                            );
                            if (confirmed) {
                              await deleteBook(book.id);
                              print('Deleted Book: ${book.title}');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Failed to fetch books'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            Book newBook = Book(id: 0, title: 'New Book', author: 'Author');
            Book createdBook = await createBook(newBook);
            print('Created Book: ${createdBook.title}');
          },
        ),
      ),
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final Book book;

  DeleteConfirmationDialog({required this.book});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete Book'),
      content: Text('Are you sure you want to delete "${book.title}"?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false); // User cancelled
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true); // User confirmed
          },
          child: Text('Delete'),
        ),
      ],
    );
  }
}

class UpdateBookDialog extends StatefulWidget {
  final Book book;

  UpdateBookDialog({required this.book});

  @override
  _UpdateBookDialogState createState() => _UpdateBookDialogState();
}

class _UpdateBookDialogState extends State<UpdateBookDialog> {
  late TextEditingController titleController;
  late TextEditingController authorController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book.title);
    authorController = TextEditingController(text: widget.book.author);
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Book'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: authorController,
            decoration: InputDecoration(labelText: 'Author'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // User cancelled
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Book updatedBook = Book(
              id: widget.book.id,
              title: titleController.text,
              author: authorController.text,
            );
            Navigator.pop(context, updatedBook);
          },
          child: Text('Update'),
        ),
      ],
    );
  }
}

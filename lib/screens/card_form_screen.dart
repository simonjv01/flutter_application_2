import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CardFormScreen extends StatefulWidget {
  const CardFormScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CardFormScreenState createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  List<Card> cards = [];
  TextEditingController titleController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  void loadCards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cardsJson = prefs.getString('cards');
    if (cardsJson != null) {
      List<dynamic> decodedCards = json.decode(cardsJson);
      setState(() {
        cards = decodedCards.map((card) => Card.fromJson(card)).toList();
      });
    }
  }

  void saveCards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cardsJson = json.encode(cards.map((card) => card.toJson()).toList());
    await prefs.setString('cards', cardsJson);
  }

  void addCard() {
    if (titleController.text.isNotEmpty) {
      setState(() {
        cards.add(Card(title: titleController.text, date: selectedDate));
        titleController.clear();
        selectedDate = DateTime.now();
      });
      saveCards();
    }
  }

  void deleteCard(int index) {
    setState(() {
      cards.removeAt(index);
    });
    saveCards();
  }

  void moveCardUp(int index) {
    if (index > 0) {
      setState(() {
        Card card = cards.removeAt(index);
        cards.insert(index - 1, card);
      });
      saveCards();
    }
  }

  void moveCardDown(int index) {
    if (index < cards.length - 1) {
      setState(() {
        Card card = cards.removeAt(index);
        cards.insert(index + 1, card);
      });
      saveCards();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Schedule'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Race Event'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                    'Date of Race: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                const SizedBox(width: 20),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: const Text('Select date'),
          ),
          ElevatedButton(
            onPressed: addCard,
            child: const Text('Add Card'),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return CardWidget(
                  key: ValueKey(cards[index]),
                  card: cards[index],
                  onDelete: () => deleteCard(index),
                  onMoveUp: index > 0 ? () => moveCardUp(index) : null,
                  onMoveDown: index < cards.length - 1
                      ? () => moveCardDown(index)
                      : null,
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final Card card = cards.removeAt(oldIndex);
                  cards.insert(newIndex, card);
                });
                saveCards();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Card {
  String title;
  DateTime date;

  Card({required this.title, required this.date});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
    };
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      title: json['title'],
      date: DateTime.parse(json['date']),
    );
  }
}

class CardWidget extends StatelessWidget {
  final Card card;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  CardWidget({
    required Key key,
    required this.card,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(card.title),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(card.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: onMoveUp,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: onMoveDown,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

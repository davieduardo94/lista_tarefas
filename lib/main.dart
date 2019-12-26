import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _toDoController = TextEditingController();
  List _toDoList = [];

  // Criando o mapa da lista para ultimo removido
  Map<String, dynamic> _lastRemoved;
  // para saber a posicao
  int _lastRemovedPos;

  void _addTodo() {
    setState(() {
      // criando o map vazio
      Map<String, dynamic> newToDo = Map();
      // adicionando titulo
      newToDo["title"] = _toDoController.text.toUpperCase();
      // limpando o texto do textfield
      _toDoController.text = "";
      newToDo['ok'] = false;
      // adicionando o elemento a lista.
      _toDoList.add(newToDo);
      // salvando no dispositivo;
      _saveData();
    });
  }

  // criando a função de refresh
  Future<Null> _refresh() async {
    // espera 1 segundo para executar a função
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      // ordernar a lista
      _toDoList.sort((a, b) {
        // se 'a' for ok e 'b' não for ok retorna 1
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  @override
  void initState() {
    super.initState();
    // lendo dados do arquivo
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Icon(Icons.add),
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
            // atualizar a lista
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

// cria a os itens da lista
  Widget buildItem(context, index) {
    return Dismissible(
      // definindo uma key
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]['ok'] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
          backgroundColor: (_toDoList[index]['ok'] ? Colors.green : Colors.yellow[300]),
        ),
        onChanged: (bool value) {
          setState(() {
            _toDoList[index]['ok'] = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          // duplica o item do mapa
          _lastRemoved = Map.from(_toDoList[index]);
          // salvar a posicao do item removido
          _lastRemovedPos = index;
          // remove o item no index
          _toDoList.removeAt(index);
          _saveData();

          // criando o snackbar
          final snack = SnackBar(
            content: Text('Tarefa \'${_lastRemoved['title']}\' removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  // inserir o ultimo elemento na sua posicao anterior
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          // mostrando o snackbar
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

// Criando função que retorna o arquivo para salvar a lista
  Future<File> _getFile() async {
    // pegar o diretorio do arquivo JSON / armazenar arquivos
    final directory = await getApplicationDocumentsDirectory();

    // retorna o arquivo, especificando o caminho do diretorio
    return File("${directory.path}/data.json");
  }

// função para salvar os dados
  Future<File> _saveData() async {
    //transformando a lista em JSON
    String data = json.encode(_toDoList);
    // abrir o arquivo, espera o arquivo.
    final file = await _getFile();
    // escrevendo os dados no arquivo
    return file.writeAsString(data);
  }

  // obter os dados
  Future<String> _readData() async {
    try {
      // tentar pegar o arquivo
      final file = await _getFile();
      // retorna o arquivo
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

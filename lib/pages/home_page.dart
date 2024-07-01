import 'package:campominado/components/bomb.dart';
import 'package:campominado/components/boxes.dart';
import 'package:campominado/components/score.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'dart:math';
import '../components/numberbox.dart';
import 'dart:async';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //variaveis
  int numberInEachRow = 9;
  int numberOfSquares = 81;
  int numerodeBombas = 10;
  var squareStatus =
      []; // [ numero de bombas em volta, revelado (true or false), flagged (true or false) ]
  List<int> bombLocation = [];
  late Timer _timer;
  int _start = 0;
  bool _timeRunning = false;
  bool bombsRevealed = false;
  int _flags = 0;
  int _touchMode = 0;
  bool _gameRunning = true;
  var _dropDificuldadeAtual = 'Fácil';
  final _dropDificuldades = ['Fácil', 'Intermediário', 'Difícil'];
  double _alturaDoCampo = 500;
  double _larguraDoCampo = 350;
  List<int> melhoresTempos = [0,0,0];
  var facil = boxScores.get('Fácil');
  var intermediario = boxScores.get('Intermediário');
  var dificil = boxScores.get('Difícil');



  @override
  void initState() {
    super.initState();
    if (boxScores.isEmpty){resetScores();};
    generateBombs();
    // inicia com cada quadrado 0 bombas em volta e não revelado
    for (int i = 0; i < numberOfSquares; i++) {
      squareStatus.add([0, false, false]);
    }
    scanBombs();
  }

  void generateBombs() {
    final random = Random();
    while (bombLocation.length < numerodeBombas) {
      int bombIndex = random.nextInt(numberOfSquares);
      if (!bombLocation.contains(bombIndex)) {
        bombLocation.add(bombIndex);
      }
    }
  }

  //funções do Timer
  void startTimer() {
  if(!_gameRunning){}
  else {
    _timeRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _start++;
      });
    });
  }
  }

  int stopTimer() {
    setState(() {
      _timeRunning = false;
    });
    _timer.cancel();
    return _start;
  }

  void restartTimer() {
    if(!_gameRunning){}
    else {
      setState(() {
        _timer.cancel();
        _start = 0;
        startTimer();
      });
    }
  }

  bool atualizaScores() {
    int dificuldade = _dropDificuldadeAtual == "Fácil"
        ? 1
        : (_dropDificuldadeAtual == 'Difícil' ? 0 : 2);
    int highScore = boxScores.getAt(dificuldade).time;
    if (highScore == 0 || highScore > _start) {
      setState(() {
        boxScores.put(
            _dropDificuldadeAtual,
            Score(
                name: _dropDificuldadeAtual,
                time: _start));
      });
      return true;
    } else {
      return false;
    }
  }

  void mostraScores(){
    showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.brown[100],
          title: Text('HIGHSCORE'),
          content: Container(
            height: 80,
            child: Column(
              children: [
                SizedBox(height: 10,),
                Text('Fácil - ' + boxScores.getAt(1).time.toString() + ' segundos'),
                Text('Intermediário - ' + boxScores.getAt(2).time.toString() + ' segundos'),
                Text('Difícil - ' + boxScores.getAt(0).time.toString() + ' segundos'),

                ],
            ),
          ),
          actions: [
            ElevatedButton(
            onPressed: () => resetScores(),
            child: Text('Reset Scores'))
            ],
        );
      });
  }

  void resetScores(){
    setState(() {
      boxScores.put(
          'Fácil',
          Score(
              name: 'Fácil',
              time: 0));
      boxScores.put(
          'Difícil',
          Score(
              name: 'Difícil',
              time: 0));
      boxScores.put(
          "Intermediário",
          Score(
              name: "Intermediário",
              time: 0));
    });
    print(boxScores.getAt(0).name);
    print(boxScores.getAt(1).name);
    print(boxScores.getAt(2).name);
  }

  //função quando o jogador apertar em um número
  void revealBoxNumber(int index) {
    // Define direções para vizinhos ao redor de uma célula
    final List<int> directions = [
      -1,
      1,
      -numberInEachRow,
      numberInEachRow,
      -numberInEachRow - 1,
      -numberInEachRow + 1,
      numberInEachRow - 1,
      numberInEachRow + 1
    ];

    void reveal(int index) {
      if (squareStatus[index][1])
        return; // Se já estiver revelado, não faz nada

      setState(() {
        squareStatus[index][2] = false;
        squareStatus[index][1] = true;
      });

      _calculaFlags();

      if (squareStatus[index][0] == 0) {
        for (int dir in directions) {
          int neighborIndex = index + dir;
          // Verifica se o vizinho está dentro dos limites do tabuleiro
          if (neighborIndex >= 0 && neighborIndex < numberOfSquares) {
            bool isLeftEdge = index % numberInEachRow == 0;
            bool isRightEdge = index % numberInEachRow == numberInEachRow - 1;

            // Impede que cruze as bordas da esquerda ou direita
            if ((dir == -1 && isLeftEdge) ||
                (dir == 1 && isRightEdge) ||
                (dir == -numberInEachRow - 1 && isLeftEdge) ||
                (dir == numberInEachRow - 1 && isLeftEdge) ||
                (dir == -numberInEachRow + 1 && isRightEdge) ||
                (dir == numberInEachRow + 1 && isRightEdge)) {
              continue;
            }

            if (!squareStatus[neighborIndex][1]) {
              reveal(neighborIndex); // Chamada recursiva
            }
          }
        }
      }
    }

    reveal(index);
  }

  void completaBombas(int index){
    if(!squareStatus[index][1] || squareStatus[index][0] == 0)
      return;

    final List<int> directions = [
      -1,
      1,
      -numberInEachRow,
      numberInEachRow,
      -numberInEachRow - 1,
      -numberInEachRow + 1,
      numberInEachRow - 1,
      numberInEachRow + 1
    ];

    int flagsAround = 0;

    for (int dir in directions) {
      int neighborIndex = index + dir;

        // Verifica se o vizinho está dentro dos limites do tabuleiro
      if (neighborIndex >= 0 && neighborIndex < numberOfSquares) {
        bool isLeftEdge = index % numberInEachRow == 0;
        bool isRightEdge = index % numberInEachRow == numberInEachRow - 1;

      // Impede que cruze as bordas da esquerda ou direita
      if ((dir == -1 && isLeftEdge) ||
          (dir == 1 && isRightEdge) ||
          (dir == -numberInEachRow - 1 && isLeftEdge) ||
          (dir == numberInEachRow - 1 && isLeftEdge) ||
          (dir == -numberInEachRow + 1 && isRightEdge) ||
          (dir == numberInEachRow + 1 && isRightEdge)) {
        continue;
      }

      if (squareStatus[neighborIndex][2]) {
        flagsAround++;
          }
        }
      }

    if(squareStatus[index][0] != flagsAround)
      return;
    else{
      for (int dir in directions) {
        int neighborIndex = index + dir;

        // Verifica se o vizinho está dentro dos limites do tabuleiro
        if (neighborIndex >= 0 && neighborIndex < numberOfSquares) {
          bool isLeftEdge = index % numberInEachRow == 0;
          bool isRightEdge = index % numberInEachRow == numberInEachRow - 1;

          // Impede que cruze as bordas da esquerda ou direita
          if ((dir == -1 && isLeftEdge) ||
              (dir == 1 && isRightEdge) ||
              (dir == -numberInEachRow - 1 && isLeftEdge) ||
              (dir == numberInEachRow - 1 && isLeftEdge) ||
              (dir == -numberInEachRow + 1 && isRightEdge) ||
              (dir == numberInEachRow + 1 && isRightEdge)) {
            continue;
          }


          if (!squareStatus[neighborIndex][1] && !squareStatus[neighborIndex][2]) {
            if (bombLocation.contains(neighborIndex)) {
              playerLost();
            } else {
            revealBoxNumber(neighborIndex);
            }
          }
        }
      }
    }
  }

  //coloca em cada quadrado quantas bombas tem em volta
  void scanBombs() {
    final List<int> directions = [
      -1,
      1,
      -numberInEachRow,
      numberInEachRow,
      -numberInEachRow - 1,
      -numberInEachRow + 1,
      numberInEachRow - 1,
      numberInEachRow + 1
    ];

    for (int i = 0; i < numberOfSquares; i++) {
      int numberOfBombsAround = 0;

      for (int dir in directions) {
        int neighborIndex = i + dir;

        // Verifica se o vizinho está dentro dos limites do tabuleiro
        if (neighborIndex >= 0 && neighborIndex < numberOfSquares) {
          bool isLeftEdge = i % numberInEachRow == 0;
          bool isRightEdge = i % numberInEachRow == numberInEachRow - 1;

          // Impede que cruze as bordas da esquerda ou direita
          if ((dir == -1 && isLeftEdge) ||
              (dir == 1 && isRightEdge) ||
              (dir == -numberInEachRow - 1 && isLeftEdge) ||
              (dir == numberInEachRow - 1 && isLeftEdge) ||
              (dir == -numberInEachRow + 1 && isRightEdge) ||
              (dir == numberInEachRow + 1 && isRightEdge)) {
            continue;
          }

          if (bombLocation.contains(neighborIndex)) {
            numberOfBombsAround++;
          }
        }
      }

      setState(() {
        squareStatus[i][0] = numberOfBombsAround;
      });
    }
  }

  void restartGame() {
    _gameRunning = true;
    setState(() {
      _start = 0;
      _flags = 0;
      if(_timeRunning){stopTimer();}
      bombLocation.clear();
      generateBombs();
      bombsRevealed = false;
      for (int i = 0; i < numberOfSquares; i++) {
        squareStatus[i][1] = false;
        squareStatus[i][2] = false;
      }

      scanBombs();
    });
  }

  void playerLost() {

    setState(() {
      bombsRevealed = true;
    });
    _gameRunning = false;
    stopTimer();
    Vibration.vibrate(duration: 500, intensities: [200]);
  }

  void playerWon() {
    _gameRunning = false;
    stopTimer();
    String melhorTempo = '';
    if(atualizaScores()){
      melhorTempo = 'Parabéns pelo melhor tempo!';
    };
    Vibration.vibrate(duration: 500, intensities: [150]);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.brown[100],
            title: Center(
              child: Text(
                'P A R A B É N S !',
                style: TextStyle(color: Colors.brown[700]),
              ),
            ),
            content: Container(
              height: 70,
              child: Column(
                children: [

                  Text('$_start segundos!',
                  style: TextStyle(
                    fontSize: 10
                  ),),
                  SizedBox(height: 5,),
                  Text(melhorTempo),
                ],
              ),
            ),
            actions: [
              Center(
                child: MaterialButton(
                  elevation: 0,
                  color: Colors.brown[100],
                  onPressed: () {
                    restartGame();
                    Navigator.pop(context);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.brown[700],
                      child: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Icon(Icons.refresh, size: 30, color: Colors.brown[100],),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  void checkWinner() {
    //verifica quantas caixas falta abrir
    int unrevealedBoxes = 0;
    for (int i = 0; i < numberOfSquares; i++) {
      if (squareStatus[i][1] == false) {
        unrevealedBoxes++;
      }
    }

    //se for igual ao numero de bombas, o jogador ganha
    if (unrevealedBoxes == bombLocation.length) {
      playerWon();
    }
  }

  void _calculaFlags() {
    setState(() {
      _flags = 0;
      for (int i = 0; i < numberOfSquares; i++) {
        if (squareStatus[i][2] == true) {
          _flags++;
        }
      }
    });

  }

  //quando segurar em um quadrado que não esteja aberto
  void putFlag(int index) {
    Vibration.vibrate(duration: 50, intensities: [20]);
    if (squareStatus[index][1]) {
    } else {
      if (squareStatus[index][2]) {
        squareStatus[index][2] = false;
      } else {
        squareStatus[index][2] = true;
      }
      _calculaFlags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[700],
      body: Column(
        children: [
          // game stats
          Container(
            color: Colors.brown[900],
            height: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => {
                      mostraScores(),
                      },
                    child: Card(
                      color: Colors.brown[300],
                      child: Icon(Icons.timer,
                          color: Colors.brown[700], size: 30),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.brown, // Cor da borda
                            width: 2.0, // Largura da borda
                          ),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '💣',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              (numerodeBombas - _flags).toString(),
                              style: TextStyle(
                                color: Colors.brown[200],
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.brown, // Cor da borda
                            width: 2.0, // Largura da borda
                          ),
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _start.toString(),
                              style:TextStyle(
                                color: Colors.brown[200],
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              '⏳',
                              style: TextStyle(
                                  fontSize: 20,
                                ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: restartGame,
                    child: Card(
                      color: Colors.brown[300],
                      child: Icon(Icons.refresh,
                          color: Colors.brown[700], size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                children: [InteractiveViewer(
                  child: Container(
                    width: _larguraDoCampo,
                    height: _alturaDoCampo,
                    child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: numberOfSquares,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: numberInEachRow),
                        itemBuilder: (context, index) {
                          if (bombLocation.contains(index)) {
                            return MyBomb(
                                child: '💣',
                                revealed: bombsRevealed,
                                flagged: squareStatus[index][2],
                                functionDoublePress: (){
                                  completaBombas(index);
                                },
                                functionLongPress: () {
                                  if(!_gameRunning){}
                                  else {
                                    if (!_timeRunning) {
                                      startTimer();
                                    }
                                    putFlag(index);
                                  }
                                },
                                function: () {
                                  if(!_gameRunning){}
                                  else {
                                    if (_touchMode == 1) {
                                      putFlag(index);
                                    } else {
                                      //apertou  na bomba
                                      playerLost();
                                    }
                                  }
                                });
                          } else {
                            return MyNumberBox(
                              child: squareStatus[index][0],
                              revealed: squareStatus[index][1],
                              flagged: squareStatus[index][2],
                              functionDoublePress: (){
                                completaBombas(index);
                              },
                              functionLongPress: () {
                                if(!_gameRunning){}
                                else{
                                  if (!_timeRunning) {
                                    startTimer();
                                  }
                                  putFlag(index);
                                }
                              },
                              function: () {
                                if(!_gameRunning){}
                                else{
                                  if (_touchMode == 1) {
                                    putFlag(index);
                                  } else {
                                    //apertou no numero
                                    if (!_timeRunning) {
                                      startTimer();
                                    }
                                    revealBoxNumber(index);
                                    checkWinner();
                                  }
                                }
                              },
                            );
                          }
                        }),
                  ),
                )],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(25))
                    ),
                    alignment: Alignment.center,
                    //margin: const EdgeInsets.only(bottom: 25),
                    child: ToggleSwitch(
                      fontSize: 16.0,
                      initialLabelIndex: _touchMode,
                      totalSwitches: 2,
                      activeBgColor: [const Color(0xFFBCAAA4)],
                      activeFgColor: Colors.brown[900],
                      inactiveBgColor: Colors.transparent,
                      inactiveFgColor: Colors.brown[200],
                      icons: [Icons.search, Icons.flag],
                      onToggle: (index){
                        setState(() {
                          _touchMode = index!;
                        });
                      },
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFA1887F), // Cor da borda
                      width: 2.0, // Largura da borda
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(10))
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: DropdownButton(
                      value: _dropDificuldadeAtual,
                      items: _dropDificuldades.map((String item){
                        return DropdownMenuItem(
                            child: Text(item,
                            style: TextStyle(
                              color: Colors.brown[400]
                            ),),
                            value: item
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _dropDificuldadeAtual = value!;
                          if (value == 'Fácil'){
                            numberInEachRow = 9;
                            numberOfSquares= 81;
                            numerodeBombas= 10;
                            _alturaDoCampo = 750;
                            _larguraDoCampo = 400;
                          }
                          if (value == 'Intermediário'){
                            numberInEachRow = 16;
                            numberOfSquares= 256;
                            numerodeBombas= 40;
                            _alturaDoCampo = 750;
                            _larguraDoCampo = 400;
                          }
                          if (value == 'Difícil'){
                            numberInEachRow = 16;
                            numberOfSquares= 480;
                            numerodeBombas= 99;
                            _alturaDoCampo = 750;
                            _larguraDoCampo = 400;
                          }
                          squareStatus.clear();
                          for (int i = 0; i < numberOfSquares; i++) {
                            squareStatus.add([0, false, false]);
                          }
                          restartGame();
                          });
                                              },
                    ),
                  ),
                ),

              ],
            ),
          )
        ],
      ),
    );
  }


}

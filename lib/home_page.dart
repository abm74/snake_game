import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/snake_pixel.dart';

enum Direction { left, right, up, down }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int squaresCount = 100;
  int rowCount = 10;
  List<int> snakePos = [0, 1, 2];
  final int snakeLength = 3;
  late int foodPos;
  // Timer? gameTimer;
  Direction currDirection = Direction.right;
  int score = 0;
  final FocusNode _focusNode = FocusNode();
  bool gameStarted = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    foodPos = Random().nextInt(squaresCount - snakeLength) + snakeLength;
  }

  void startGame() {
    setState(() {
      gameStarted = true;
    });
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        moveSnake(timer);
      });
    });
  }

  void moveSnake(Timer timer) {
    switch (currDirection) {
      case Direction.right:
        if (snakePos.last % rowCount == (rowCount - 1) ||
            snakePos.contains(snakePos.last + 1)) {
          gameOver(timer);
        } else {
          snakePos.add(snakePos.last + 1);
          if (snakePos.last == foodPos) {
            eatFood();
          } else {
            snakePos.removeAt(0);
          }
        }
        break;
      case Direction.left:
        if (snakePos.last % rowCount == 0 ||
            snakePos.contains(snakePos.last - 1)) {
          gameOver(timer);
        } else {
          snakePos.add(snakePos.last - 1);
          if (snakePos.last == foodPos) {
            eatFood();
          } else {
            snakePos.removeAt(0);
          }
        }
        break;
      case Direction.up:
        if (0 <= snakePos.last && snakePos.last < rowCount ||
            snakePos.contains(snakePos.last - rowCount)) {
          gameOver(timer);
        } else {
          snakePos.add(snakePos.last - rowCount);
          if (snakePos.last == foodPos) {
            eatFood();
          } else {
            snakePos.removeAt(0);
          }
        }
        break;
      case Direction.down:
        if ((squaresCount - rowCount) <= snakePos.last &&
                snakePos.last < squaresCount ||
            snakePos.contains(snakePos.last + rowCount)) {
          gameOver(timer);
        } else {
          snakePos.add(snakePos.last + rowCount);
          if (snakePos.last == foodPos) {
            eatFood();
          } else {
            snakePos.removeAt(0);
          }
        }
        break;
    }
  }

  // void moveForward() {
  //   if (snakePos.last == foodPos) {
  //     score++;
  //     foodPos = Random().nextInt(squaresCount);
  //     while (snakePos.contains(foodPos)) {
  //       foodPos = Random().nextInt(squaresCount);
  //     }
  //   } else {
  //     snakePos.removeAt(0);
  //   }
  // }

  void eatFood() {
    score++;
    // foodPos = Random().nextInt(squaresCount);
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(squaresCount);
    }
  }

  void gameOver(Timer timer) {
    timer.cancel();
    final nameController = TextEditingController();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: ((context) => AlertDialog(
            contentTextStyle: const TextStyle(color: Colors.black),
            backgroundColor: Colors.white,
            title: const Text(
              'Game Over!',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 25),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your score is $score',
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextField(
                  style: const TextStyle(color: Colors.black),
                  controller: nameController,
                  decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
            actions: [
              TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple),
                  onPressed: () {
                    restartGame(context);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Restart')),
              const SizedBox(
                width: 10,
              ),
              TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple),
                  onPressed: () async {
                    // Navigator.of(context).pop();
                    try {
                      await FirebaseFirestore.instance
                          .collection('scores')
                          .doc(nameController.text.trim())
                          .set({'name': nameController.text, 'score': score});
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      restartGame(context);
                    } catch (e) {
                      print(e);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        restartGame(context);
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(SnackBar(
                            content: const Text('couldn\'t send score'),
                            action: SnackBarAction(
                                label: 'Ok',
                                onPressed: () => Navigator.of(context).pop()),
                          ));
                      }
                    }
                  },
                  child: const Text('Submit score')),
            ],
          )),
    );
  }

  void restartGame(BuildContext context) {
    setState(() {
      setState(() {
        snakePos = [0, 1, 2];
        foodPos = Random().nextInt(squaresCount - snakeLength) + snakeLength;
        score = 0;
        currDirection = Direction.right;
      });
      gameStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(241, 0, 0, 0),
        body: KeyboardListener(
          autofocus: true,
          onKeyEvent: (value) {
            if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (currDirection != Direction.down &&
                  currDirection != Direction.up) {
                setState(() {
                  currDirection = Direction.up;
                });
                debugPrint('moving up');
              }
            } else if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (currDirection != Direction.down &&
                  currDirection != Direction.up) {
                setState(() {
                  currDirection = Direction.down;
                });
                debugPrint('moving down');
              }
            } else if (value.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (currDirection != Direction.left &&
                  currDirection != Direction.right) {
                setState(() {
                  currDirection = Direction.left;
                });
                debugPrint('moving left');
              }
            } else if (value.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (currDirection != Direction.left &&
                  currDirection != Direction.right) {
                setState(() {
                  currDirection = Direction.right;
                });
                debugPrint('moving right');
              }
            }
          },
          focusNode: _focusNode,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (currDirection == Direction.left ||
                  currDirection == Direction.right) {
                return;
              }
              if (details.delta.dx > 0) {
                setState(() {
                  currDirection = Direction.right;
                });
                debugPrint('moving right');
              } else {
                setState(() {
                  currDirection = Direction.left;
                });
                print('moving left');
              }
            },
            onVerticalDragUpdate: (details) {
              if (currDirection == Direction.down ||
                  currDirection == Direction.up) {
                return;
              }
              if (details.delta.dy > 0) {
                setState(() {
                  currDirection = Direction.down;
                });
                print('moving down');
              } else {
                setState(() {
                  currDirection = Direction.up;
                });
                print('moving up');
              }
            },
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          // textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.centerRight,
                                // mainAxisSize: MainAxisSize.min,
                                // mainAxisAlignment: MainAxisAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.end,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Current score',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                    Text(
                                      '$score',
                                      style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 25),
                                //   child: Text(
                                //     '$score',
                                //     style: const TextStyle(
                                //         fontSize: 25,
                                //         fontWeight: FontWeight.bold),
                                //   ),
                                // )
                                // ],
                              ),
                            ),
                            const Expanded(
                              child: SizedBox(
                                  // width: 30,
                                  ),
                            ),
                            Expanded(
                              flex: 4,
                              child: gameStarted
                                  ? Container()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TOP FIVE HIGH SCORES',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('scores')
                                              .limit(5)
                                              .orderBy('score',
                                                  descending: true)
                                              .snapshots(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<
                                                      QuerySnapshot<
                                                          Map<String, dynamic>>>
                                                  snapshot) {
                                            if (snapshot.hasData) {
                                              if (snapshot.data!.size > 0) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 25),
                                                  child: SizedBox(
                                                    // alignment: Alignment.centerLeft,
                                                    // constraints: BoxConstraints(),
                                                    height:
                                                        snapshot.data!.size *
                                                            20,
                                                    width: 150,
                                                    child: ListView.builder(
                                                        itemCount:
                                                            snapshot.data!.size,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                snapshot.data!
                                                                    .docs[index]
                                                                    .data()[
                                                                        'score']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Text(
                                                                snapshot.data!
                                                                    .docs[index]
                                                                    .data()['name'],
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              )
                                                            ],
                                                          );
                                                        }),
                                                  ),
                                                );
                                              } else {
                                                return const Text(
                                                    'no available scores');
                                              }
                                            } else if (snapshot.hasError) {
                                              return const Text(
                                                  'couldn\'t load high scores');
                                            } else {
                                              return const Text('loading...');
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                            )
                          ],
                          // color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.height * 0.55,
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.43),
                        child: GridView.builder(
                          itemCount: squaresCount,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: rowCount),
                          itemBuilder: ((context, index) {
                            if (snakePos.contains(index)) {
                              return const SnakePixel();
                            } else if (foodPos == index) {
                              return const FoodPixel();
                            } else {
                              return const BlankPixel();
                            }
                          }),
                        ),
                      ),
                    ),
                    if (!gameStarted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30, top: 20),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                // disabledBackgroundColor:
                                //     const Color.fromARGB(255, 67, 14, 77),
                                // disabledForegroundColor:
                                //     Color.fromARGB(120, 255, 255, 255),
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white),
                            onPressed: startGame,
                            child: const Text(
                              'PLAY',
                              style: TextStyle(fontSize: 20),
                            )),
                      ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_todo/data/task.dart';
import 'package:riverpod_todo/data/task_list.dart';
import 'package:riverpod_todo/widget/task_tile.dart';

final StateNotifierProvider<TaskList> taskListProvider =
StateNotifierProvider((ref) => TaskList([Task(title: 'play tennis')]));

final Computed<int> isNotDoneTasksCount = Computed((read) {
  return read(taskListProvider.state).where((task) => !task.isDone).length;
});

enum Filter {
  all,
  active,
  done,
}

final StateProvider<Filter> filterProvider = StateProvider((ref) => Filter.all);

final Computed<List<Task>> filteredTasks = Computed((read) {
  final filter = read(filterProvider);
  final tasks = read(taskListProvider.state);

  switch (filter.state) {
    case Filter.done:
      return tasks.where((task) => task.isDone).toList();
    case Filter.active:
      return tasks.where((task) => !task.isDone).toList();
    case Filter.all:
    default:
      return tasks;
  }
});

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var _newTaskTitle = '';
    final _textEditingController = TextEditingController();

    void clearTextField() {
      _textEditingController.clear();
      _newTaskTitle = '';
    }

    void showSnackBar({
      List<Task> previousTasks,
      TaskList taskList,
      String content,
      ScaffoldState scaffoldState,
    }) {
      scaffoldState.removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: 'restore',
          onPressed: () {
            taskList.updateTasks(previousTasks);
            scaffoldState.removeCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 3),
      );
      scaffoldState.showSnackBar(snackBar);
    }

    return MaterialApp(
      home: Scaffold(
        body: Consumer(
              (context, read) {
            final taskList = read(taskListProvider);
            final allTasks = read(taskListProvider.state);
            final displayedTasks = read(filteredTasks);
            final filter = read(filterProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'ToDo List',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          child: TextField(
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              hintText: 'Enter a todo title',
                              suffixIcon: IconButton(
                                onPressed: clearTextField,
                                icon: Icon(Icons.clear),
                              ),
                            ),
                            textAlign: TextAlign.start,
                            onChanged: (newText) {
                              _newTaskTitle = newText;
                            },
                            onSubmitted: (newText) {
                              if (_newTaskTitle.isEmpty) {
                                _newTaskTitle = 'No Title';
                              }
                              taskList.addTask(_newTaskTitle);
                              clearTextField();
                            },
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${read(isNotDoneTasksCount)} tasks left',
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('All'),
                                  ),
                                  onTap: () => filter.state = Filter.all,
                                ),
                                InkWell(
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Active'),
                                  ),
                                  onTap: () => filter.state = Filter.active,
                                ),
                                InkWell(
                                  onTap: () => filter.state = Filter.done,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Done'),
                                  ),
                                ),
                                InkWell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Delete Done',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    final doneTasks = allTasks
                                        .where((task) => task.isDone)
                                        .toList();
                                    if (doneTasks.isNotEmpty) {
                                      taskList.deleteDoneTasks();
                                      showSnackBar(
                                        previousTasks: allTasks,
                                        taskList: taskList,
                                        content:
                                        'Done tasks have been deleted.',
                                        scaffoldState: Scaffold.of(context),
                                      );
                                    }
                                  },
                                ),
                                InkWell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Delete All',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (allTasks.isNotEmpty) {
                                      taskList.deleteAllTasks();
                                      showSnackBar(
                                        previousTasks: allTasks,
                                        taskList: taskList,
                                        content: 'All tasks have been deleted.',
                                        scaffoldState: Scaffold.of(context),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        return TaskTile(
                          taskTitle: task.title,
                          isChecked: task.isDone,
                          checkboxCallback: (bool value) {
                            taskList.toggleDone(task.id);
                          },
                          longPressCallback: () {
                            taskList.deleteTask(task);
                            showSnackBar(
                              previousTasks: displayedTasks,
                              taskList: taskList,
                              content: '${task.title} has been deleted.',
                              scaffoldState: Scaffold.of(context),
                            );
                          },
                        );
                      },
                      itemCount: displayedTasks.length,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
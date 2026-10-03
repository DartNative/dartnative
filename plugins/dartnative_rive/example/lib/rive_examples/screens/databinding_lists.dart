// Ported from rive-flutter's example/lib/examples/databinding_lists.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   FileLoader.fromAsset + RiveWidgetBuilder  →  Rive(asset:, controller:)
//   onLoaded: viewModelInstance.list('menu')! →  the same lookup in initState
//   state.file.viewModelByName('listItem')!   →  controller.viewModelByName(…)
//   myTodo.string('label')!.value             →  myTodo.string('label').value
//   ElevatedButton                            →  the example's pill button
//   Scaffold(appBar: AppBar(…), body: …)      →  the body alone
//   the controls panel at the page's foot     →  its top rule and padding as
//                                                theirs, the panel lifted
//                                                clear of the home indicator
//                                                and Android's navigation bar:
//                                                the bottom inset, what
//                                                SafeArea adds, and 20 more as
//                                                padding below it.
//                                                width: infinity is what
//                                                Flutter does anyway. A
//                                                SafeArea around it takes the
//                                                whole height in DartNative and
//                                                centres the panel (framework
//                                                gap, reported)
//
// Their screen brings its own Scaffold and AppBar, and the example app shows
// it inside a page that already has a bar, so theirs draws a second bar
// under the first: colorScheme.inversePrimary, near-white on their dark
// theme, under a white title — a blank white band. It carries nothing, so
// the port leaves it out.
//
// A made instance lives in the view's file, so createInstance() needs the
// view mounted, as theirs needs the file loaded; the Add button is only
// reachable once it is. An index out of range is logged natively and
// ignored where rive_native throws, so their SnackBar never shows here.
//
// See: https://rive.app/docs/runtimes/data-binding

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../elevated_pill.dart';
import '../theme.dart';

Widget buildDataBindingLists(BuildContext context) =>
    const ExampleDataBindingLists();

/// Example using Rive data binding lists at runtime.
///
/// See: https://rive.app/docs/runtimes/data-binding
class ExampleDataBindingLists extends StatefulWidget {
  const ExampleDataBindingLists({super.key});

  @override
  State<ExampleDataBindingLists> createState() =>
      _ExampleDataBindingListsState();
}

class _ExampleDataBindingListsState extends State<ExampleDataBindingLists> {
  final controller = RiveController();
  late ViewModelInstance viewModelInstance;
  late ViewModelInstanceList menuList;
  late ViewModel todoItemVM;

  // Text controllers for input fields
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();
  final TextEditingController _deleteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _onLoaded();
  }

  @override
  void dispose() {
    controller.dispose();
    _textController.dispose();
    _num1Controller.dispose();
    _num2Controller.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  void _onLoaded() {
    viewModelInstance = controller.viewModelInstance;

    // Get the menu list
    menuList = viewModelInstance.list('menu');

    // Get the TodoItem View Model
    todoItemVM = controller.viewModelByName('listItem');

    debugPrint('Rive file loaded!');
    debugPrint('Menu list: $menuList');
    debugPrint('TodoItem VM: $todoItemVM');
  }

  void _onSubmit() {
    final inputText = _textController.text.trim();
    if (inputText.isEmpty) return;

    debugPrint('Submitted text: $inputText');
    var myTodo = todoItemVM.createInstance()!;
    myTodo.string('label').value = inputText;
    myTodo.string('fontIcon').value = "";
    myTodo.color('hoverColor').value = const Color(0xffefefef);
    menuList.add(myTodo);
    myTodo.dispose();

    // Clear the input
    _textController.clear();
  }

  void _onSwap() {
    final num1Text = _num1Controller.text.trim();
    final num2Text = _num2Controller.text.trim();

    if (num1Text.isEmpty || num2Text.isEmpty) return;

    final num1 = int.tryParse(num1Text);
    final num2 = int.tryParse(num2Text);

    if (num1 != null && num2 != null) {
      try {
        menuList.swap(num1, num2);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error swapping items: $e')));
      }
    }
  }

  void _onDelete() {
    final deleteText = _deleteController.text.trim();
    if (deleteText.isEmpty) return;

    final deleteIndex = int.tryParse(deleteText);
    if (deleteIndex != null) {
      try {
        menuList.removeAt(deleteIndex);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              // Rive Widget
              Expanded(
                child: Rive(
                  asset: 'assets/rive/lists_demo.riv',
                  controller: controller,
                ),
              ),

              // Controls Panel
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 20,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300])),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Add Item Section
                      const Text('Add New Item', style: _heading),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: _field,
                              decoration: const InputDecoration(
                                hintText: 'Enter item text',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _onSubmit(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedPill(
                            onPressed: _onSubmit,
                            child: const Text('Add'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Swap Items Section
                      const Text('Swap Items', style: _heading),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _num1Controller,
                              style: _field,
                              decoration: const InputDecoration(
                                hintText: 'Index 1',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _num2Controller,
                              style: _field,
                              decoration: const InputDecoration(
                                hintText: 'Index 2',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedPill(
                            onPressed: _onSwap,
                            child: const Text('Swap'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Delete Item Section
                      const Text('Delete Item', style: _heading),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _deleteController,
                              style: _field,
                              decoration: const InputDecoration(
                                hintText: 'Index to delete',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedPill(
                            onPressed: _onDelete,
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _heading = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 16,
  fontWeight: FontWeight.bold,
  fontFamily: monoFont,
);

const _field = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 14,
  fontFamily: monoFont,
);

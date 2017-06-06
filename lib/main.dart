import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: new MyHomePage(title: 'Todo list')
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

typedef void ChangeTodoCallback(int index, bool val);

class AnimatedText extends AnimatedWidget {

  final String text;
  final bool crossed;

  const AnimatedText({
    Key key,
    @required Animation listenable,
    this.text,
    this.crossed
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    Widget textView = new Text(text);
    Animation animation = listenable as Animation;

    Widget todoTextView = new ClipRect(child: new Align(
        alignment: FractionalOffset.topRight,
        widthFactor: 1.0 - animation.value,
        child: new DefaultTextStyle(
            style: new TextStyle(
                decoration: TextDecoration.none, color: Colors.black),
            child: textView
        )
    ));

    Widget textLinedTrough = new ClipRect(child: new Align(
        alignment: FractionalOffset.topLeft,
        widthFactor: animation.value,
        child: new DefaultTextStyle(
            style: new TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.black),
            child: textView
        )
    ));

    return new Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          textLinedTrough,
          todoTextView
        ]
    );
  }
}

typedef Widget AnimationControllerHolderChildBuilder(BuildContext ctx,
    AnimationController animationController,
    Animation animation);

typedef AnimationController AnimationControllerBuilder();
typedef Animation AnimationBuilder(AnimationController controller);

class AnimationControllerHolder extends StatefulWidget {

  final AnimationControllerBuilder controllerBuilder;
  final AnimationBuilder animationBuilder;
  final AnimationControllerHolderChildBuilder builder;

  AnimationControllerHolder({
    Key key,
    @required this.controllerBuilder,
    @required this.animationBuilder,
    @required this.builder
  }) : super(key: key);

  @override
  AnimationControllerHolderState createState() =>
      new AnimationControllerHolderState();
}

class AnimationControllerHolderState extends State<AnimationControllerHolder> {
  AnimationController animationController;
  Animation animation;

  initState() {
    super.initState();
    animationController = widget.controllerBuilder();
    animation = widget.animationBuilder(animationController);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, animationController, animation);
  }
}

class TodoListView extends StatelessWidget {

  final List<Todo> todos;
  final ChangeTodoCallback changeTodo;
  final TickerProvider tickerProvider;

  TodoListView({
    Key key,
    this.todos,
    this.changeTodo,
    @required this.tickerProvider
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IndexedWidgetBuilder indexedWidgetBuilder = (context, index) {
      return new AnimationControllerHolder(

          controllerBuilder: () =>
          new AnimationController(
              duration: new Duration(milliseconds: 300),
              vsync: tickerProvider
          ),

          animationBuilder: (animationController) =>
          new CurvedAnimation(
            parent: animationController,
            curve: Curves.easeInOut,
          ),

          builder: (context, animationController, animation) {
            if (!animationController.isAnimating) {
              animationController.value = todos[index].isDone ? 1.0 : 0.0;
            }

            return new Row(children: [
              new Checkbox(
                  value: todos[index].isDone,
                  onChanged: (val) {
                    animationController.animateTo(val ? 1.0 : 0.0);
                    changeTodo(index, val);
                  }
              ),
              new AnimatedText(
                  listenable: animation,
                  text: todos[index].text,
                  crossed: todos[index].isDone
              )
            ]);
          }

      );
    };

    return new ListView.builder(
        itemCount: todos.length,
        itemBuilder: indexedWidgetBuilder
    );
  }
}

typedef void AddTodoCallback(String text);

class TodoForm extends StatelessWidget {

  final AddTodoCallback onAddTodo;

  TodoForm({this.onAddTodo});

  VoidCallback onSubmit(TextEditingController controller) {
    return () {
      onAddTodo(controller.text);
    };
  }

  @override
  Widget build(BuildContext context) {
    var textEditingController = new TextEditingController();

    double elevation = 4.0;

    return new Row(
        children: [
          new Expanded(
              child: new Container(
                  padding: new EdgeInsets.only(
                      bottom: 6.0,
                      left: 4.0,
                      right: 8.0
                  ),
                  child: new Material(
                      elevation: elevation,
                      borderRadius: new BorderRadius.all(
                          new Radius.circular(999.0)),
                      child: new Container(
                          padding: new EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: new TextField(
                              controller: textEditingController,
                              decoration: new InputDecoration.collapsed(
                                  hintText: "O que precisa ser feito?"))
                      )
                  )
              )
          ),
          new Container(
              padding: new EdgeInsets.only(bottom: 8.0, right: 4.0),
              child: new FloatingActionButton(
                  elevation: elevation,
                  child: new Icon(Icons.send),
                  onPressed: this.onSubmit(textEditingController),
                  mini: true
              )
          )

        ]);
  }
}


class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  List<Todo> _todos = [];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Column(
            children: [
              new Expanded(child: new TodoListView(
                  todos: _todos,
                  changeTodo: this.changeTodo,
                  tickerProvider: this
              )),
              new TodoForm(onAddTodo: this.onAddTodo)
            ]
        )
    );
  }

  void onAddTodo(String text) {
    setState(() {
      _todos.add(new Todo()
        ..text = text
        ..isDone = false
      );
    });
  }

  void changeTodo(int index, bool val) {
    setState(() {
      _todos[index].isDone = val;
    });
  }
}

class Todo {
  String text;
  bool isDone;
}

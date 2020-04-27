import 'dart:convert';
import 'dart:io';
import 'services.dart';
import 'xterm.dart';

/// Implementation of list questions. Can be used without [CLI_Dialog].
class ListChooser {
  /// The options which are presented to the user
  List<String> items;

  /// Select the navigation mode. See dialog.dart for details.
  bool navigationMode;

  /// Default constructor for the list chooser.
  /// It is as simple as passing your [items] as a List of strings
  ListChooser(this.items, {this.navigationMode = false}) {
    _checkItems();
    //relevant when running from IntelliJ console pane for example
    if (stdin.hasTerminal) {
      // lineMode must be true to set echoMode in Windows
      // see https://github.com/dart-lang/sdk/issues/28599
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  /// Named constructor mostly for unit testing.
  /// For context and an example see [CLI_Dialog], `README.md` and the `test/` folder.
  ListChooser.std(this._std_input, this._std_output, this.items,
      {this.navigationMode = false}) {
    _checkItems();
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  /// Similar to [ask] this actually triggers the dialog and returns the chosen item = option.
  String choose() {
    int input;
    int index = 0;

    _renderList(0, initial: true);

    while ((input = _userInput()) != 10) {
      if (input < 0) {
        _resetStdin();
        return ':${-input}';
      }
      if (input == 65) {
        if (index > 0) {
          index--;
        }
      } else if (input == 66) {
        if (index < items.length - 1) {
          index++;
        }
      }
      _renderList(index);
    }
    _resetStdin();
    return items[index];
  }

  // END OF PUBLIC API

  var _std_input = StdinService();
  var _std_output = StdoutService();

  void _checkItems() {
    if (items == null) {
      throw ArgumentError('No options for list dialog given');
    }
  }

  void _deletePreviousList() {
    for (var i = 0; i < items.length; i++) {
      _std_output.write(XTerm.moveUp(1) + XTerm.blankRemaining());
    }
  }

  void _renderList(index, {initial = false}) {
    if (!initial) {
      _deletePreviousList();
    }
    for (var i = 0; i < items.length; i++) {
      if (i == index) {
        _std_output
            .writeln(XTerm.rightIndicator() + ' ' + XTerm.teal(items[i]));
        continue;
      }
      _std_output.writeln('  ' + items[i]);
    }
  }

  void _resetStdin() {
    if (stdin.hasTerminal) {
      //see default ctor. Order is important here
      stdin.lineMode = true;
      stdin.echoMode = true;
    }
  }

  int _userInput() {
    if (Platform.isWindows) {
      var byte = _std_input.readByteSync();

      if (byte == Keys.enter) return 10;
      if (byte == Keys.arrowUp[0]) return 65;
      if (byte == Keys.arrowDown[0])
        return 66;
      else
        return byte;
    }
    for (var i = 0; i < 2; i++) {
      final input = _std_input.readByteSync();
      if (navigationMode) {
        if (input == 58) {
          // 58 = :
          _std_output.write(':');
          final inputLine =
              _std_input.readLineSync(encoding: Encoding.getByName('utf-8'));
          int lineNumber = int.parse(inputLine.trim());
          _std_output.writeln('$lineNumber');
          return -lineNumber; // make the result negative so it can be told apart from normal key codes
        }
      }
      if (input == 10) {
        return 10;
      }
    }
    final input = _std_input.readByteSync();
    return input;
  }
}

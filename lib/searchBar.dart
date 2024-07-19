import 'package:flutter/material.dart';
import 'package:searchbar_animation/searchbar_animation.dart';

class SearchBarAnimationWidget extends StatefulWidget {
  final Function(String) onSubmitted;

  const SearchBarAnimationWidget({Key? key, required this.onSubmitted}) : super(key: key);

  @override
  _SearchBarAnimationWidgetState createState() => _SearchBarAnimationWidgetState();
}

class _SearchBarAnimationWidgetState extends State<SearchBarAnimationWidget> {

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SearchBarAnimation(
      textEditingController: _textEditingController,
      isOriginalAnimation: true,
      enableKeyboardFocus: false,
      onChanged: (value) {
        _textEditingController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      onFieldSubmitted: (value) {
        if (value.isNotEmpty) {
          widget.onSubmitted(value);
          // _textEditingController.clear();
        }
      },
      onExpansionComplete: () {
        debugPrint('do something just after searchbox is opened.');
      },
      onCollapseComplete: () {
        debugPrint('do something just after searchbox is closed.');
      },
      onPressButton: (isSearchBarOpens) {
        if (isSearchBarOpens) {
        } else {
        }
      },
      secondaryButtonWidget: const Icon(
        Icons.close,
        size: 20,
        color: Colors.black,
      ),
      buttonWidget: const Icon(
        Icons.search,
        size: 20,
        color: Colors.black,
      ),
      trailingWidget: IconButton(icon: Icon(Icons.clear,size: 20,), onPressed: () { _textEditingController.clear(); },),
    );
  }
}

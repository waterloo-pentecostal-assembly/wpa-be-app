import 'package:flutter/material.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class ThreadForm extends StatefulWidget {
  final String? initialTitle;
  final String saveButtonText;
  final Function(String) onSave;
  final VoidCallback onCancel;

  const ThreadForm({
    Key? key,
    this.initialTitle,
    this.saveButtonText = 'POST',
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  _ThreadFormState createState() => _ThreadFormState();
}

class _ThreadFormState extends State<ThreadForm> with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _textEditingController;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: widget.initialTitle ?? '');
    _isValid = _textEditingController.text.trim().isNotEmpty;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 1,
    );

    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

    _controller.forward();
  }

  @override
  dispose() {
    _controller.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);

    return FadeTransition(
      opacity: _animation,
      child: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: widget.onCancel,
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0),
                    ),
                  )
                ],
              ),
            ),
            GestureDetector(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 18.0,
                      offset: Offset(0, 12),
                    )
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: TextFormField(
                        controller: _textEditingController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        focusNode: _focusNode,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            _isValid = value.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Thread Title',
                          hintStyle: getIt<TextFactory>()
                              .textFormFieldInputStyle()
                              .copyWith(
                                color: Colors.grey.shade300,
                              ),
                        ),
                        style: getIt<TextFactory>().textFormFieldInputStyle(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      runSpacing: 16.0,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          children: [
                            _CancelButton(onCancel: widget.onCancel),
                            SizedBox(width: 16),
                            _SaveButton(
                              isValid: _isValid,
                              text: widget.saveButtonText,
                              onPressed: () {
                                widget.onSave(_textEditingController.text);
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isValid;
  final String text;
  final VoidCallback onPressed;

  const _SaveButton({
    Key? key,
    required this.isValid,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(
          getIt<LayoutFactory>().getDimension(baseDimension: 16.0))),
      child: TextButton(
        style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(Size(
                getIt<LayoutFactory>().getDimension(baseDimension: 90.0),
                getIt<LayoutFactory>().getDimension(baseDimension: 30.0))),
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                return kWpaBlue.withValues(alpha: 0.25);
              }
              return kWpaBlue.withValues(alpha: 0.75);
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                return Colors.white;
              }
              return Colors.white;
            }),
            padding: WidgetStateProperty.all(
                EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: !isValid ? null : onPressed,
        child: getIt<TextFactory>().regularButton(text),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onCancel;

  const _CancelButton({Key? key, required this.onCancel}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(
          getIt<LayoutFactory>().getDimension(baseDimension: 16.0))),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          minimumSize: Size(
              getIt<LayoutFactory>().getDimension(baseDimension: 90.0),
              getIt<LayoutFactory>().getDimension(baseDimension: 30.0)),
          backgroundColor: kCardGrey,
          padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onCancel,
        child: getIt<TextFactory>().regularButton('CANCEL'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../common/loader.dart';
import '../../../common/text_factory.dart';

class NewPrayerRequestForm extends StatefulWidget {
  final OverlayEntry entry;

  const NewPrayerRequestForm({Key key, @required this.entry}) : super(key: key);

  @override
  _NewPrayerRequestFormState createState() => _NewPrayerRequestFormState(entry: entry);
}

class _NewPrayerRequestFormState extends State<NewPrayerRequestForm> with TickerProviderStateMixin {
  final OverlayEntry entry;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  AnimationController _controller;
  Animation<double> _animation;
  bool _isAnonymous;

  _NewPrayerRequestFormState({@required this.entry});

  initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 1,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

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
    return BlocProvider<NewPrayerRequestsBloc>(
      create: (BuildContext context) => getIt<PrayerRequestsBloc>()..add(NewPrayerRequestStarted()),
      child: BlocBuilder<NewPrayerRequestsBloc, PrayerRequestsState>(
        builder: (BuildContext context, state) {
          if (state is NewPrayerRequestState) {
            _isAnonymous = state.isAnonymous;
            FocusScope.of(context).requestFocus(_focusNode);

            return FadeTransition(
              opacity: _animation,
              child: SafeArea(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => entry.remove(),
                      child: Flex(
                        direction: Axis.horizontal,
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.white.withOpacity(0),
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
                                  BlocProvider.of<NewPrayerRequestsBloc>(context)
                                    ..add(NewPrayerRequestRequestChanged(prayerRequest: value.toString()));
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Prayer Request',
                                  hintStyle: getIt<TextFactory>().textFormFieldInputStyle().copyWith(
                                        color: Colors.grey.shade300,
                                      ),
                                ),
                                style: getIt<TextFactory>().textFormFieldInputStyle(),
                              ),
                            ),
                            Container(
                              padding: state.errorExist ? null : EdgeInsets.only(bottom: 16),
                              child: state.errorExist
                                  ? Text('')
                                  : getIt<TextFactory>().textFormFieldInput(state.prayerRequestError,
                                      color: kErrorTextColor.withOpacity(0.8), fontSize: 12.0),
                            ),
                            Wrap(
                              runSpacing: 16.0,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    AnonymousCheckbox(
                                      value: _isAnonymous,
                                      onChanged: (bool state) {
                                        BlocProvider.of<NewPrayerRequestsBloc>(context)
                                          ..add(NewPrayerRequestAnonymousChanged(isAnonymous: state));
                                      },
                                    ),
                                    SizedBox(width: 4),
                                    getIt<TextFactory>().lite('Anonymous'),
                                  ],
                                ),
                                Wrap(
                                  children: [
                                    CancelButton(entry: entry),
                                    SizedBox(width: 16),
                                    PostButton(
                                      isValid: state.isFormValid,
                                      isAnonymous: state.isAnonymous,
                                      prayerRequest: state.prayerRequest,
                                      entry: entry,
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
          return Loader(); // Or return empty SizedBox() widget
        },
      ),
    );
  }
}

class AnonymousCheckbox extends StatefulWidget {
  final bool value;
  final Function(bool state) onChanged;

  const AnonymousCheckbox({Key key, @required this.value, @required this.onChanged}) : super(key: key);

  @override
  _AnonymousCheckboxState createState() => _AnonymousCheckboxState(value: value, onChanged: onChanged);
}

class _AnonymousCheckboxState extends State<AnonymousCheckbox> {
  bool value = true;
  final Function(bool state) onChanged;

  _AnonymousCheckboxState({@required this.value, @required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => value = !value);
        onChanged(value);
      },
      child: Container(
        height: 18,
        width: 18,
        decoration: BoxDecoration(
          border: value ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(48),
          color: value ? kWpaBlue.withOpacity(0.65) : Colors.white,
        ),
        child: value
            ? Icon(
                Icons.check,
                size: 16.0,
                color: Colors.white,
              )
            : SizedBox(),
      ),
    );
  }
}

class PostButton extends StatelessWidget {
  final bool isValid;
  final bool isAnonymous;
  final String prayerRequest;
  final OverlayEntry entry;

  const PostButton({
    Key key,
    @required this.isValid,
    @required this.isAnonymous,
    @required this.prayerRequest,
    @required this.entry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      child: FlatButton(
        height: 30,
        minWidth: 90,
        color: kWpaBlue.withOpacity(0.75),
        textColor: Colors.white,
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: !isValid
            ? null
            : () {
                BlocProvider.of<PrayerRequestsBloc>(context)
                  ..add(NewPrayerRequestCreated(
                    request: prayerRequest,
                    isAnonymous: isAnonymous,
                  ));
                entry.remove();
              },
        disabledColor: kWpaBlue.withOpacity(0.25),
        disabledTextColor: Colors.white,
        child: getIt<TextFactory>().regularButton('POST'),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final OverlayEntry entry;

  const CancelButton({Key key, @required this.entry}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      child: FlatButton(
        height: 30,
        minWidth: 90,
        color: kCardGrey,
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => entry.remove(),
        child: getIt<TextFactory>().regularButton('CANCEL'),
      ),
    );
  }
}

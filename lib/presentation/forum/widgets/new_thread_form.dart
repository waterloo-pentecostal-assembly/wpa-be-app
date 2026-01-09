import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/application/forum/forum_bloc.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/application/notification_settings/notification_settings_bloc.dart';

class NewThreadForm extends StatefulWidget {
  final OverlayEntry? entry;
  final String forumId;
  final ForumBloc forumBloc;
  final NotificationSettingsBloc notificationSettingsBloc;

  const NewThreadForm({
    Key? key,
    this.entry,
    required this.forumId,
    required this.forumBloc,
    required this.notificationSettingsBloc,
  }) : super(key: key);

  @override
  _NewThreadFormState createState() => _NewThreadFormState();
}

class _NewThreadFormState extends State<NewThreadForm>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();

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
              onTap: () => widget.entry?.remove(),
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
                            CancelButton(entry: widget.entry),
                            SizedBox(width: 16),
                            PostButton(
                              isValid: _isValid,
                              title: _textEditingController.text,
                              forumId: widget.forumId,
                              forumBloc: widget.forumBloc,
                              notificationSettingsBloc:
                                  widget.notificationSettingsBloc,
                              entry: widget.entry,
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

class PostButton extends StatelessWidget {
  final bool isValid;
  final String title;
  final String forumId;
  final ForumBloc forumBloc;
  final NotificationSettingsBloc notificationSettingsBloc;
  final OverlayEntry? entry;

  const PostButton({
    Key? key,
    required this.isValid,
    required this.title,
    required this.forumId,
    required this.forumBloc,
    required this.notificationSettingsBloc,
    this.entry,
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
        onPressed: !isValid
            ? null
            : () {
                final authState =
                    BlocProvider.of<AuthenticationBloc>(context).state;
                if (authState is Authenticated) {
                  // Generate ID client-side
                  final threadId = FirebaseFirestore.instance
                      .collection('forums')
                      .doc(forumId)
                      .collection('threads')
                      .doc()
                      .id;

                  forumBloc.add(
                    CreateThread(
                      ForumThread(
                        id: threadId,
                        forumId: forumId,
                        title: title,
                        authorId: authState.user.id,
                        authorName: authState.user.fullName,
                        authorImageUrl: authState.user.profilePhotoUrl,
                        createdAt: Timestamp.now(),
                        updatedAt: Timestamp.now(),
                        commentCount: 0,
                        isFrozen: false,
                        isHidden: false,
                      ),
                    ),
                  );
                  // Auto-follow
                  notificationSettingsBloc.add(ThreadFollowed(threadId));
                }
                entry?.remove();
              },
        child: getIt<TextFactory>().regularButton('POST'),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final OverlayEntry? entry;

  const CancelButton({Key? key, this.entry}) : super(key: key);
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
        onPressed: () => entry?.remove(),
        child: getIt<TextFactory>().regularButton('CANCEL'),
      ),
    );
  }
}

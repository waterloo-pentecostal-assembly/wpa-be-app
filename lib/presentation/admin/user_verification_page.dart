import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/admin/admin_bloc.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/admin/helper.dart';

class UserVerificationPage extends StatefulWidget {
  @override
  _UserVerificationPageState createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  final key = GlobalKey<AnimatedListState>();
  List<LocalUser> userCards;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is UnverifiedUsersLoaded) {
          _initUserList(state.users);
        }
      },
      builder: (BuildContext context, state) {
        if (userCards != null) {
          return SafeArea(
              child: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                BlocProvider.of<AdminBloc>(context)..add(LoadUnverifiedUsers());
              },
              child: Column(
                children: [
                  HeaderWidget(title: 'User Verification'),
                  Expanded(
                    child: Container(
                      child: AnimatedList(
                        key: key,
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        initialItemCount: userCards.length,
                        itemBuilder: (context, index, animation) =>
                            buildItem(userCards[index], index, animation),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
        } else if (userCards == null) {
          return SafeArea(
              child: Container(
            child: Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  BlocProvider.of<AdminBloc>(context)
                    ..add(LoadUnverifiedUsers());
                },
                child: Column(
                  children: [
                    HeaderWidget(title: 'User Verification'),
                  ],
                ),
              ),
            ),
          ));
        } else {
          return Loader();
        }
      },
    );
  }

  Widget buildItem(LocalUser user, int index, Animation<double> animation) {
    return userCard(user, index, animation);
  }

  void removeItem(int index) {
    setState(() {
      final item = userCards.removeAt(index);
      key.currentState.removeItem(
          index, (context, animation) => buildItem(item, index, animation));
    });
  }

  _initUserList(List<LocalUser> userList) {
    setState(() {
      userCards = userList;
    });
  }

  Widget userCard(LocalUser user, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 0.9 * MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: kCardOverlayGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 8.0,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getIt<TextFactory>()
                      .regular(user.firstName + ' ' + user.lastName),
                  SizedBox(height: 8),
                  getIt<TextFactory>().lite(user.email),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        BlocProvider.of<AdminBloc>(context)
                          ..add(DeleteUnverifiedUser(user.id));
                        removeItem(index);
                      },
                      child: Icon(Icons.cancel, color: Colors.red, size: 40),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                        onTap: () {
                          BlocProvider.of<AdminBloc>(context)
                            ..add(VerifyUser(user.id));
                          removeItem(index);
                        },
                        child: Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 40)),
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

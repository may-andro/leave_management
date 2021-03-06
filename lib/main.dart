import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mm_hrmangement/model/UserModel.dart';
import 'package:flutter_mm_hrmangement/redux/applied_leave_redux/applied_leave_action.dart';
import 'package:flutter_mm_hrmangement/redux/employee_management_redux/employee_management_action.dart';
import 'package:flutter_mm_hrmangement/redux/login_action/actions.dart';
import 'package:flutter_mm_hrmangement/redux/project_management_redux/project_management_action.dart';
import 'package:flutter_mm_hrmangement/redux/public_holiday/public_holiday_action.dart';
import 'package:flutter_mm_hrmangement/redux/states/app_state.dart';
import 'package:flutter_mm_hrmangement/redux/store.dart';
import 'package:flutter_mm_hrmangement/ui/home_page/home_page.dart';
import 'package:flutter_mm_hrmangement/ui/onboarding_page/onboarding_page.dart';
import 'package:flutter_mm_hrmangement/ui/signin_page/signin_page.dart';
import 'package:flutter_mm_hrmangement/ui/splash_page/splash_page.dart';
import 'package:flutter_mm_hrmangement/utility/constants.dart';
import 'package:flutter_mm_hrmangement/utility/navigation.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => run();

Future run() async {
  runApp(SplashPage());

  var authUser = await _init();
  var store = await createStore();
  Navigation.initPaths();

  if (!authUser.isOnboarded) {
    runApp(RouteOnBoardingPage(store));
  }else if (authUser.isLoggedIn) {
    print('run looged in user is ${authUser.user.name}');
    await _setStore(authUser.user, store);
    runApp(RouteHomePage(store));
  } else {
    runApp(RouteSignInPage(store));
  }
}

Future<void> _setStore(User user, Store<AppState> store) async {
  store.dispatch(LoginUserAction(user));
  store.dispatch(FetchAppliedLeaveAction(mmid: user.mmid));
  store.dispatch(FetchPublicHolidayAction());
  if (user.role.id == 0 ||
      user.role.id == 1 ||
      user.role.id == 5 ||
      user.role.id == 6) {
    store.dispatch(FetchEmployeeListAction());
  }
  if (user.role.id == 0 || user.role.id == 5 || user.role.id == 6) {
    store.dispatch(FetchProjectListAction());
  }
}

Future<AuthUser> _init() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String savedMmid = prefs.getString(LOGGED_IN_USER_MMID) ?? "";
  String savedPassword = prefs.getString(LOGGED_IN_USER_PASSWORD) ?? "";
  bool isOnboarded = prefs.getBool(ONBOARDING_FINISHED) ?? false;

  if (isOnboarded) {
    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('pinCollection')
        .where('mmid', isEqualTo: '$savedMmid')
        .getDocuments();

    if (querySnapshot.documents.length > 0) {
      String fireStorePin = querySnapshot.documents[0]['pin'] as String;
      if (fireStorePin == savedPassword) {
        QuerySnapshot userQuerySnapshot = await Firestore.instance
            .collection('userCollection')
            .where('mmid', isEqualTo: '$savedMmid')
            .getDocuments();

        User user = User.fromJson(userQuerySnapshot.documents[0]);
        return AuthUser(isOnboarded,
            savedPassword.isNotEmpty && savedMmid.isNotEmpty, user);
      } else {
        return AuthUser(
            isOnboarded,
            savedPassword.isNotEmpty && savedMmid.isNotEmpty,
            User.nullObject());
      }
    } else {
      return AuthUser(isOnboarded,
          savedPassword.isNotEmpty && savedMmid.isNotEmpty, User.nullObject());
    }
  } else {
    return AuthUser(isOnboarded, false, User.nullObject());
  }
}

class FetchingData extends StatelessWidget {
  final User user;

  FetchingData(this.user);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                  child: new Text("Fetching data",
                      style: new TextStyle(fontSize: 32.0))),
            ),
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Center(
                  child: new Text("for ${user.name}",
                      style: new TextStyle(fontSize: 16.0))),
            ),
            Padding(
                padding: const EdgeInsets.all(30.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ))
          ], mainAxisAlignment: MainAxisAlignment.center),
        )),
        theme: new ThemeData(
          primarySwatch: Colors.deepPurple,
          canvasColor: Colors.transparent,
        ));
  }
}

class RouteOnBoardingPage extends StatelessWidget {
  final Store<AppState> store;

  RouteOnBoardingPage(this.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, appState) {
          return MaterialApp(
              title: 'MM Leave Management',
              debugShowCheckedModeBanner: false,
              theme: ThemeProvider(store.state.themeDataId)._getAppTheme(),
              home: OnBoardingPage()
          );
        },
      )
    );
  }
}

class RouteHomePage extends StatelessWidget {
  final Store<AppState> store;

  RouteHomePage(this.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, appState) {
          return MaterialApp(
              title: 'MM Leave Management',
              debugShowCheckedModeBanner: false,
              theme: ThemeProvider(store.state.themeDataId)._getAppTheme(),
              home: HomePage()
          );
        },
      )
    );
  }
}

class RouteSignInPage extends StatelessWidget {
  final Store<AppState> store;

  RouteSignInPage(this.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, appState) {
          return MaterialApp(
              title: 'MM Leave Management',
              debugShowCheckedModeBanner: false,
              theme: ThemeProvider(store.state.themeDataId)._getAppTheme(),
              home: SignInPage()
          );
        },
      )
    );
  }
}

class ThemeProvider{
  final int themeId;

  ThemeProvider(this.themeId);

  ThemeData _getAppTheme() {
    final ThemeData base = ThemeData.light();

    ThemeData appTheme;
    switch(themeId) {
      case SELECTED_THEME_PURPLE: appTheme =  base.copyWith(
        accentColor: Colors.blueGrey,
        primaryColor: Colors.deepPurple,
        bottomAppBarColor: Colors.deepPurple,
        primaryColorLight: Colors.purpleAccent,
        primaryColorDark: Colors.purple,
        buttonColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        backgroundColor: Colors.white70,
        cardColor: Colors.blueGrey,
        textSelectionColor: Colors.deepPurple,
        errorColor: Colors.redAccent,
        cursorColor: Colors.blueGrey,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        indicatorColor: Colors.blueGrey,
        hintColor: Colors.blueGrey,
      );
      break;

      case SELECTED_THEME_BLUE: appTheme = base.copyWith(
        accentColor: Colors.blueGrey,
        primaryColor: Colors.blue,
        bottomAppBarColor: Colors.blue,
        primaryColorLight: Colors.blueAccent,
        primaryColorDark: Colors.blue,
        buttonColor: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        backgroundColor: Colors.white70,
        cardColor: Colors.blueGrey,
        textSelectionColor: Colors.blueGrey,
        errorColor: Colors.redAccent,
        cursorColor: Colors.black,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        indicatorColor: Colors.black,
        hintColor: Colors.blueGrey,
      );
      break;

      case SELECTED_THEME_RED: appTheme = base.copyWith(
        accentColor: Colors.black87,
        primaryColor: Colors.red,
        bottomAppBarColor: Colors.red,
        primaryColorLight: Colors.redAccent,
        primaryColorDark: Colors.red,
        buttonColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        backgroundColor: Colors.white70,
        cardColor: Colors.blueGrey,
        textSelectionColor: Colors.deepPurple,
        errorColor: Colors.deepOrange,
        cursorColor: Colors.black,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        indicatorColor: Colors.black,
        hintColor: Colors.blueGrey,
      );
      break;

      case SELECTED_THEME_YELLOW: appTheme = base.copyWith(
        accentColor: Colors.black,
        primaryColor: Colors.amber,
        bottomAppBarColor: Colors.amber,
        primaryColorLight: Colors.amberAccent,
        primaryColorDark: Colors.amber,
        buttonColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        backgroundColor: Colors.white70,
        cardColor: Colors.blueGrey,
        textSelectionColor: Colors.blueGrey,
        errorColor: Colors.red,
        cursorColor: Colors.black,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        indicatorColor: Colors.black,
        hintColor: Colors.blueGrey,
      );
      break;

      default: appTheme = base.copyWith(
        accentColor: Colors.blueGrey,
        primaryColor: Colors.deepPurple,
        bottomAppBarColor: Colors.deepPurple,
        primaryColorLight: Colors.purpleAccent,
        primaryColorDark: Colors.purple,
        buttonColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        backgroundColor: Colors.white70,
        cardColor: Colors.blueGrey,
        textSelectionColor: Colors.deepPurple,
        errorColor: Colors.redAccent,
        cursorColor: Colors.blueGrey,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        indicatorColor: Colors.blueGrey,
        hintColor: Colors.blueGrey,
      );
      break;
    }

    return appTheme;
  }
}

/*class MyApp extends StatelessWidget {
  final AuthUser authUser;
  final Store<AppState> store;

  MyApp(this.authUser, this.store) {
    Navigation.initPaths();
  }

  Widget build(BuildContext context) {
    print('MyApp.build');
    var store = this.store;
    return StoreProvider(
      store: store,
      child: new MaterialApp(
          title: 'MM Leave Management',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: FutureBuilder(
            future: Future.delayed(Duration(microseconds: 1)),
            builder: (BuildContext context, snapshot) {
              if (!authUser.isOnboarded) {
                return OnBoardingPage();
              } else if (authUser.isLoggedIn) {
                return FutureBuilder(
                  future: _fetchLeaveData(authUser.user.mmid),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Leave>> snapShot) {
                    if (snapShot.hasData) {
                      print(
                          '_AppState.build going to home ${authUser.user.name}');
                      store.dispatch(LoginUserAction(authUser.user));
                      store.dispatch(
                          FetchAppliedLeaveAction(mmid: authUser.user.mmid));
                      store.dispatch(FetchPublicHolidayAction());
                      if (authUser.user.role.id == 0 ||
                          authUser.user.role.id == 1 ||
                          authUser.user.role.id == 5 ||
                          authUser.user.role.id == 6) {
                        store.dispatch(FetchEmployeeListAction());
                      }
                      return HomePage();
                    } else {
                      return FetchingData(authUser.user);
                    }
                  },
                );
              } else {
                return SignInPage();
              }
            },
          )),
    );
  }

  Future<List<Leave>> _fetchLeaveData(String mmid) async {
    List<Leave> leaveList = [];
    await Firestore.instance.runTransaction((Transaction transaction) async {
      var snapshot = await Firestore.instance
          .collection("leaveCollection")
          .where('mmid', isEqualTo: mmid)
          .getDocuments();

      snapshot.documents.forEach((snapshot) {
        Leave leave = Leave.fromJson(snapshot);
        leaveList.add(leave);
      });
    });
    return leaveList;
  }
}*/

class AuthUser {
  bool isOnboarded = false;
  bool isLoggedIn = false;
  User user = User.nullObject();

  AuthUser(this.isOnboarded, this.isLoggedIn, this.user);
}

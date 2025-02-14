import 'package:clout/screens/authscreens/loadingnew.dart';
import 'package:clout/screens/preauthscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  //try { String uid = FirebaseAuth.instance.currentUser!.uid;} catch(e) {}
  //print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: "assets/.env");
  Stripe.publishableKey = dotenv.get("stripePublishableKey");
  Stripe.merchantIdentifier = "merchant.com.outwithclout.clout";
  Stripe.instance.applySettings();

  if (FirebaseAuth.instance.currentUser != null) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: false,
    );
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  PendingDynamicLinkData? initialLink;
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  MyApp({super.key, initialLink});
  @override
  Widget build(BuildContext context) {
    analytics.setAnalyticsCollectionEnabled(true);
    return MaterialApp(
      title: 'clout',
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(
        analytics: analytics,
      ),
      theme: ThemeData(
          primaryColor: const Color.fromARGB(255, 255, 48, 117),
          primarySwatch: Colors.grey,
          fontFamily: "Archivo",
          textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color.fromARGB(150, 255, 48, 117),
              selectionColor: Color.fromARGB(150, 255, 48, 117),
              selectionHandleColor: Color.fromARGB(150, 255, 48, 117))),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  AuthenticationWrapper({super.key, required this.analytics});
  FirebaseAnalytics analytics;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return LoadingScreen(
                uid: FirebaseAuth.instance.currentUser!.uid,
                analytics: analytics);
          } else {
            return PreAuthScreen(analytics: analytics);
          }
        }),
      ),
      backgroundColor: Colors.white,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'buyer page/cart_service.dart';
import 'buyer page/buyer_home_page.dart';
import 'splash_screen.dart';
import 'auth_wrapper.dart';
import 'buyer page/login_page.dart';
import 'buyer page/register_page.dart';
import 'auth_service.dart';
import 'seller page/seller_home_page.dart';
import 'forgot_password_page.dart';
import 'notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();

  // Initialize Notification Service
  NotificationService notificationService = NotificationService();
  await notificationService.init();

  // Set foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    notificationService.showNotification(message);
      });


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VeggieVerse',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthWrapper(),
        '/home': (context) => BuyerHomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/seller_home': (context) => SellerHomePage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
      },
    );
  }
}

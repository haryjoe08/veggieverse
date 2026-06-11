import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'buyer page/login_page.dart';
import 'buyer page/buyer_home_page.dart';
import 'seller page/seller_home_page.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Menggunakan StreamBuilder untuk mendengarkan perubahan status autentikasi
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // Jika tidak ada user yang terautentikasi, tampilkan halaman login
            return LoginPage();
          } else {
            // Jika ada user yang terautentikasi, periksa perannya
            return FutureBuilder<String?>(
              future: AuthService().getCurrentUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.done) {
                  if (roleSnapshot.data == 'buyer') {
                    // Jika peran user adalah buyer, tampilkan halaman buyer
                    return BuyerHomePage();
                  } else if (roleSnapshot.data == 'seller') {
                    // Jika peran user adalah seller, tampilkan halaman seller
                    return SellerHomePage();
                  } else {
                    // Jika peran tidak dikenali, kembali ke halaman login
                    return LoginPage();
                  }
                }
                // Tampilkan indikator loading selama memeriksa peran
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }
        }
        // Tampilkan indikator loading selama memeriksa status autentikasi
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
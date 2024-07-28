import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:dashbaord/screens/home_screen.dart';
import 'package:dashbaord/services/analytics_service.dart';
import 'package:dashbaord/services/api_service.dart';
import 'package:dashbaord/utils/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CustomGoogleButton extends StatefulWidget {
  final ValueChanged<int> onThemeChanged;
  const CustomGoogleButton({super.key, required this.onThemeChanged});

  @override
  State<CustomGoogleButton> createState() => _CustomGoogleButtonState();
}

class _CustomGoogleButtonState extends State<CustomGoogleButton> {
  final analyticsService = FirebaseAnalyticsService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email"]);

  Future<bool> checkLoggedIn() async {
    return _googleSignIn.isSignedIn();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> silentLogin() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      var result = await ApiServices().login(googleAuth.idToken ?? 'aa45');

      if (result['status'] == 401) {
        showSnackBar(result['error']);
        return;
      }
      if (result['user'] == null) {
        showSnackBar('Failed to sign in with Google.');
        return;
      }
      // successfully logged in
      analyticsService.logEvent(name: "Google Login");

      var email = FirebaseAuth.instance.currentUser?.email ?? '';

      if (email.isEmpty) {
        await logout();
        showSnackBar('Error!');
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomeScreen(
            isGuest: false,
            onThemeChanged: widget.onThemeChanged,
          ),
        ));
      }
    } catch (error) {
      showSnackBar('Failed to sign in with Google.');
    }
  }

  Future<bool> signInWithGoogle() async {
    timeDilation = 1;
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      final GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        googleUser = await _googleSignIn.signInSilently();
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        return false;
      }

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CustomLoadingScreen()));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);

      var result = await ApiServices().login(googleAuth.idToken ?? 'aa45');

      if (result['status'] == 401) {
        showSnackBar('Please login with IITH email-ID');
        return false;
      }
      if (result['user'] == null) {
        showSnackBar('Failed to sign in with Google.');
        return false;
      }
      // successfully logged in
      analyticsService.logEvent(name: "Google Login");

      return true;
    } catch (error) {
      showSnackBar('Failed to sign in with Google.');
      return false;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  // void printInChunks(String longString, {int chunkSize = 500}) {
  //   for (int i = 0; i < longString.length; i += chunkSize) {
  //     int end = (i + chunkSize < longString.length)
  //         ? i + chunkSize
  //         : longString.length;
  //     debugPrint(longString.substring(i, end));
  //   }
  // }

  @override
  void initState() {
    super.initState();
    silentLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xffFE724C),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            bool status = await signInWithGoogle();
            bool isLoggedIn = await checkLoggedIn();

            if (isLoggedIn && status) {
              var email = FirebaseAuth.instance.currentUser?.email ?? '';

              if (email.isEmpty) {
                await logout();
                showSnackBar('Something went wrong');
                Navigator.of(context).popUntil(
                    (route) => route.isFirst); //POP THE LOADING SCREEN
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        isGuest: false,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                    (Route<dynamic> route) => false);
              }
            } else {
              await logout();
              Navigator.of(context)
                  .popUntil((route) => route.isFirst); //POP THE LOADING SCREEN
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/icons/google.png",
                  height: 36,
                  width: 36,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    "Continue with Google",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/session_service.dart';
import '../login_screen.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecurityService.updateLastActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    } else if (state == AppLifecycleState.paused) {
      SecurityService.updateLastActive();
    }
  }

  void _checkAutoLock() {
    final account = SessionService.activeAccount;
    if (account != null && account.pin != null) {
      if (SecurityService.shouldAutoLock(account.autoLockDurationSeconds ~/ 60)) {
        // Force lock
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(account: account)),
          (route) => false,
        );
      }
    }
    SecurityService.updateLastActive();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SecurityService.updateLastActive(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

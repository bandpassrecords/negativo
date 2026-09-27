import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The app's normal orientations (see main.dart): portrait only.
const kAppOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];

/// For screens that show a photo large: while one is open the phone may turn
/// to landscape, so a photo taken sideways can fill the screen, and the
/// portrait lock comes back when it closes. The viewfinder does the same for
/// shooting.
mixin RotatableScreen<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(kAppOrientations);
    super.dispose();
  }
}

import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/pages/landing.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampusMateApp extends StatelessWidget {
  const CampusMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CmBloc(),
      child: MaterialApp(
        title: "CampusMate",
        theme: ThemeData.from(
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
              ).copyWith(
                surface: backgroundColor,
                onSurface: textColor,
                secondary: secondaryColor,
                primary: primaryColor,
              ),
        ),
        home: Landing(),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ijtgujclssmghkhbaxrk.supabase.co',
    publishableKey: 'sb_publishable_J9M-9-Zgj1cF_QlyMAlOUA_8SKId1Zf',
  );
  runApp(CampusMateApp());
}

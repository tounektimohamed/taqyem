import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:DREHATT_app/components/language.dart';
import 'package:DREHATT_app/components/language_constants.dart';
import 'package:DREHATT_app/screens2/app%20option%20setting/help_center.dart';
import 'package:DREHATT_app/screens2/app%20option%20setting/termsNconditions.dart';
import 'package:DREHATT_app/screens2/users/user_profile.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPageUI extends StatefulWidget {
  const SettingsPageUI({super.key});

  @override
  _SettingPageUIState createState() => _SettingPageUIState();
}

class _SettingPageUIState extends State<SettingsPageUI> {
  bool ValueNotify1 = false;
  bool ValueNotify2 = false;

  onChangeFunction2(bool newValue2) {
    setState(() {
      ValueNotify2 = newValue2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translation(context).settings,
          style: const TextStyle(
            fontSize: 22,
          ),
        ),
        elevation: 5,
      ),
      body: SettingsList(
        lightTheme: const SettingsThemeData(
          settingsListBackground: Color.fromRGBO(241, 250, 251, 1),
        ),
        sections: [
          SettingsSection(
            title: Text(
              translation(context).accountSettings,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(translation(context).editProfile),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserProfile()),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              translation(context).appSettings,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(translation(context).notificationSettings),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.language_rounded),
                title: Text(translation(context).language),
                onPressed: (BuildContext context) {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        child: Wrap(
                          children: Language.languageList().map((language) {
                            return ListTile(
                              leading: Text(
                                language.flag,
                                style: const TextStyle(fontSize: 30),
                              ),
                              title: Text(language.name),
                              onTap: () async {
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              translation(context).other,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                  leading: const Icon(Icons.help_outline_outlined),
                  title: Text(translation(context).helpCenter),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpCenter()),
                    );
                  }),
              SettingsTile.navigation(
                leading: const Icon(Icons.description_outlined),
                title: Text(translation(context).termsNconditions),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsAndConditions()),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text(''),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.login_rounded),
                title: Text(translation(context).signOut),
                onPressed: (context) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsNconditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsNconditions;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @nic.
  ///
  /// In en, this message translates to:
  /// **'NIC'**
  String get nic;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mobileNo.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get save;

  /// No description provided for @profileText1.
  ///
  /// In en, this message translates to:
  /// **'In here you can edit your profile settings.'**
  String get profileText1;

  /// No description provided for @profileText2.
  ///
  /// In en, this message translates to:
  /// **'If you forget your password relax and try to remember your password.'**
  String get profileText2;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @dashText1.
  ///
  /// In en, this message translates to:
  /// **'Your medication reminders\n will be displayed here.'**
  String get dashText1;

  /// No description provided for @dashText2.
  ///
  /// In en, this message translates to:
  /// **'You have no medication reminders.'**
  String get dashText2;

  /// No description provided for @medicationText1.
  ///
  /// In en, this message translates to:
  /// **'Your medications\n will be displayed here.'**
  String get medicationText1;

  /// No description provided for @medicationText2.
  ///
  /// In en, this message translates to:
  /// **'You have no medications.'**
  String get medicationText2;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Add a Medication'**
  String get buttonText;

  /// No description provided for @dashText3.
  ///
  /// In en, this message translates to:
  /// **'Your medication alarms\n will be displayed here'**
  String get dashText3;

  /// No description provided for @presImg.
  ///
  /// In en, this message translates to:
  /// **'Prescription Image'**
  String get presImg;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby Pharmacies & Hospitals'**
  String get nearby;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'Check your BMI'**
  String get bmi;

  /// No description provided for @upalarm.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Alarms'**
  String get upalarm;

  /// No description provided for @emgcall.
  ///
  /// In en, this message translates to:
  /// **'Emergency Calls'**
  String get emgcall;

  /// No description provided for @reclamation.
  ///
  /// In en, this message translates to:
  /// **'Reclamation'**
  String get reclamation;

  /// No description provided for @housingApplicationForm.
  ///
  /// In en, this message translates to:
  /// **'Housing Form'**
  String get housingApplicationForm;

  /// No description provided for @photoHeading.
  ///
  /// In en, this message translates to:
  /// **'Save a photo of your prescription'**
  String get photoHeading;

  /// No description provided for @photoText1.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your prescription'**
  String get photoText1;

  /// No description provided for @photoBtn1.
  ///
  /// In en, this message translates to:
  /// **'Add a Photo'**
  String get photoBtn1;

  /// No description provided for @photoBtn2.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get photoBtn2;

  /// No description provided for @photoBtn3.
  ///
  /// In en, this message translates to:
  /// **'Browse Gallery'**
  String get photoBtn3;

  /// No description provided for @photoBtn4.
  ///
  /// In en, this message translates to:
  /// **'Use Camera'**
  String get photoBtn4;

  /// No description provided for @photoText2.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get photoText2;

  /// No description provided for @nIS.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get nIS;

  /// No description provided for @pSAI.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get pSAI;

  /// No description provided for @pIAS.
  ///
  /// In en, this message translates to:
  /// **'Prescription image uploaded successfully'**
  String get pIAS;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @dUpload.
  ///
  /// In en, this message translates to:
  /// **'Done uploading'**
  String get dUpload;

  /// No description provided for @bmiCal.
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get bmiCal;

  /// No description provided for @bmiText.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index(BMI) is a metric of body fat percentage commonly used to estimate risk levels of potential health problems.'**
  String get bmiText;

  /// No description provided for @bmiform1.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bmiform1;

  /// No description provided for @bmiform2.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bmiform2;

  /// No description provided for @bmiButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get bmiButton;

  /// No description provided for @bmiText1.
  ///
  /// In en, this message translates to:
  /// **'Your BMI Value is: '**
  String get bmiText1;

  /// No description provided for @bmiText2.
  ///
  /// In en, this message translates to:
  /// **'You\'re Underweight!'**
  String get bmiText2;

  /// No description provided for @bmiText3.
  ///
  /// In en, this message translates to:
  /// **'You\'re Healthy!'**
  String get bmiText3;

  /// No description provided for @bmiText4.
  ///
  /// In en, this message translates to:
  /// **'You\'re Overweight!'**
  String get bmiText4;

  /// No description provided for @bmiText5.
  ///
  /// In en, this message translates to:
  /// **'Ideal weight: '**
  String get bmiText5;

  /// No description provided for @bmiText6.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight'**
  String get bmiText6;

  /// No description provided for @bmiText7.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height'**
  String get bmiText7;

  /// No description provided for @ssa.
  ///
  /// In en, this message translates to:
  /// **'Suwa Seriya Ambulance'**
  String get ssa;

  /// No description provided for @as.
  ///
  /// In en, this message translates to:
  /// **'Accident Service'**
  String get as;

  /// No description provided for @pi.
  ///
  /// In en, this message translates to:
  /// **'Police Emergency'**
  String get pi;

  /// No description provided for @fi.
  ///
  /// In en, this message translates to:
  /// **'Fire & Rescue'**
  String get fi;

  /// No description provided for @gv.
  ///
  /// In en, this message translates to:
  /// **'Government Information Center'**
  String get gv;

  /// No description provided for @eps.
  ///
  /// In en, this message translates to:
  /// **'Emergency Police Squad'**
  String get eps;

  /// No description provided for @ctL.
  ///
  /// In en, this message translates to:
  /// **'Cannot launch'**
  String get ctL;

  /// No description provided for @ddUsage.
  ///
  /// In en, this message translates to:
  /// **'Daily Dosage Usage'**
  String get ddUsage;

  /// No description provided for @wdUsage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Dosage Usage'**
  String get wdUsage;

  /// No description provided for @addMed.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMed;

  /// No description provided for @medName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medName;

  /// No description provided for @vitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get vitaminC;

  /// No description provided for @cat.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get cat;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength '**
  String get strength;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @stVal.
  ///
  /// In en, this message translates to:
  /// **'Strength Value'**
  String get stVal;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// No description provided for @liquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get liquid;

  /// No description provided for @topical.
  ///
  /// In en, this message translates to:
  /// **'Topical'**
  String get topical;

  /// No description provided for @cream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get cream;

  /// No description provided for @drops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get drops;

  /// No description provided for @foam.
  ///
  /// In en, this message translates to:
  /// **'Foam'**
  String get foam;

  /// No description provided for @gel.
  ///
  /// In en, this message translates to:
  /// **'Gel'**
  String get gel;

  /// No description provided for @herbal.
  ///
  /// In en, this message translates to:
  /// **'Herbal'**
  String get herbal;

  /// No description provided for @inhaler.
  ///
  /// In en, this message translates to:
  /// **'Inhaler'**
  String get inhaler;

  /// No description provided for @injection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get injection;

  /// No description provided for @lotion.
  ///
  /// In en, this message translates to:
  /// **'Lotion'**
  String get lotion;

  /// No description provided for @nasalSpray.
  ///
  /// In en, this message translates to:
  /// **'Nasal Spray'**
  String get nasalSpray;

  /// No description provided for @ointment.
  ///
  /// In en, this message translates to:
  /// **'Ointment'**
  String get ointment;

  /// No description provided for @patch.
  ///
  /// In en, this message translates to:
  /// **'Patch'**
  String get patch;

  /// No description provided for @powder.
  ///
  /// In en, this message translates to:
  /// **'Powder'**
  String get powder;

  /// No description provided for @spray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get spray;

  /// No description provided for @suppository.
  ///
  /// In en, this message translates to:
  /// **'Suppository'**
  String get suppository;

  /// No description provided for @dpi.
  ///
  /// In en, this message translates to:
  /// **'Dosage Per Intake'**
  String get dpi;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @apc.
  ///
  /// In en, this message translates to:
  /// **'Available Pill Count '**
  String get apc;

  /// No description provided for @tpc.
  ///
  /// In en, this message translates to:
  /// **'Total Pill Count'**
  String get tpc;

  /// No description provided for @medNote.
  ///
  /// In en, this message translates to:
  /// **'Medication Note '**
  String get medNote;

  /// No description provided for @ufi.
  ///
  /// In en, this message translates to:
  /// **'Using for illness'**
  String get ufi;

  /// No description provided for @medTimes.
  ///
  /// In en, this message translates to:
  /// **'Medication Times'**
  String get medTimes;

  /// No description provided for @tpd.
  ///
  /// In en, this message translates to:
  /// **'time(s) per day'**
  String get tpd;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get addTime;

  /// No description provided for @whenWYTT.
  ///
  /// In en, this message translates to:
  /// **'When will you take this?'**
  String get whenWYTT;

  /// No description provided for @medFreq.
  ///
  /// In en, this message translates to:
  /// **'Medication Frequency'**
  String get medFreq;

  /// No description provided for @sDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get sDate;

  /// No description provided for @eDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get eDate;

  /// No description provided for @aRI.
  ///
  /// In en, this message translates to:
  /// **'At Regular Intervals'**
  String get aRI;

  /// No description provided for @oSDW.
  ///
  /// In en, this message translates to:
  /// **'On Specific Days of the Week'**
  String get oSDW;

  /// No description provided for @cTI.
  ///
  /// In en, this message translates to:
  /// **'Choose the Interval'**
  String get cTI;

  /// No description provided for @freq.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get freq;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @loc.
  ///
  /// In en, this message translates to:
  /// **'Enable Location Services'**
  String get loc;

  /// No description provided for @locSe.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to use this app.'**
  String get locSe;

  /// No description provided for @locD.
  ///
  /// In en, this message translates to:
  /// **'User denied permissions to access the device location.'**
  String get locD;

  /// No description provided for @eD.
  ///
  /// In en, this message translates to:
  /// **'Every Day'**
  String get eD;

  /// No description provided for @e2D.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Days'**
  String get e2D;

  /// No description provided for @e3D.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Days'**
  String get e3D;

  /// No description provided for @e4D.
  ///
  /// In en, this message translates to:
  /// **'Every 4 Days'**
  String get e4D;

  /// No description provided for @e5D.
  ///
  /// In en, this message translates to:
  /// **'Every 5 Days'**
  String get e5D;

  /// No description provided for @e6D.
  ///
  /// In en, this message translates to:
  /// **'Every 6 Days'**
  String get e6D;

  /// No description provided for @eW.
  ///
  /// In en, this message translates to:
  /// **'Every Week (7 Days)'**
  String get eW;

  /// No description provided for @e2W.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Weeks (14 Days)'**
  String get e2W;

  /// No description provided for @e3W.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Weeks (21 Days)'**
  String get e3W;

  /// No description provided for @eM.
  ///
  /// In en, this message translates to:
  /// **'Every Month (30 Days)'**
  String get eM;

  /// No description provided for @e2M.
  ///
  /// In en, this message translates to:
  /// **'Every 2 Months (60 Days)'**
  String get e2M;

  /// No description provided for @e3M.
  ///
  /// In en, this message translates to:
  /// **'Every 3 Months (90 Days)'**
  String get e3M;

  /// No description provided for @sTD.
  ///
  /// In en, this message translates to:
  /// **'Select the Days'**
  String get sTD;

  /// No description provided for @su.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get su;

  /// No description provided for @m.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get m;

  /// No description provided for @t.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get t;

  /// No description provided for @w.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get w;

  /// No description provided for @th.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get th;

  /// No description provided for @f.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get f;

  /// No description provided for @s.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get s;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @medDetails.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION DETAILS'**
  String get medDetails;

  /// No description provided for @medIntake.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION INTAKE'**
  String get medIntake;

  /// No description provided for @medFreQ.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION FREQUENCY'**
  String get medFreQ;

  /// No description provided for @freQ.
  ///
  /// In en, this message translates to:
  /// **'FREQUENCY'**
  String get freQ;

  /// No description provided for @sInt.
  ///
  /// In en, this message translates to:
  /// **'Select Interval'**
  String get sInt;

  /// No description provided for @sDays.
  ///
  /// In en, this message translates to:
  /// **'Select Day(s)'**
  String get sDays;

  /// No description provided for @sMedFreq.
  ///
  /// In en, this message translates to:
  /// **'Select Medication Frequency'**
  String get sMedFreq;

  /// No description provided for @aOneMedTime.
  ///
  /// In en, this message translates to:
  /// **'Add at least one medication time'**
  String get aOneMedTime;

  /// No description provided for @mAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get mAddedSuccess;

  /// No description provided for @pstMedName.
  ///
  /// In en, this message translates to:
  /// **'Please select medication name'**
  String get pstMedName;

  /// No description provided for @pstMedCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select medication category'**
  String get pstMedCategory;

  /// No description provided for @pstStrType.
  ///
  /// In en, this message translates to:
  /// **'Please select strength type'**
  String get pstStrType;

  /// No description provided for @pstStrVal.
  ///
  /// In en, this message translates to:
  /// **'Please enter strength value'**
  String get pstStrVal;

  /// No description provided for @apcGd.
  ///
  /// In en, this message translates to:
  /// **'Available pill count should be greater than the dosage'**
  String get apcGd;

  /// No description provided for @sMedSDate.
  ///
  /// In en, this message translates to:
  /// **'Select medication starting date'**
  String get sMedSDate;

  /// No description provided for @t12H.
  ///
  /// In en, this message translates to:
  /// **'Times in 12 Hour: '**
  String get t12H;

  /// No description provided for @eDMBAFu.
  ///
  /// In en, this message translates to:
  /// **'Ending date must be a future date'**
  String get eDMBAFu;

  /// No description provided for @st24H.
  ///
  /// In en, this message translates to:
  /// **'Selected time in 24-hour format: '**
  String get st24H;

  /// No description provided for @nTS.
  ///
  /// In en, this message translates to:
  /// **'No time selected'**
  String get nTS;

  /// No description provided for @maxMedTPD.
  ///
  /// In en, this message translates to:
  /// **'Maximum medication times per day is 24'**
  String get maxMedTPD;

  /// No description provided for @bSD.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet data: '**
  String get bSD;

  /// No description provided for @aLDT.
  ///
  /// In en, this message translates to:
  /// **'Added log dates and times'**
  String get aLDT;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'si': return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

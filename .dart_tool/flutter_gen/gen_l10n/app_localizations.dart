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
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Paramètres du compte'**
  String get accountSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'Paramètres de l\'application'**
  String get appSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Paramètres de notification'**
  String get notificationSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// No description provided for @termsNconditions.
  ///
  /// In en, this message translates to:
  /// **'Termes et Conditions'**
  String get termsNconditions;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Votre profil'**
  String get yourProfile;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Informations de base'**
  String get basicInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date de naissance'**
  String get dob;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Sexe'**
  String get gender;

  /// No description provided for @nic.
  ///
  /// In en, this message translates to:
  /// **'CIN'**
  String get nic;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Informations de contact'**
  String get contactInfo;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @mobileNo.
  ///
  /// In en, this message translates to:
  /// **'Numéro de mobile'**
  String get mobileNo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Confirmer'**
  String get save;

  /// No description provided for @profileText1.
  ///
  /// In en, this message translates to:
  /// **'Ici, vous pouvez modifier les paramètres de votre profil.'**
  String get profileText1;

  /// No description provided for @profileText2.
  ///
  /// In en, this message translates to:
  /// **'Si vous oubliez votre mot de passe, détendez-vous et essayez de vous en souvenir.'**
  String get profileText2;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Médicaments'**
  String get medications;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get more;

  /// No description provided for @dashText1.
  ///
  /// In en, this message translates to:
  /// **'Vos rappels de médicaments\n seront affichés ici.'**
  String get dashText1;

  /// No description provided for @dashText2.
  ///
  /// In en, this message translates to:
  /// **'Vous n\'avez pas de rappels de médicaments.'**
  String get dashText2;

  /// No description provided for @medicationText1.
  ///
  /// In en, this message translates to:
  /// **'Vos médicaments\n seront affichés ici.'**
  String get medicationText1;

  /// No description provided for @medicationText2.
  ///
  /// In en, this message translates to:
  /// **'Vous n\'avez pas de médicaments.'**
  String get medicationText2;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Ajouter un médicament'**
  String get buttonText;

  /// No description provided for @dashText3.
  ///
  /// In en, this message translates to:
  /// **'Vos alarmes de médicaments\n seront affichées ici'**
  String get dashText3;

  /// No description provided for @presImg.
  ///
  /// In en, this message translates to:
  /// **'Image d\'ordonnance'**
  String get presImg;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies & Hôpitaux à proximité'**
  String get nearby;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'Vérifiez votre IMC'**
  String get bmi;

  /// No description provided for @upalarm.
  ///
  /// In en, this message translates to:
  /// **'Alarmes à venir'**
  String get upalarm;

  /// No description provided for @emgcall.
  ///
  /// In en, this message translates to:
  /// **'Appels d\'urgence'**
  String get emgcall;

  /// No description provided for @reclamation.
  ///
  /// In en, this message translates to:
  /// **'Réclamation'**
  String get reclamation;

  /// No description provided for @housingApplicationForm.
  ///
  /// In en, this message translates to:
  /// **'Formulaire de demande de logement'**
  String get housingApplicationForm;

  /// No description provided for @photoHeading.
  ///
  /// In en, this message translates to:
  /// **'Enregistrez une photo de votre ordonnance'**
  String get photoHeading;

  /// No description provided for @photoText1.
  ///
  /// In en, this message translates to:
  /// **'Téléchargez une photo claire de votre ordonnance'**
  String get photoText1;

  /// No description provided for @photoBtn1.
  ///
  /// In en, this message translates to:
  /// **'Ajouter une photo'**
  String get photoBtn1;

  /// No description provided for @photoBtn2.
  ///
  /// In en, this message translates to:
  /// **'Télécharger'**
  String get photoBtn2;

  /// No description provided for @photoBtn3.
  ///
  /// In en, this message translates to:
  /// **'Parcourir la galerie'**
  String get photoBtn3;

  /// No description provided for @photoBtn4.
  ///
  /// In en, this message translates to:
  /// **'Utiliser la caméra'**
  String get photoBtn4;

  /// No description provided for @photoText2.
  ///
  /// In en, this message translates to:
  /// **'ou'**
  String get photoText2;

  /// No description provided for @nIS.
  ///
  /// In en, this message translates to:
  /// **'Aucune image sélectionnée'**
  String get nIS;

  /// No description provided for @pSAI.
  ///
  /// In en, this message translates to:
  /// **'Veuillez d\'abord sélectionner une image'**
  String get pSAI;

  /// No description provided for @pIAS.
  ///
  /// In en, this message translates to:
  /// **'Image d\'ordonnance téléchargée avec succès'**
  String get pIAS;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Télécharger'**
  String get upload;

  /// No description provided for @dUpload.
  ///
  /// In en, this message translates to:
  /// **'Téléchargement terminé'**
  String get dUpload;

  /// No description provided for @bmiCal.
  ///
  /// In en, this message translates to:
  /// **'Calculateur d\'IMC'**
  String get bmiCal;

  /// No description provided for @bmiText.
  ///
  /// In en, this message translates to:
  /// **'L\'indice de masse corporelle (IMC) est une mesure du pourcentage de graisse corporelle couramment utilisée pour estimer les niveaux de risque de problèmes de santé potentiels.'**
  String get bmiText;

  /// No description provided for @bmiform1.
  ///
  /// In en, this message translates to:
  /// **'Poids'**
  String get bmiform1;

  /// No description provided for @bmiform2.
  ///
  /// In en, this message translates to:
  /// **'Taille'**
  String get bmiform2;

  /// No description provided for @bmiButton.
  ///
  /// In en, this message translates to:
  /// **'Calculer'**
  String get bmiButton;

  /// No description provided for @bmiText1.
  ///
  /// In en, this message translates to:
  /// **'Votre valeur IMC est : '**
  String get bmiText1;

  /// No description provided for @bmiText2.
  ///
  /// In en, this message translates to:
  /// **'Vous êtes en sous-poids !'**
  String get bmiText2;

  /// No description provided for @bmiText3.
  ///
  /// In en, this message translates to:
  /// **'Vous êtes en bonne santé !'**
  String get bmiText3;

  /// No description provided for @bmiText4.
  ///
  /// In en, this message translates to:
  /// **'Vous êtes en surpoids !'**
  String get bmiText4;

  /// No description provided for @bmiText5.
  ///
  /// In en, this message translates to:
  /// **'Poids idéal : '**
  String get bmiText5;

  /// No description provided for @bmiText6.
  ///
  /// In en, this message translates to:
  /// **'Veuillez entrer votre poids'**
  String get bmiText6;

  /// No description provided for @bmiText7.
  ///
  /// In en, this message translates to:
  /// **'Veuillez entrer votre taille'**
  String get bmiText7;

  /// No description provided for @ssa.
  ///
  /// In en, this message translates to:
  /// **'Ambulance Suwa Seriya'**
  String get ssa;

  /// No description provided for @as.
  ///
  /// In en, this message translates to:
  /// **'Service d\'accidents'**
  String get as;

  /// No description provided for @pi.
  ///
  /// In en, this message translates to:
  /// **'Urgence Police'**
  String get pi;

  /// No description provided for @fi.
  ///
  /// In en, this message translates to:
  /// **'Incendie & Sauvetage'**
  String get fi;

  /// No description provided for @gv.
  ///
  /// In en, this message translates to:
  /// **'Centre d\'information gouvernemental'**
  String get gv;

  /// No description provided for @eps.
  ///
  /// In en, this message translates to:
  /// **'Escouade de Police d\'Urgence'**
  String get eps;

  /// No description provided for @ctL.
  ///
  /// In en, this message translates to:
  /// **'Impossible de lancer'**
  String get ctL;

  /// No description provided for @ddUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage quotidien'**
  String get ddUsage;

  /// No description provided for @wdUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage hebdomadaire'**
  String get wdUsage;

  /// No description provided for @addMed.
  ///
  /// In en, this message translates to:
  /// **'Ajouter un médicament'**
  String get addMed;

  /// No description provided for @medName.
  ///
  /// In en, this message translates to:
  /// **'Nom du médicament'**
  String get medName;

  /// No description provided for @vitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamine C'**
  String get vitaminC;

  /// No description provided for @cat.
  ///
  /// In en, this message translates to:
  /// **'Catégorie'**
  String get cat;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Force'**
  String get strength;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Effacer'**
  String get clear;

  /// No description provided for @stVal.
  ///
  /// In en, this message translates to:
  /// **'Valeur de la force'**
  String get stVal;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optionnel)'**
  String get optional;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Comprimé'**
  String get tablet;

  /// No description provided for @liquid.
  ///
  /// In en, this message translates to:
  /// **'Liquide'**
  String get liquid;

  /// No description provided for @topical.
  ///
  /// In en, this message translates to:
  /// **'Topique'**
  String get topical;

  /// No description provided for @cream.
  ///
  /// In en, this message translates to:
  /// **'Crème'**
  String get cream;

  /// No description provided for @drops.
  ///
  /// In en, this message translates to:
  /// **'Gouttes'**
  String get drops;

  /// No description provided for @foam.
  ///
  /// In en, this message translates to:
  /// **'Mousse'**
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
  /// **'Inhalateur'**
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
  /// **'Spray nasal'**
  String get nasalSpray;

  /// No description provided for @ointment.
  ///
  /// In en, this message translates to:
  /// **'Pommade'**
  String get ointment;

  /// No description provided for @patch.
  ///
  /// In en, this message translates to:
  /// **'Patch'**
  String get patch;

  /// No description provided for @powder.
  ///
  /// In en, this message translates to:
  /// **'Poudre'**
  String get powder;

  /// No description provided for @spray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get spray;

  /// No description provided for @suppository.
  ///
  /// In en, this message translates to:
  /// **'Suppositoire'**
  String get suppository;

  /// No description provided for @dpi.
  ///
  /// In en, this message translates to:
  /// **'Dosage par prise'**
  String get dpi;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Nombre'**
  String get count;

  /// No description provided for @apc.
  ///
  /// In en, this message translates to:
  /// **'Nombre de pilules disponibles'**
  String get apc;

  /// No description provided for @tpc.
  ///
  /// In en, this message translates to:
  /// **'Nombre total de pilules'**
  String get tpc;

  /// No description provided for @medNote.
  ///
  /// In en, this message translates to:
  /// **'Note de médicament'**
  String get medNote;

  /// No description provided for @ufi.
  ///
  /// In en, this message translates to:
  /// **'Utilisé pour la maladie'**
  String get ufi;

  /// No description provided for @medTimes.
  ///
  /// In en, this message translates to:
  /// **'Heures de prise'**
  String get medTimes;

  /// No description provided for @tpd.
  ///
  /// In en, this message translates to:
  /// **'fois par jour'**
  String get tpd;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Ajouter une heure'**
  String get addTime;

  /// No description provided for @whenWYTT.
  ///
  /// In en, this message translates to:
  /// **'Quand allez-vous prendre ceci?'**
  String get whenWYTT;

  /// No description provided for @medFreq.
  ///
  /// In en, this message translates to:
  /// **'Fréquence du médicament'**
  String get medFreq;

  /// No description provided for @sDate.
  ///
  /// In en, this message translates to:
  /// **'Date de début'**
  String get sDate;

  /// No description provided for @eDate.
  ///
  /// In en, this message translates to:
  /// **'Date de fin'**
  String get eDate;

  /// No description provided for @aRI.
  ///
  /// In en, this message translates to:
  /// **'À intervalles réguliers'**
  String get aRI;

  /// No description provided for @oSDW.
  ///
  /// In en, this message translates to:
  /// **'Les jours spécifiques de la semaine'**
  String get oSDW;

  /// No description provided for @cTI.
  ///
  /// In en, this message translates to:
  /// **'Choisissez l\'intervalle'**
  String get cTI;

  /// No description provided for @freq.
  ///
  /// In en, this message translates to:
  /// **'Fréquence'**
  String get freq;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Activer'**
  String get enable;

  /// No description provided for @loc.
  ///
  /// In en, this message translates to:
  /// **'Activer les services de localisation'**
  String get loc;

  /// No description provided for @locSe.
  ///
  /// In en, this message translates to:
  /// **'Veuillez activer les services de localisation pour utiliser cette application.'**
  String get locSe;

  /// No description provided for @locD.
  ///
  /// In en, this message translates to:
  /// **'L\'utilisateur a refusé les autorisations d\'accès à la localisation de l\'appareil.'**
  String get locD;

  /// No description provided for @eD.
  ///
  /// In en, this message translates to:
  /// **'Tous les jours'**
  String get eD;

  /// No description provided for @e2D.
  ///
  /// In en, this message translates to:
  /// **'Tous les 2 jours'**
  String get e2D;

  /// No description provided for @e3D.
  ///
  /// In en, this message translates to:
  /// **'Tous les 3 jours'**
  String get e3D;

  /// No description provided for @e4D.
  ///
  /// In en, this message translates to:
  /// **'Tous les 4 jours'**
  String get e4D;

  /// No description provided for @e5D.
  ///
  /// In en, this message translates to:
  /// **'Tous les 5 jours'**
  String get e5D;

  /// No description provided for @e6D.
  ///
  /// In en, this message translates to:
  /// **'Tous les 6 jours'**
  String get e6D;

  /// No description provided for @eW.
  ///
  /// In en, this message translates to:
  /// **'Toutes les semaines (7 jours)'**
  String get eW;

  /// No description provided for @e2W.
  ///
  /// In en, this message translates to:
  /// **'Toutes les 2 semaines (14 jours)'**
  String get e2W;

  /// No description provided for @e3W.
  ///
  /// In en, this message translates to:
  /// **'Toutes les 3 semaines (21 jours)'**
  String get e3W;

  /// No description provided for @eM.
  ///
  /// In en, this message translates to:
  /// **'Tous les mois (30 jours)'**
  String get eM;

  /// No description provided for @e2M.
  ///
  /// In en, this message translates to:
  /// **'Tous les 2 mois (60 jours)'**
  String get e2M;

  /// No description provided for @e3M.
  ///
  /// In en, this message translates to:
  /// **'Tous les 3 mois (90 jours)'**
  String get e3M;

  /// No description provided for @sTD.
  ///
  /// In en, this message translates to:
  /// **'Sélectionnez les jours'**
  String get sTD;

  /// No description provided for @su.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get su;

  /// No description provided for @m.
  ///
  /// In en, this message translates to:
  /// **'Lun'**
  String get m;

  /// No description provided for @t.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get t;

  /// No description provided for @w.
  ///
  /// In en, this message translates to:
  /// **'Mer'**
  String get w;

  /// No description provided for @th.
  ///
  /// In en, this message translates to:
  /// **'Jeu'**
  String get th;

  /// No description provided for @f.
  ///
  /// In en, this message translates to:
  /// **'Ven'**
  String get f;

  /// No description provided for @s.
  ///
  /// In en, this message translates to:
  /// **'Sam'**
  String get s;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Résumé'**
  String get summary;

  /// No description provided for @medDetails.
  ///
  /// In en, this message translates to:
  /// **'DÉTAILS DU MÉDICAMENT'**
  String get medDetails;

  /// No description provided for @medIntake.
  ///
  /// In en, this message translates to:
  /// **'PRISE DU MÉDICAMENT'**
  String get medIntake;

  /// No description provided for @medFreQ.
  ///
  /// In en, this message translates to:
  /// **'FRÉQUENCE DU MÉDICAMENT'**
  String get medFreQ;

  /// No description provided for @freQ.
  ///
  /// In en, this message translates to:
  /// **'FRÉQUENCE'**
  String get freQ;

  /// No description provided for @sInt.
  ///
  /// In en, this message translates to:
  /// **'Sélectionnez l\'intervalle'**
  String get sInt;

  /// No description provided for @sDays.
  ///
  /// In en, this message translates to:
  /// **'Sélectionnez le(s) jour(s)'**
  String get sDays;

  /// No description provided for @sMedFreq.
  ///
  /// In en, this message translates to:
  /// **'Sélectionnez la fréquence du médicament'**
  String get sMedFreq;

  /// No description provided for @aOneMedTime.
  ///
  /// In en, this message translates to:
  /// **'Ajoutez au moins un temps de médicament'**
  String get aOneMedTime;

  /// No description provided for @mAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Médicament ajouté avec succès'**
  String get mAddedSuccess;

  /// No description provided for @pstMedName.
  ///
  /// In en, this message translates to:
  /// **'Veuillez sélectionner le nom du médicament'**
  String get pstMedName;

  /// No description provided for @pstMedCategory.
  ///
  /// In en, this message translates to:
  /// **'Veuillez sélectionner la catégorie du médicament'**
  String get pstMedCategory;

  /// No description provided for @pstStrType.
  ///
  /// In en, this message translates to:
  /// **'Veuillez sélectionner le type de force'**
  String get pstStrType;

  /// No description provided for @pstStrVal.
  ///
  /// In en, this message translates to:
  /// **'Veuillez entrer la valeur de la force'**
  String get pstStrVal;

  /// No description provided for @apcGd.
  ///
  /// In en, this message translates to:
  /// **'Le nombre de pilules disponibles doit être supérieur au dosage'**
  String get apcGd;

  /// No description provided for @sMedSDate.
  ///
  /// In en, this message translates to:
  /// **'Sélectionnez la date de début du médicament'**
  String get sMedSDate;

  /// No description provided for @t12H.
  ///
  /// In en, this message translates to:
  /// **'Heures au format 12 heures : '**
  String get t12H;

  /// No description provided for @eDMBAFu.
  ///
  /// In en, this message translates to:
  /// **'La date de fin doit être une date future'**
  String get eDMBAFu;

  /// No description provided for @st24H.
  ///
  /// In en, this message translates to:
  /// **'Heure sélectionnée au format 24 heures : '**
  String get st24H;

  /// No description provided for @nTS.
  ///
  /// In en, this message translates to:
  /// **'Aucune heure sélectionnée'**
  String get nTS;

  /// No description provided for @maxMedTPD.
  ///
  /// In en, this message translates to:
  /// **'Nombre maximum de prises de médicaments par jour est de 24'**
  String get maxMedTPD;

  /// No description provided for @bSD.
  ///
  /// In en, this message translates to:
  /// **'Données de la feuille inférieure : '**
  String get bSD;

  /// No description provided for @aLDT.
  ///
  /// In en, this message translates to:
  /// **'Dates et heures des journaux ajoutés'**
  String get aLDT;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'Cette semaine'**
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

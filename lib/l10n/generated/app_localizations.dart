import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @audio.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get audio;

  /// No description provided for @music.
  ///
  /// In tr, this message translates to:
  /// **'Müzik'**
  String get music;

  /// No description provided for @soundEffects.
  ///
  /// In tr, this message translates to:
  /// **'Ses Efektleri'**
  String get soundEffects;

  /// No description provided for @answersAlwaysEnglish.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplar her zaman İngilizcedir.'**
  String get answersAlwaysEnglish;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @puzzles.
  ///
  /// In tr, this message translates to:
  /// **'Bulmacalar'**
  String get puzzles;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get daily;

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @appearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get system;

  /// No description provided for @light.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get dark;

  /// No description provided for @appInformation.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama bilgileri'**
  String get appInformation;

  /// No description provided for @easy.
  ///
  /// In tr, this message translates to:
  /// **'Kolay'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In tr, this message translates to:
  /// **'Zor'**
  String get hard;

  /// No description provided for @puzzle.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca'**
  String get puzzle;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @check.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol Et'**
  String get check;

  /// No description provided for @continueGame.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueGame;

  /// No description provided for @start.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get start;

  /// No description provided for @replay.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Oyna'**
  String get replay;

  /// No description provided for @replayLower.
  ///
  /// In tr, this message translates to:
  /// **'tekrar oyna'**
  String get replayLower;

  /// No description provided for @play.
  ///
  /// In tr, this message translates to:
  /// **'Oyna'**
  String get play;

  /// No description provided for @resume.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get resume;

  /// No description provided for @dailyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün Bulmacası'**
  String get dailyTitle;

  /// No description provided for @dailyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Geçmiş'**
  String get dailyHistory;

  /// No description provided for @seeResult.
  ///
  /// In tr, this message translates to:
  /// **'Sonucu Gör'**
  String get seeResult;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @returnHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfaya Dön'**
  String get returnHome;

  /// No description provided for @returnPuzzles.
  ///
  /// In tr, this message translates to:
  /// **'Bulmacalara Dön'**
  String get returnPuzzles;

  /// No description provided for @chooseDifficulty.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk Seç'**
  String get chooseDifficulty;

  /// No description provided for @viewPuzzles.
  ///
  /// In tr, this message translates to:
  /// **'Bulmacaları Gör'**
  String get viewPuzzles;

  /// No description provided for @nextPuzzle.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki Bulmaca'**
  String get nextPuzzle;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get back;

  /// No description provided for @closeSession.
  ///
  /// In tr, this message translates to:
  /// **'Oturumu Kapat'**
  String get closeSession;

  /// No description provided for @restart.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Başla'**
  String get restart;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @locked.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get locked;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @completedLower.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get completedLower;

  /// No description provided for @score.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get score;

  /// No description provided for @time.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get time;

  /// No description provided for @hints.
  ///
  /// In tr, this message translates to:
  /// **'İpucu'**
  String get hints;

  /// No description provided for @wrongChecks.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı kontrol'**
  String get wrongChecks;

  /// No description provided for @best.
  ///
  /// In tr, this message translates to:
  /// **'En iyi'**
  String get best;

  /// No description provided for @thisAttempt.
  ///
  /// In tr, this message translates to:
  /// **'Bu deneme'**
  String get thisAttempt;

  /// No description provided for @newRecord.
  ///
  /// In tr, this message translates to:
  /// **'Yeni rekor!'**
  String get newRecord;

  /// No description provided for @puzzleCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca tamamlandı!'**
  String get puzzleCompleted;

  /// No description provided for @dailyCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Günün bulmacası tamamlandı!'**
  String get dailyCompleted;

  /// No description provided for @rewardHint.
  ///
  /// In tr, this message translates to:
  /// **'Reklamla Harf Aç'**
  String get rewardHint;

  /// No description provided for @adLoading.
  ///
  /// In tr, this message translates to:
  /// **'Reklam hazırlanıyor'**
  String get adLoading;

  /// No description provided for @adUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Reklam şu anda hazır değil. Lütfen tekrar deneyin.'**
  String get adUnavailable;

  /// No description provided for @puzzleLoading.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca hazırlanıyor…'**
  String get puzzleLoading;

  /// No description provided for @puzzlePreparing.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca hazırlanıyor'**
  String get puzzlePreparing;

  /// No description provided for @dailyPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Günün bulmacası hazırlanıyor'**
  String get dailyPreparing;

  /// No description provided for @generationError.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca şu anda hazırlanamadı. Tekrar deneyin.'**
  String get generationError;

  /// No description provided for @shareError.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç paylaşılamadı. Lütfen tekrar deneyin.'**
  String get shareError;

  /// No description provided for @dailyUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Günlük bulmaca bu oturumda kullanılamıyor.'**
  String get dailyUnavailable;

  /// No description provided for @emptyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanan günlük bulmaca yok.'**
  String get emptyHistory;

  /// No description provided for @noScore.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yok'**
  String get noScore;

  /// No description provided for @completedPuzzles.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan bulmaca'**
  String get completedPuzzles;

  /// No description provided for @scoredPuzzles.
  ///
  /// In tr, this message translates to:
  /// **'Puanlanan bulmaca'**
  String get scoredPuzzles;

  /// No description provided for @totalScore.
  ///
  /// In tr, this message translates to:
  /// **'Toplam puan'**
  String get totalScore;

  /// No description provided for @averageScore.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama puan'**
  String get averageScore;

  /// No description provided for @bestScore.
  ///
  /// In tr, this message translates to:
  /// **'En iyi puan'**
  String get bestScore;

  /// No description provided for @hintFree.
  ///
  /// In tr, this message translates to:
  /// **'İpuçsuz tamamlanan'**
  String get hintFree;

  /// No description provided for @errorFree.
  ///
  /// In tr, this message translates to:
  /// **'Hatasız tamamlanan'**
  String get errorFree;

  /// No description provided for @dailyStatistics.
  ///
  /// In tr, this message translates to:
  /// **'Günlük bulmacalar'**
  String get dailyStatistics;

  /// No description provided for @dailyCount.
  ///
  /// In tr, this message translates to:
  /// **'Günlük tamamlanan'**
  String get dailyCount;

  /// No description provided for @currentStreak.
  ///
  /// In tr, this message translates to:
  /// **'Güncel seri'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In tr, this message translates to:
  /// **'En uzun seri'**
  String get longestStreak;

  /// No description provided for @statisticsIntro.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan bulmacalar ve kaydedilen en iyi puanlar.'**
  String get statisticsIntro;

  /// No description provided for @statisticsExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Puan istatistikleri her bulmacanın kaydedilen en iyi sonucunu kullanır. Puanı olmayan eski tamamlamalar yalnızca tamamlanan bulmaca sayısına eklenir.'**
  String get statisticsExplanation;

  /// No description provided for @withinDifficulty.
  ///
  /// In tr, this message translates to:
  /// **'Puanlar aynı zorluk içinde karşılaştırılır.'**
  String get withinDifficulty;

  /// No description provided for @hintLocked.
  ///
  /// In tr, this message translates to:
  /// **'İpucuyla açıldı, kilitli'**
  String get hintLocked;

  /// No description provided for @development.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirme · İlerleme kaydedilmez'**
  String get development;

  /// No description provided for @allCorrect.
  ///
  /// In tr, this message translates to:
  /// **'Tüm harfler doğru.'**
  String get allCorrect;

  /// No description provided for @legacyScore.
  ///
  /// In tr, this message translates to:
  /// **'Bu bulmaca puanlama eklenmeden önce tamamlandı.'**
  String get legacyScore;

  /// No description provided for @appDescription.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe ipuçlarıyla İngilizce kelimeleri keşfedin. Normal bulmacalar, tekrar oynama ve günün bulmacası.'**
  String get appDescription;

  /// No description provided for @workingName.
  ///
  /// In tr, this message translates to:
  /// **'Arrowword çalışma adıdır; nihai ürün adı henüz belirlenmedi.'**
  String get workingName;

  /// No description provided for @versionLoading.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm bilgisi yükleniyor…'**
  String get versionLoading;

  /// No description provided for @versionUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm bilgisi şu anda alınamıyor.'**
  String get versionUnavailable;

  /// No description provided for @puzzleNumber.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca {number}'**
  String puzzleNumber(int number);

  /// No description provided for @trackPuzzle.
  ///
  /// In tr, this message translates to:
  /// **'{difficulty} · Bulmaca {number}'**
  String trackPuzzle(String difficulty, int number);

  /// No description provided for @replayPuzzle.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca {number} · Tekrar Oyna'**
  String replayPuzzle(int number);

  /// No description provided for @trackFinished.
  ///
  /// In tr, this message translates to:
  /// **'{difficulty} seviye tamamlandı!'**
  String trackFinished(String difficulty);

  /// No description provided for @progress.
  ///
  /// In tr, this message translates to:
  /// **'{completed} / {total} tamamlandı'**
  String progress(int completed, int total);

  /// No description provided for @scorePoints.
  ///
  /// In tr, this message translates to:
  /// **'{score} puan'**
  String scorePoints(int score);

  /// No description provided for @todayCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Bugün tamamlandı · {score} puan'**
  String todayCompleted(int score);

  /// No description provided for @streakDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} günlük seri'**
  String streakDays(int count);

  /// No description provided for @completedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} bulmaca tamamlandı'**
  String completedCount(int count);

  /// No description provided for @versionBuild.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version} · Yapı {build}'**
  String versionBuild(String version, String build);

  /// No description provided for @bestDetail.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca {number} · {seconds} sn'**
  String bestDetail(int number, int seconds);

  /// No description provided for @legacyDetail.
  ///
  /// In tr, this message translates to:
  /// **'Eski kayıt · {seconds} sn'**
  String legacyDetail(int seconds);

  /// No description provided for @dailyDetails.
  ///
  /// In tr, this message translates to:
  /// **'{duration} · {hints} ipucu · {checks} hatalı kontrol'**
  String dailyDetails(String duration, int hints, int checks);

  /// No description provided for @clueLength.
  ///
  /// In tr, this message translates to:
  /// **'{clue} ({length})'**
  String clueLength(String clue, int length);

  /// No description provided for @clueSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{clue}, {length} harf, {direction}'**
  String clueSemantics(String clue, int length, String direction);

  /// No description provided for @right.
  ///
  /// In tr, this message translates to:
  /// **'sağa'**
  String get right;

  /// No description provided for @down.
  ///
  /// In tr, this message translates to:
  /// **'aşağı'**
  String get down;

  /// No description provided for @tileSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca {number}, {status}{completed, select, yes{, tamamlandı} other{}}{scored, select, yes{, {score} puan} other{}}{replayable, select, yes{, tekrar oyna} other{}}'**
  String tileSemantics(
    int number,
    String status,
    String completed,
    String scored,
    int score,
    String replayable,
  );

  /// No description provided for @resultDetails.
  ///
  /// In tr, this message translates to:
  /// **'{label}: {score}\n{hasBest, select, yes{En iyi: {best}\n} other{}}Süre: {duration}\nİpucu: {hints}\nHatalı kontrol: {checks}'**
  String resultDetails(
    String label,
    int score,
    String hasBest,
    int best,
    String duration,
    int hints,
    int checks,
  );

  /// No description provided for @dailyShare.
  ///
  /// In tr, this message translates to:
  /// **'Arrowword — Günün Bulmacası\n{date}\n\nPuan: {score}\nSüre: {duration}\nİpucu: {hints}\nHatalı kontrol: {checks}{hasStreak, select, yes{\nSeri: {streak} gün} other{}}'**
  String dailyShare(
    String date,
    int score,
    String duration,
    int hints,
    int checks,
    String hasStreak,
    int streak,
  );

  /// No description provided for @dateDisplay.
  ///
  /// In tr, this message translates to:
  /// **'{day} {month} {year}'**
  String dateDisplay(int day, String month, int year);

  /// No description provided for @clueUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'İpucu şu anda gösterilemiyor.'**
  String get clueUnavailable;

  /// No description provided for @uiPreview.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirme · Yalnızca arayüz İngilizce'**
  String get uiPreview;

  /// No description provided for @invalidDevConfig.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirme bulmacası açılamadı.\nARROWWORD_PUZZLE_INDEX 1–{count} arasında olmalı.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium veya hard.'**
  String invalidDevConfig(int count);

  /// No description provided for @month1.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get month1;

  /// No description provided for @month2.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get month2;

  /// No description provided for @month3.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get month3;

  /// No description provided for @month4.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get month4;

  /// No description provided for @month5.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get month5;

  /// No description provided for @month6.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get month6;

  /// No description provided for @month7.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get month7;

  /// No description provided for @month8.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get month8;

  /// No description provided for @month9.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get month9;

  /// No description provided for @month10.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get month12;

  /// No description provided for @versionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm bilgisi alınamadı.'**
  String get versionFailed;

  /// No description provided for @puzzleGenerationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca oluşturulamadı. Lütfen tekrar deneyin.'**
  String get puzzleGenerationFailed;

  /// No description provided for @replayGenerationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bulmaca tekrar oluşturulamadı. Lütfen tekrar deneyin.'**
  String get replayGenerationFailed;

  /// No description provided for @dailyGenerationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Günün bulmacası oluşturulamadı. Lütfen tekrar deneyin.'**
  String get dailyGenerationFailed;

  /// No description provided for @legacyScoringMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu bulmaca puanlama sistemi eklenmeden önce tamamlandı.'**
  String get legacyScoringMessage;

  /// No description provided for @restartGame.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Başlat'**
  String get restartGame;

  /// No description provided for @emptyProgress.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanan bulmaca yok'**
  String get emptyProgress;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Varsayılanı'**
  String get systemDefault;

  /// No description provided for @englishName.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get englishName;

  /// No description provided for @turkishName.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkishName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

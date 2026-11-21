import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

/// Lightweight EN/RU copy (arb-backed keys without codegen).
class S {
  S._(this._ru);
  final bool _ru;

  static S of(BuildContext context) {
    final loc = LocaleControllerScope.maybeOf(context);
    return S._(loc?.isRu ?? false);
  }

  static S from(LocaleController c) => S._(c.isRu);

  String get appName => 'WAMemory';
  String get chats => _ru ? 'Чаты' : 'Chats';
  String get updates => _ru ? 'Статусы' : 'Updates';
  String get communities => _ru ? 'Сообщества' : 'Communities';
  String get calls => _ru ? 'Звонки' : 'Calls';
  String get deleted => _ru ? 'Удалённые' : 'Deleted';
  String get settings => _ru ? 'Настройки' : 'Settings';
  String get searchHint =>
      _ru ? 'Поиск чатов и сообщений' : 'Search chats & messages';
  String get typeHere => _ru ? 'Сообщение' : 'Type here';
  String get noChats =>
      _ru ? 'Пока нет архивных чатов' : 'No archived chats yet';
  String get enableNotifications =>
      _ru ? 'Включить доступ к уведомлениям' : 'Enable Notification Access';
  String get enableNotificationsBody => _ru
      ? 'WAMemory нужен доступ к уведомлениям, чтобы сохранять сообщения WhatsApp.'
      : 'Enable Notification Access to archive WhatsApp messages automatically.';
  String get enable => _ru ? 'Включить' : 'Enable';
  String get language => _ru ? 'Язык' : 'Language';
  String get english => 'English';
  String get russian => 'Русский';
  String get comingSoon =>
      _ru ? 'Скоро в следующем обновлении' : 'Coming in a later update';
  String get linkToSend => _ru
      ? 'Сначала Settings → Connect WhatsApp'
      : 'Link WhatsApp in Settings → Connect to send live.';
  String get sentLive => _ru ? 'Отправлено' : 'Sent via WhatsApp link';
  String get mediaSent => _ru ? 'Медиа отправлено' : 'Media sent';
  String get photo => _ru ? 'Фото' : 'Photo';
  String get video => _ru ? 'Видео' : 'Video';
  String get voice => _ru ? 'Голосовой' : 'Voice';
  String get audio => _ru ? 'Аудио' : 'Audio';
  String get document => _ru ? 'Документ' : 'Document';
  String get refreshArchive => _ru ? 'Обновить архив' : 'Refresh archive';
  String get deletedMessages =>
      _ru ? 'Удалённые сообщения' : 'Deleted messages';
  String get ok => 'OK';
  String get cancel => _ru ? 'Отмена' : 'Cancel';
  String get save => _ru ? 'Сохранить' : 'Save';
  String get create => _ru ? 'Создать' : 'Create';
  String get delete => _ru ? 'Удалить' : 'Delete';
  String get more => _ru ? 'Ещё' : 'More';
  String get noPreview => _ru ? 'Нет превью' : 'No preview';

  // Updates / Status
  String get statusSection => _ru ? 'Статус' : 'Status';
  String get myStatus => _ru ? 'Мой статус' : 'My status';
  String get tapToAddStatus =>
      _ru ? 'Нажмите, чтобы добавить статус' : 'Tap to add a status update';
  String get recentUpdates => _ru ? 'Недавние' : 'Recent updates';
  String get channels => _ru ? 'Каналы' : 'Channels';
  String get channelsBody => _ru
      ? 'Каналы Meta здесь не синхронизируются. WAMemory хранит локальный архив чатов.'
      : 'Meta Channels are not synced here. WAMemory keeps your local chat archive.';
  String get channelsLocalOnly => _ru
      ? 'Поиск каналов Meta — позже. Сейчас доступны архивные чаты.'
      : 'Meta channel search later. Archived chats work now.';
  String get findChannels => _ru ? 'Найти каналы' : 'Find channels';
  String get statusSearchHint => _ru
      ? 'Поиск статусов — в следующем обновлении'
      : 'Status search comes in a later update';
  String get statusPrivacy => _ru ? 'Конфиденциальность статуса' : 'Status privacy';
  String get statusPrivacyBody => _ru
      ? 'Статус хранится только на этом устройстве в WAMemory. Он не публикуется в WhatsApp.'
      : 'Status text stays on this device inside WAMemory. It is not posted to WhatsApp.';

  // Communities
  String get communitiesBody => _ru
      ? 'Локальные сообщества для организации архива. Это не Meta Communities.'
      : 'Local communities to organise your archive. Not Meta Communities.';
  String get newCommunity => _ru ? 'Новое сообщество' : 'New community';
  String get noCommunities =>
      _ru ? 'Пока нет сообществ' : 'No communities yet';
  String get noCommunitiesHint => _ru
      ? 'Создайте локальную группу, чтобы упорядочить архив.'
      : 'Create a local group to organise your archive.';
  String get communityNameHint =>
      _ru ? 'Название сообщества' : 'Community name';
  String get communityLocal =>
      _ru ? 'Локально на устройстве' : 'Local on this device';
  String get communityDetail => _ru
      ? 'Это локальная метка WAMemory. Чаты Meta Communities не подтягиваются.'
      : 'This is a WAMemory local label. Meta Community chats are not imported.';

  // Calls
  String get callsBody => _ru
      ? 'Журнал звонков локальный. Настоящие VoIP-звонки WhatsApp не выполняются.'
      : 'Call log is local. Real WhatsApp VoIP is not placed from WAMemory.';
  String get noCalls => _ru ? 'Пока нет звонков' : 'No calls yet';
  String get noCallsHint => _ru
      ? 'Выберите контакт ниже или откройте чат и нажмите кнопку звонка.'
      : 'Pick a contact below or open a chat and tap the call button.';
  String get favourites => _ru ? 'Избранные' : 'Favourites';
  String get tapToCall =>
      _ru ? 'Нажмите, чтобы записать звонок' : 'Tap to log a call';
  String get callLoggedBody => _ru
      ? 'Звонок записан в журнал. Реальный VoIP не запускается — откройте чат для сообщения.'
      : 'Call logged. Real VoIP is not started — open the chat to message.';
  String get openChat => _ru ? 'Открыть чат' : 'Open chat';

  // Help / settings
  String get support => _ru ? 'Поддержка' : 'Support';
  String get feedbackIntro => _ru
      ? 'Напишите отзыв — он сохранится на устройстве до запуска канала поддержки.'
      : 'Send feedback — saved on device until the support channel launches.';
  String get feedbackHint =>
      _ru ? 'Что улучшить в WAMemory?' : 'What should we improve in WAMemory?';
  String get feedbackEmpty =>
      _ru ? 'Сначала введите текст' : 'Type feedback first';
  String get feedbackSaved =>
      _ru ? 'Отзыв сохранён на устройстве' : 'Feedback saved on device';
  String get sendFeedback => _ru ? 'Отправить отзыв' : 'Send feedback';
  String get feedbackHistory => _ru ? 'ИСТОРИЯ' : 'HISTORY';

  String get premiumTitle => 'WAMemory Premium';
  String get premiumHeadline =>
      _ru ? '\$5 / месяц · 7 дней пробный' : '\$5 / month · 7-day trial';
  String get premiumBody => _ru
      ? 'Один аккаунт WhatsApp, локальный архив и квота медиа ~2 ГБ (план).'
      : 'One WhatsApp account, local archive, and ~2 GB media quota (planned).';
  String get premiumBullet1 =>
      _ru ? 'Архив удалённых сообщений остаётся в WAMemory' : 'Deleted copies stay inside WAMemory';
  String get premiumBullet2 =>
      _ru ? 'Live link через Evolution (риск бана)' : 'Live link via Evolution (ban risk)';
  String get premiumBullet3 =>
      _ru ? 'Оплата подключается в следующем milestone' : 'Checkout lands in the next billing milestone';
  String get premiumCheckoutSoon => _ru
      ? 'Оплата (Lemon Squeezy / Paddle) ещё не подключена. Пробный период будет доступен после биллинга.'
      : 'Checkout (Lemon Squeezy / Paddle) is not wired yet. Trial starts after billing lands.';
  String get startTrial => _ru ? 'Начать пробный период' : 'Start trial';

  String get retentionTitle => _ru ? 'Хранение' : 'Retention';
  String get retentionBody => _ru
      ? 'Выберите, сколько дней хранить архив. Автоочистка появится позже — настройка уже сохраняется.'
      : 'Choose how long to keep the archive. Auto-purge comes later — your preference is saved now.';
  String get retentionHint =>
      _ru ? 'Сохраняется на устройстве' : 'Saved on this device';
  String retentionDays(int d) =>
      _ru ? '$d дней' : '$d days';

  // Chat detail menus
  String get viewContact => _ru ? 'Контакт' : 'View contact';
  String get searchInChat => _ru ? 'Поиск в чате' : 'Search in chat';
  String get mediaLinksDocs =>
      _ru ? 'Медиа, ссылки и документы' : 'Media, links, and docs';
  String get muteNotifications =>
      _ru ? 'Без уведомлений' : 'Mute notifications';
  String get wallpaper => _ru ? 'Обои' : 'Wallpaper';
  String get clearChatLocal =>
      _ru ? 'Очистить локальный чат' : 'Clear local chat';
  String get callFromChat => _ru ? 'Позвонить' : 'Call';
  String get videoCallFromChat => _ru ? 'Видеозвонок' : 'Video call';

  // Setup guide
  String get setupGuide => _ru ? 'Инструкция' : 'Setup guide';
  String get setupGuideSubtitle => _ru
      ? 'Как настроить телефон и WAMemory'
      : 'How to set up your phone and WAMemory';
  String get setupGuideIntro => _ru
      ? 'После установки выполните эти шаги. Архив работает на этом телефоне; API нужен для Connect.'
      : 'After install, follow these steps. Archive runs on this phone; API is needed for Connect.';
  String get setupStep1Title =>
      _ru ? '1. Установите APK' : '1. Install the APK';
  String get setupStep1Body => _ru
      ? 'Скачайте APK с Contabo страницы загрузки и разрешите установку из неизвестных источников.'
      : 'Download the APK from the Contabo download page and allow install from unknown sources.';
  String get setupStep2Title =>
      _ru ? '2. Доступ к уведомлениям' : '2. Notification Access';
  String get setupStep2Body => _ru
      ? 'Settings → Notification access → включите WAMemory. Так WhatsApp сообщения архивируются (Path A).'
      : 'Settings → Notification access → enable WAMemory. This archives WhatsApp alerts (Path A).';
  String get setupStep3Title =>
      _ru ? '3. Профиль' : '3. Your profile';
  String get setupStep3Body => _ru
      ? 'Settings → Account / профиль: имя, фото, номер. Это только внутри WAMemory.'
      : 'Settings → Account / profile: name, photo, phone. Shown only inside WAMemory.';
  String get setupStep4Title =>
      _ru ? '4. API URL (Connect)' : '4. API URL (Connect)';
  String get setupStep4Body => _ru
      ? 'Settings → Linked devices. API по умолчанию: http://13.140.202.159:8090/api. Contabo API должен быть online.'
      : 'Settings → Linked devices. Default API: http://13.140.202.159:8090/api. Contabo API must be online.';
  String get setupStep5Title =>
      _ru ? '5. Connect WhatsApp (опционально)' : '5. Connect WhatsApp (optional)';
  String get setupStep5Body => _ru
      ? 'Path B (Evolution) — неофициально, риск бана. Лучше тестовый номер. QR / код сопряжения.'
      : 'Path B (Evolution) is unofficial — ban risk. Prefer a test number. Use QR / pairing code.';
  String get setupStep6Title =>
      _ru ? '6. Тема и язык' : '6. Theme and language';
  String get setupStep6Body => _ru
      ? 'Settings → Appearance (Light/Dark). Settings → Язык (English / Русский).'
      : 'Settings → Appearance (Light/Dark). Settings → Language (English / Русский).';
  String get setupStep7Title =>
      _ru ? '7. Проверка' : '7. Verify';
  String get setupStep7Body => _ru
      ? 'Отправьте себе WhatsApp сообщение. Оно должно появиться в Чатах. Удалённые — во вкладке Deleted.'
      : 'Send yourself a WhatsApp message. It should appear in Chats. Deleted ones stay under Deleted.';
  String get setupOpenNotifications =>
      _ru ? 'Открыть доступ к уведомлениям' : 'Open notification access';
  String get setupOpenConnect =>
      _ru ? 'Открыть Linked devices' : 'Open Linked devices';
}

/// Inherited access to [LocaleController].
class LocaleControllerScope extends InheritedNotifier<LocaleController> {
  const LocaleControllerScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>()
        ?.notifier;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerAudioService {
  static final TimerAudioService instance = TimerAudioService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  TimerAudioService._init();

  Future<void> initNotifications() async {
    if (kIsWeb) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _notificationsPlugin.initialize(initSettings);
      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar notificações locais: $e');
    }
  }

  Future<void> playRestCompleteAlert() async {
    // 1. Som de alerta / feedback tátil
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.vibrate();
      
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 800);
      }
    } catch (e) {
      debugPrint('Erro ao acionar som/vibração: $e');
    }

    // 2. Disparar notificação local se em segundo plano
    if (_notificationsInitialized) {
      try {
        const androidDetails = AndroidNotificationDetails(
          'jtech_rest_timer',
          'Cronômetro de Descanso',
          channelDescription: 'Notificações ao concluir o tempo de descanso entre séries',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
        const iosDetails = DarwinNotificationDetails(presentSound: true);
        const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        await _notificationsPlugin.show(
          101,
          'Tempo de Descanso Concluído! 🏋️‍♂️',
          'Hora de iniciar sua próxima série com carga!',
          details,
        );
      } catch (e) {
        debugPrint('Erro ao enviar notificação local: $e');
      }
    }
  }
}

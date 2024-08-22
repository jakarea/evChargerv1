import 'dart:math';

import 'package:ev_charger/controllers/sharedPreference_controller.dart';
import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import 'log.dart';

class Helpers {
  String nextTimezone = 'UTC+01:00';
  int nextTimezoneChange = 0;

  final SharedPreferenceController sharedPreferenceController =
      SharedPreferenceController();

  Future<void> updatingCardDataForFirstTimeBoot() async {
    var allCards = await DatabaseHelper.instance.getCards();
    var random = Random();

    int lastCardTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (var i = 0; i < allCards.length; i++) {
      var card = allCards[i];

      // Generate a random duration between 1 to 3 hours (in seconds)
      int randomHours = random.nextInt(3) + 1;
      int randomTimeInSeconds = randomHours * 3600;

      // Generate a random delay between 20 to 45 minutes (in seconds)
      int randomMinutes = random.nextInt(26) + 20;
      int randomDelayInSeconds = randomMinutes * 60;

      // Ensure this card starts at least the random delay after the last card
      int randomUnixTime = lastCardTime + randomTimeInSeconds;
      lastCardTime = randomUnixTime + randomDelayInSeconds; // Update lastCardTime for the next iteration

      await DatabaseHelper.instance.updateTimeField(card['id'], randomUnixTime);
    }
    Log.v("updated card data");
  }

  void decideNextTimezoneChangerDate() {
    int currentMonth = DateTime.now().month;
    currentMonth = 1;
    if (currentMonth > 3 && currentMonth <= 10) {
      setLastSundayOfMarch();
    } else if (currentMonth > 10 || currentMonth <= 3) {
      setLastSundayOfOctober();
    }
  }

  void setLastSundayOfOctober() {
    DateTime now = DateTime.now().toUtc();
    int nextOctoberYear = now.month <= 10 ? now.year : now.year + 1;
    int date = 31;
    DateTime lastDayOfOctober = DateTime(nextOctoberYear, 10, date);
    int lastDayOfWeek = lastDayOfOctober.weekday;
    for (int i = lastDayOfWeek; i >= 0; i--) {
      DateTime lastDayOfOctober = DateTime(nextOctoberYear, 10, date - i);
      int dayNo = lastDayOfOctober.weekday;
      if (dayNo == 7) {
        DateTime lastSaturdayOfOctober =
            DateTime.utc(nextOctoberYear, 10, date - i, 0, 59, 59);
        nextTimezoneChange =
            (lastSaturdayOfOctober.millisecondsSinceEpoch ~/ 1000) - 1;
      }
    }
    nextTimezone = 'UTC+01:00';
  }

  void setLastSundayOfMarch() {
    DateTime now = DateTime.now().toUtc();
    int nextMarchYear = now.month <= 3 ? now.year : now.year + 1;
    int date = 31;
    DateTime lastDayOfMarch = DateTime(nextMarchYear, 3, date);
    int lastDayOfWeek = lastDayOfMarch.weekday;
    for (int i = lastDayOfWeek; i >= 0; i--) {
      DateTime lastDayOfOctober = DateTime(nextMarchYear, 3, date - i);
      int dayNo = lastDayOfOctober.weekday;
      if (dayNo == 7) {
        DateTime lastSaturdayOfOctober =
            DateTime.utc(nextMarchYear, 3, date - i, 1, 59, 59);
        nextTimezoneChange =
            lastSaturdayOfOctober.millisecondsSinceEpoch ~/ 1000;
      }
    }
    nextTimezone = 'UTC+02:00';
  }

  int getRandomSessionRestTime(int numberOfSession, int days, int lastSession) {
    if (lastSession < 12000) {
      lastSession = 12000;
    }
    int lastCardTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    int totalTime = 86400 * days;
    int averageUse = totalTime ~/ numberOfSession;
    Random random = Random();
    int halfOfAverageUse = averageUse ~/ 2;
    int thirdOfAverageUse = averageUse ~/ 3;
    int randomNumber =
        random.nextInt(thirdOfAverageUse) + random.nextInt(halfOfAverageUse);
    int nextSession = randomNumber.abs() + 1700 + lastSession * 3;
    DateTime now = DateTime.now().toUtc();
    nextSession.toInt();

    if (80000 < nextSession && nextSession < 86400) {
      nextSession = nextSession - 5000;
    }

    if (86400 < nextSession && nextSession < 90000) {
      nextSession = nextSession + 5000;
    }

    // Generate a random delay between 20 to 45 minutes (in seconds)
    int randomMinutes = random.nextInt(26) + 20;
    int randomDelayInSeconds = randomMinutes * 60;

    int randomUnixTime = lastCardTime + nextSession;
    lastCardTime = randomUnixTime + randomDelayInSeconds;

    return randomUnixTime;
/*    return randomUnixTime + now.millisecondsSinceEpoch ~/ 1000;*/
  }

  Future<void> delayInSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }

  bool isCurrentTimeInRange(String timeRange) {
    // Split the timeRange string to get start and end times
    List<String> times = timeRange.split(' - ');
    String startTimeStr = times[0];
    String endTimeStr = times[1];

    // Convert the string times to TimeOfDay
    List<String> startParts = startTimeStr.split('.');
    TimeOfDay startTimes = TimeOfDay(
        hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));

    List<String> endParts = endTimeStr.split('.');
    TimeOfDay endTime =
        TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

    // Get the current time as a TimeOfDay
    final now = TimeOfDay.now();

    // Function to convert TimeOfDay to minutes for easier comparison
    double toMinutes(TimeOfDay tod) => tod.hour * 60.0 + tod.minute;

    // Compare the current time with the parsed TimeOfDay objects
    double nowInMinutes = toMinutes(now);
    double startInMinutes = toMinutes(startTimes);
    double endInMinutes = toMinutes(endTime);

    return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
  }
}

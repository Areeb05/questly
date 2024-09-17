import 'package:flutter/material.dart';
import '../services/chatgpt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class QuestScreen extends StatefulWidget {
  @override
  _QuestScreenState createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  String? quest;
  bool isLoading = true;
  int streak = 1;
  DateTime? lastQuestDate;
  Timer? _timer;
  Duration _timeLeft = Duration(hours: 24);
  RewardedAd? _rewardedAd;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    lastQuestDate = DateTime.tryParse(prefs?.getString('lastQuestDate') ?? '');
    streak = prefs?.getInt('streak') ?? 1;
    await _loadQuest();
    _startTimer();
    _loadRewardedAd();
  }

  Future<void> _loadQuest() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    List<String>? responses = args?['responses'];

    // Check if a new quest is needed
    if (lastQuestDate == null ||
        DateTime.now().difference(lastQuestDate!).inDays >= 1 ||
        prefs?.getString('quest') == null) {
      if (responses != null) {
        try {
          setState(() {
            isLoading = true;
          });
          ChatGPTService api = ChatGPTService();
          String newQuest = await api.getPersonalizedQuest(responses, streak);
          setState(() {
            quest = newQuest;
            isLoading = false;
          });
          // Save quest and date
          prefs?.setString('quest', newQuest);
          prefs?.setString('lastQuestDate', DateTime.now().toIso8601String());
        } catch (e) {
          setState(() {
            quest = 'Error generating quest. Please try again later.';
            isLoading = false;
          });
        }
      } else {
        // Load existing quest
        setState(() {
          quest = prefs?.getString('quest');
          isLoading = false;
        });
      }
    } else {
      // Load existing quest
      setState(() {
        quest = prefs?.getString('quest');
        isLoading = false;
      });
    }
  }

  void _completeQuest() async {
    DateTime now = DateTime.now();
    DateTime lastCompletionDate =
        DateTime.tryParse(prefs?.getString('lastCompletionDate') ?? '') ?? now;

    if (now.difference(lastCompletionDate).inDays == 1) {
      // Continue streak
      setState(() {
        streak += 1;
      });
    } else if (now.difference(lastCompletionDate).inDays > 1) {
      // Reset streak
      setState(() {
        streak = 1;
      });
    }

    prefs?.setInt('streak', streak);
    prefs?.setString('lastCompletionDate', now.toIso8601String());

    // Force new quest
    prefs?.remove('quest');
    await _loadQuest();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (lastQuestDate != null) {
      DateTime nextQuestTime = lastQuestDate!.add(Duration(hours: 24));
      _timeLeft = nextQuestTime.difference(DateTime.now());
      if (_timeLeft.isNegative) {
        _timeLeft = Duration(seconds: 0);
      }
    } else {
      _timeLeft = Duration(seconds: 0);
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        // Allow user to get a new quest
        prefs?.remove('quest');
        _loadQuest();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'YOUR_REWARDED_AD_UNIT_ID', // Replace with your Ad Unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched the ad, skip the timer
          _timer?.cancel();
          setState(() {
            _timeLeft = Duration(seconds: 0);
          });
          // Force new quest
          _loadQuest();
        },
      );
      _rewardedAd = null;
    } else {
      print('Rewarded ad is not loaded yet');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad is not ready yet, please try again later.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Daily Quest'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                // Added to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Streak: $streak day(s)',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 20),
                    Text(
                      quest ?? 'No quest available.',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      child: Text('Complete Quest'),
                      onPressed: _completeQuest,
                    ),
                    SizedBox(height: 30),
                    Text(
                      _timeLeft.inSeconds > 0
                          ? 'Next quest in: ${_formatDuration(_timeLeft)}'
                          : 'You can get a new quest now!',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    _timeLeft.inSeconds > 0
                        ? ElevatedButton(
                            child: Text('Watch Ad to Skip Timer'),
                            onPressed: _showRewardedAd,
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
    );
  }
}

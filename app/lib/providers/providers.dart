import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
export 'purchases_provider.dart';

/// Singleton API client provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// User profile state
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return UserProfileNotifier(ref.read(apiClientProvider));
});

class UserProfile {
  final String displayName;
  final int energy;
  final int streakCount;
  final int hintCredits;
  final int totalRepairs;
  final String subscription;
  final int todayCasesPlayed;
  final bool loginBonusClaimed;
  final bool dailyHintClaimed;
  final bool fomoPurchased;
  final int maxEnergy;
  final int daysSinceInstall;
  final String? installDate;

  UserProfile({
    required this.displayName,
    required this.energy,
    required this.streakCount,
    required this.hintCredits,
    required this.totalRepairs,
    required this.subscription,
    required this.todayCasesPlayed,
    required this.loginBonusClaimed,
    required this.dailyHintClaimed,
    required this.fomoPurchased,
    required this.maxEnergy,
    required this.daysSinceInstall,
    this.installDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] ?? 'Mechanic',
    energy: json['energy'] ?? 0,
    streakCount: json['streakCount'] ?? 0,
    hintCredits: json['hintCredits'] ?? 0,
    totalRepairs: json['totalRepairs'] ?? 0,
    subscription: json['subscription'] ?? 'free',
    todayCasesPlayed: json['todayCasesPlayed'] ?? 0,
    loginBonusClaimed: json['loginBonusClaimed'] ?? false,
    dailyHintClaimed: json['dailyHintClaimed'] ?? false,
    fomoPurchased: json['fomoPurchased'] ?? false,
    maxEnergy: json['maxEnergy'] ?? 3,
    daysSinceInstall: json['daysSinceInstall'] ?? 999,
    installDate: json['installDate'],
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'energy': energy,
    'streakCount': streakCount,
    'hintCredits': hintCredits,
    'totalRepairs': totalRepairs,
    'subscription': subscription,
    'todayCasesPlayed': todayCasesPlayed,
    'loginBonusClaimed': loginBonusClaimed,
    'dailyHintClaimed': dailyHintClaimed,
    'fomoPurchased': fomoPurchased,
    'maxEnergy': maxEnergy,
    'daysSinceInstall': daysSinceInstall,
    'installDate': installDate,
  };

  /// Whether user has any hint credits available (purchased or daily)
  bool get hasHints => hintCredits > 0;

  /// Whether user is a Pro subscriber (unlimited hints)
  bool get isPro => subscription == 'pro';

  /// Honeymoon phase: Day 1-3 (no FOMO, generous energy)
  bool get isHoneymoon => daysSinceInstall <= 2;

  /// Transition phase: Day 4-7 (show transition FOMO)
  bool get isTransition => daysSinceInstall >= 3 && daysSinceInstall <= 6;

  String get rank {
    if (totalRepairs >= 50) return 'Usta Tamirci';
    if (totalRepairs >= 20) return 'Kalfa';
    if (totalRepairs >= 5) return 'Çırak';
    return 'Acemi';
  }
}

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final ApiClient _api;
  UserProfileNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.getProfile();
      state = AsyncValue.data(UserProfile.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> claimLoginBonus() async {
    try {
      await _api.claimLoginBonus();
      // Reload profile
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> claimAdReward(String type, {String? sessionId}) async {
    try {
      await _api.claimAdReward(type, sessionId: sessionId);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    try {
      final res = await _api.updateProfile(newName);
      if (res['success'] == true) {
        state.whenData((profile) {
          state = AsyncValue.data(UserProfile(
            displayName: newName,
            energy: profile.energy,
            streakCount: profile.streakCount,
            hintCredits: profile.hintCredits,
            totalRepairs: profile.totalRepairs,
            subscription: profile.subscription,
            todayCasesPlayed: profile.todayCasesPlayed,
            loginBonusClaimed: profile.loginBonusClaimed,
            dailyHintClaimed: profile.dailyHintClaimed,
            fomoPurchased: profile.fomoPurchased,
            maxEnergy: profile.maxEnergy,
            daysSinceInstall: profile.daysSinceInstall,
            installDate: profile.installDate,
          ));
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void updateEnergy(int newEnergy) {
    state.whenData((profile) {
      state = AsyncValue.data(UserProfile(
        displayName: profile.displayName,
        energy: newEnergy,
        streakCount: profile.streakCount,
        hintCredits: profile.hintCredits,
        totalRepairs: profile.totalRepairs,
        subscription: profile.subscription,
        todayCasesPlayed: profile.todayCasesPlayed,
        loginBonusClaimed: profile.loginBonusClaimed,
        dailyHintClaimed: profile.dailyHintClaimed,
        fomoPurchased: profile.fomoPurchased,
        maxEnergy: profile.maxEnergy,
        daysSinceInstall: profile.daysSinceInstall,
        installDate: profile.installDate,
      ));
    });
  }

  /// Consume one hint credit locally after a successful hint API call
  void consumeHint() {
    state.whenData((profile) {
      state = AsyncValue.data(UserProfile(
        displayName: profile.displayName,
        energy: profile.energy,
        streakCount: profile.streakCount,
        hintCredits: (profile.hintCredits - 1).clamp(0, 9999),
        totalRepairs: profile.totalRepairs,
        subscription: profile.subscription,
        todayCasesPlayed: profile.todayCasesPlayed,
        loginBonusClaimed: profile.loginBonusClaimed,
        dailyHintClaimed: profile.dailyHintClaimed,
        fomoPurchased: profile.fomoPurchased,
        maxEnergy: profile.maxEnergy,
        daysSinceInstall: profile.daysSinceInstall,
        installDate: profile.installDate,
      ));
    });
  }

  /// Add purchased hints to the local credit count
  void addHintCredits(int amount) {
    state.whenData((profile) {
      state = AsyncValue.data(UserProfile(
        displayName: profile.displayName,
        energy: profile.energy,
        streakCount: profile.streakCount,
        hintCredits: profile.hintCredits + amount,
        totalRepairs: profile.totalRepairs,
        subscription: profile.subscription,
        todayCasesPlayed: profile.todayCasesPlayed,
        loginBonusClaimed: profile.loginBonusClaimed,
        dailyHintClaimed: profile.dailyHintClaimed,
        fomoPurchased: profile.fomoPurchased,
        maxEnergy: profile.maxEnergy,
        daysSinceInstall: profile.daysSinceInstall,
        installDate: profile.installDate,
      ));
    });
  }

  void markFomoPurchased() {
    state.whenData((profile) {
      state = AsyncValue.data(UserProfile(
        displayName: profile.displayName,
        energy: profile.energy,
        streakCount: profile.streakCount,
        hintCredits: profile.hintCredits,
        totalRepairs: profile.totalRepairs,
        subscription: 'pro', // Automatically make them PRO for the mock
        todayCasesPlayed: profile.todayCasesPlayed,
        loginBonusClaimed: profile.loginBonusClaimed,
        dailyHintClaimed: profile.dailyHintClaimed,
        fomoPurchased: true,
        maxEnergy: profile.maxEnergy,
        daysSinceInstall: profile.daysSinceInstall,
        installDate: profile.installDate,
      ));
    });
  }

  void markProPurchased() {
    state.whenData((profile) {
      state = AsyncValue.data(UserProfile(
        displayName: profile.displayName,
        energy: profile.energy,
        streakCount: profile.streakCount,
        hintCredits: profile.hintCredits,
        totalRepairs: profile.totalRepairs,
        subscription: 'pro',
        todayCasesPlayed: profile.todayCasesPlayed,
        loginBonusClaimed: profile.loginBonusClaimed,
        dailyHintClaimed: profile.dailyHintClaimed,
        fomoPurchased: profile.fomoPurchased,
        maxEnergy: profile.maxEnergy,
        daysSinceInstall: profile.daysSinceInstall,
        installDate: profile.installDate,
      ));
    });
  }
}

/// Game session state
class GameSession {
  final String sessionId;
  final Map<String, dynamic> scenario;
  final List<ChatMessage> messages;
  final int messageCount;
  final bool solved;
  final int streakCount;
  final bool bonusEnergy;

  GameSession({
    required this.sessionId,
    required this.scenario,
    this.messages = const [],
    this.messageCount = 0,
    this.solved = false,
    this.streakCount = 0,
    this.bonusEnergy = false,
  });

  GameSession copyWith({
    List<ChatMessage>? messages,
    int? messageCount,
    bool? solved,
    int? streakCount,
    bool? bonusEnergy,
  }) => GameSession(
    sessionId: sessionId,
    scenario: scenario,
    messages: messages ?? this.messages,
    messageCount: messageCount ?? this.messageCount,
    solved: solved ?? this.solved,
    streakCount: streakCount ?? this.streakCount,
    bonusEnergy: bonusEnergy ?? this.bonusEnergy,
  );
}

class ChatMessage {
  final String role; // user, assistant, system, hint
  final String content;
  final bool blocked;

  ChatMessage({required this.role, required this.content, this.blocked = false});
}

/// Leaderboard state
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, period) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getLeaderboard(period);
  final rankings = data['rankings'] as List;
  return rankings.map((r) => LeaderboardEntry(
    rank: r['rank'],
    displayName: r['displayName'],
    repPoints: r['repPoints'],
  )).toList();
});

class LeaderboardEntry {
  final int rank;
  final String displayName;
  final int repPoints;

  LeaderboardEntry({required this.rank, required this.displayName, required this.repPoints});
}

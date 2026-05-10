// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AutoFix AI 模拟器';

  @override
  String get tabGarage => '车库';

  @override
  String get tabLeaderboard => '排行榜';

  @override
  String get tabProfile => '个人资料';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get send => '发送';

  @override
  String get close => '关闭';

  @override
  String customerComplaint(Object complaint) {
    return '🧑‍🔧 客户：\"$complaint\"';
  }

  @override
  String get noEnergy => '⚡ 能量耗尽！观看广告或等待。';

  @override
  String get fallbackError => '⚡ 车库跳闸了，请重试。';

  @override
  String get caseSolved => '✅ 案件已解决！';

  @override
  String get repairSuccess => '🏆 修理成功！';

  @override
  String seriesInfo(Object streak) {
    return '连胜：$streak | +1 声望';
  }

  @override
  String get bonusEnergyTag => ' | 🎁 +1 额外能量！';

  @override
  String get backToGarage => '返回车库';

  @override
  String messageCount(Object count, Object limit) {
    return '$count/$limit 条消息';
  }

  @override
  String cooldownLabel(Object remaining) {
    return '⏰ 冷却时间：$remaining';
  }

  @override
  String cooldownMessage(Object limit) {
    return '已达到 $limit 条消息上限';
  }

  @override
  String get watchAdContinue => '观看广告 → 继续';

  @override
  String get cooldownCleared => '🎬 冷却已重置！继续吧。';

  @override
  String cooldownReduced(Object remaining) {
    return '🎬 减少1小时！剩余：$remaining';
  }

  @override
  String get giveUpTitle => '🏳️ 放弃？';

  @override
  String get giveUpMessage => '您的连胜不会中断，但此案件不算已解决。确定要放弃吗？';

  @override
  String get giveUpButton => '放弃';

  @override
  String get continueButton => '继续';

  @override
  String get hintTimeTitle => '提示时间！';

  @override
  String get hintTimeMessage => '已超过15条消息但未解决。想咨询大师吗？';

  @override
  String get getHint => '获取提示';

  @override
  String get no => '不';

  @override
  String get helpButton => '帮助';

  @override
  String get hintsEmpty => '提示用完了！';

  @override
  String get hintsEmptyMessage => '你需要大师的智慧，但提示积分已用完！立即购买提示来破案。';

  @override
  String get hintsPromo => '💡 3个提示仅需¥6！';

  @override
  String get hintStore => '提示商店';

  @override
  String get continueAlone => '自己继续';

  @override
  String get reportTitle => '🚨 举报';

  @override
  String get reportMessage => '您即将举报一条不当的AI消息。此会话将被记录以供审查。';

  @override
  String get reportSuccess => '您的举报已收到，将进行审查。';

  @override
  String get reportFailed => '举报发送失败。';

  @override
  String get chatPlaceholder => '检查、测试、修理...';

  @override
  String get examining => '检查中...';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileLoadError => '加载个人资料失败';

  @override
  String get energy => '能量';

  @override
  String get repairs => '修理';

  @override
  String get series => '连胜';

  @override
  String get hints => '提示';

  @override
  String get accountLinked => '✅ 账户已关联';

  @override
  String get accountAnonymous => '⚠️ 匿名账户';

  @override
  String get linkAccount => '关联账户';

  @override
  String get linkAccountMessage => '使用Google或Apple账户登录。\n保护您的购买记录和游戏进度！';

  @override
  String get signInGoogle => '使用Google登录';

  @override
  String get signInApple => '使用Apple登录';

  @override
  String get signInGoogleSuccess => '✅ Google账户已关联！';

  @override
  String get signInAppleSuccess => '✅ Apple账户已关联！';

  @override
  String get signInCancelled => '登录已取消';

  @override
  String get dailyBonus => '每日奖励';

  @override
  String get dailyBonusClaimed => '今日已领取 ✅';

  @override
  String get dailyBonusReward => '+1 能量，+1 提示';

  @override
  String get dailyBonusSuccess => '🎁 奖励已领取！+1 能量，+1 提示';

  @override
  String get dailyBonusAlready => '奖励已领取过';

  @override
  String get watchAd => '观看广告';

  @override
  String get watchAdReward => '获得+1能量';

  @override
  String get watchAdSuccess => '🎬 +1 能量已获得！';

  @override
  String get watchAdFailed => '广告加载失败';

  @override
  String get premium => '高级版';

  @override
  String get premiumFree => '无限能量，无广告';

  @override
  String get premiumComingSoon => '🚧 即将推出！高级功能开发中...';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get restorePurchasesSub => '恢复之前的购买记录';

  @override
  String get restoreSuccess => '✅ 购买已检查并恢复！';

  @override
  String get restoreEmpty => '未找到购买记录。';

  @override
  String get settings => '设置';

  @override
  String get settingsSub => '语言、通知';

  @override
  String get language => '语言';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutSub => '返回匿名账户';

  @override
  String get signOutConfirm => '退出登录？';

  @override
  String get signOutMessage => '您将返回匿名账户。重新登录后数据将恢复。';

  @override
  String get difficultyEasy => '简单';

  @override
  String get difficultyMedium => '中等';

  @override
  String get difficultyHard => '困难';

  @override
  String get difficultyEasySub => '电池，起动机，火花塞';

  @override
  String get difficultyMediumSub => 'LPG，燃油泵，传感器';

  @override
  String get difficultyHardSub => '垫片，涡轮，变速箱';

  @override
  String get casesCount => '5 个案件';

  @override
  String get selectCase => '选择一个新案件';

  @override
  String get garageWelcome => '车库在等你，师傅。';

  @override
  String streakProgress(Object current, Object total) {
    return '连胜：$current/$total';
  }

  @override
  String get bonusEnergyShort => '🎁 +1 能量';

  @override
  String get weeklyTab => '每周';

  @override
  String get monthlyTab => '每月';

  @override
  String get yearlyTab => '每年';

  @override
  String get leaderboardEmpty => '还没有人进入排行榜';

  @override
  String get leaderboardBeFirst => '成为第一个！🔧';

  @override
  String get casesTitle => '案件';

  @override
  String get goPro => '升级 Pro';

  @override
  String get rankNovice => '新手';

  @override
  String get rankApprentice => '学徒';

  @override
  String get rankJourneyman => '熟练工';

  @override
  String get rankMaster => '大师';

  @override
  String get tip1 => '提示：先听取客户意见，再进行观察。在没有诊断之前不要随意修理！';

  @override
  String get tip2 => '提示：OBD-II 扫描仪是你最好的朋友。第一步永远是连接它。';

  @override
  String get tip3 => '提示：如果发动机能转动但无法启动，可能是点火或燃油问题。';

  @override
  String get tip4 => '提示：如果提示用完了，可以向大师求助。Pro 用户有无限提示。';

  @override
  String get tip5 => '提示：先测试便宜的零件。盲目更换零件会扣除声望点数。';

  @override
  String get tip6 => '提示：刹车异响通常来自刹车片，但别忘了检查刹车鼓。';

  @override
  String get paywallTitle => 'PRO 维修工';

  @override
  String get paywallHero => '成为车库的新老板！';

  @override
  String get paywallFeature1 => '无限能量（无需等待）';

  @override
  String get paywallFeature2 => '每个案件都有无限提示';

  @override
  String get paywallFeature3 => '移除所有广告';

  @override
  String get weeklyPlan => '周度计划';

  @override
  String get weeklyPlanSub => '短期掌握';

  @override
  String get monthlyPlan => '月度计划';

  @override
  String get monthlyPlanSub => '每天只需 ¥3';

  @override
  String get monthlyPlanTag => '最畅销 — 节省 61%';

  @override
  String get yearlyPlan => '年度计划';

  @override
  String get yearlyPlanSub => '长期投资';

  @override
  String get upgradeNow => '立即升级';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get restore => '恢复购买';

  @override
  String get paywallSuccess => '购买成功！Pro 功能已解锁。';

  @override
  String get case1Vehicle => '2002 日本轿车 1.6';

  @override
  String get case1Complaint => '车完全无法启动，拧钥匙时没有任何声音。';

  @override
  String get case2Vehicle => '2006 美国掀背车 1.6';

  @override
  String get case2Complaint => '拧钥匙时有咔哒声，但发动机不转。';

  @override
  String get case3Vehicle => '2008 德国掀背车 1.4';

  @override
  String get case3Complaint => '左侧大灯不亮，右侧正常。';

  @override
  String get case4Vehicle => '2010 法国轿车 1.5';

  @override
  String get case4Complaint => '雨刮器完全不动，但玻璃水能喷出。';

  @override
  String get case5Vehicle => '2004 德国掀背车 1.6';

  @override
  String get case5Complaint => '空调出风但完全不冷。';

  @override
  String get case6Vehicle => '2015 韩国掀背车 1.4';

  @override
  String get case6Complaint => '发动机温度在 15 分钟内飙升到红区。';

  @override
  String get case7Vehicle => '1998 意大利掀背车 1.6';

  @override
  String get case7Complaint => '早晨启动困难，怠速时抖动剧烈。';

  @override
  String get case8Vehicle => '2012 日本轿车 1.6';

  @override
  String get case8Complaint => '换挡，尤其是 1 挡到 2 挡时，非常顿挫。';

  @override
  String get case9Vehicle => '2009 法国掀背车 1.4';

  @override
  String get case9Complaint => '低速刹车时前轮发出刺耳的尖叫声。';

  @override
  String get case10Vehicle => '2007 日本掀背车 1.5';

  @override
  String get case10Complaint => '踩油门时转速上升，但车几乎不加速。';

  @override
  String get case11Vehicle => '2005 高级德国轿车 2.0';

  @override
  String get case11Complaint => '发动机故障灯亮起，转速无法超过 3000 转。';

  @override
  String get case12Vehicle => '2011 高级德国轿车 2.1';

  @override
  String get case12Complaint => '机油和防冻液混合，膨胀水箱里像奶昔一样。';

  @override
  String get case13Vehicle => '2003 高级德国轿车 1.8';

  @override
  String get case13Complaint => '下雨时挡风玻璃和天窗周围漏水。';

  @override
  String get case14Vehicle => '2014 高级瑞典轿车 2.0';

  @override
  String get case14Complaint => '方向盘变得非常沉重，几乎无法转动。';

  @override
  String get case15Vehicle => '2016 捷克轿车 1.6';

  @override
  String get case15Complaint => '仪表盘显示定速巡航和车道保持辅助系统已禁用。';

  @override
  String get analyzing => '分析中...';

  @override
  String get master => '师傅';

  @override
  String get claimBonus => '领取奖励！';

  @override
  String get bonusEnergy => '+1 能量';

  @override
  String get bonusHint => '+1 提示';

  @override
  String get watchAdButton => '观看';

  @override
  String get adEnergySuccess => '🎬 获得 +1 能量！';

  @override
  String get adApiFail => '奖励 API 错误';

  @override
  String get adLoadFail => '广告加载失败或被中断。';

  @override
  String get hintError => '提示错误';

  @override
  String get splashTitle => '汽修大师';

  @override
  String get splashSubtitle => '车库在等你';

  @override
  String get fomoTitle => '限时优惠！';

  @override
  String get fomoBody => '仅限现在！无限能量和所有大师功能等着你。不要错过！';

  @override
  String get fomoPopupTitle => '限时优惠';

  @override
  String get fomoOffer => '1 周无限能量\n🎁 +5 提示免费赠送！';

  @override
  String get fomoDiscount => '8折优惠！';

  @override
  String fomoViewers(String count) {
    return '$count 人正在查看此优惠';
  }

  @override
  String get fomoBuy => '立即抢购';

  @override
  String get fomoSkip => '跳过优惠，继续游戏';

  @override
  String cooldownAdSuccess(String remaining) {
    return '🎬 减少1小时！剩余：$remaining';
  }

  @override
  String get googleLinked => '✅ Google 账号已关联！';

  @override
  String get appleLinked => '✅ Apple 账号已关联！';

  @override
  String get loginCancelled => '登录已取消';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get enterNewName => '输入新名称';

  @override
  String get saveSuccess => '更新成功！';

  @override
  String get save => '保存';
}

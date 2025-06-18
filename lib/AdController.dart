// import 'dart:async';
//
// // import 'package:advertising_id/advertising_id.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:logger/logger.dart';
//
// class AdController extends GetxController with WidgetsBindingObserver {
//   final RxBool isAdLoading = false.obs;
//
//   void setAdLoading(bool loading) => isAdLoading.value = loading;
//
//   // Banner Ad
//   late BannerAd bannerAd;
//   var isBannerAdLoaded = false.obs;
//
//   // Interstitial Ad
//   InterstitialAd? interstitialAd;
//   AppOpenAd? _appOpenAd;
//   var isAppOpenAdLoaded = false.obs;
//   DateTime? _appOpenAdLoadTime;
//
//   final String _appOpenAdUnitId = dotenv.env['APP_OPEN_AD_UNIT_ID'] ?? '';
//   final String _appBannerAdUnitId = dotenv.env['BANNER_AD_UNIT_ID'] ?? '';
//   final String _appInterstitialAdUnitId = dotenv.env['INTERSTITIAL_AD_UNIT_ID'] ?? '';
//   final String _appRewardAdUnitId = dotenv.env['REWARD_AD_UNIT_ID'] ?? '';
//
//   // Rewarded Ad
//   RewardedAd? _rewardedAd;
//   var isRewardedAdLoaded = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadBannerAd();
//     loadInterstitialAd();
//     _loadRewardedAd(); // Load rewarded ad on initialization
//     _loadAppOpenAd();
//     WidgetsBinding.instance.addObserver(this);
//     // testID();
//   }
//
//   // testID() async {
//   //   String? adId = await AdvertisingId.id();
//   //   Logger().e("Advertising ID: $adId");
//   // }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       _showAppOpenAdIfAvailable();
//     }
//   }
//
//   // AppOpenAd
//   bool get isAppOpenAdAvailable {
//     return _appOpenAd != null && _wasLoadTimeLessThanNHoursAgo(4);
//   }
//
//   bool _wasLoadTimeLessThanNHoursAgo(int n) {
//     if (_appOpenAdLoadTime == null) {
//       return false;
//     }
//     DateTime date = _appOpenAdLoadTime!;
//     DateTime now = DateTime.now();
//     return now.difference(date).inHours < n;
//   }
//
//   void _loadAppOpenAd() {
//     AppOpenAd.load(
//       adUnitId: _appOpenAdUnitId,
//       request: AdRequest(),
//       adLoadCallback: AppOpenAdLoadCallback(
//         onAdLoaded: (ad) {
//           _appOpenAd = ad;
//           isAppOpenAdLoaded.value = true;
//           _appOpenAdLoadTime = DateTime.now();
//           Logger().i('App open ad loaded.');
//
//           // Assign onPaidEvent callback
//           _appOpenAd?.onPaidEvent = (ad, impressionData) {
//             Logger().e('Ad Impression: ${impressionData.valueMicros}');
//           } as OnPaidEventCallback?;
//
//           _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (ad) {
//               _appOpenAd = null;
//               isAppOpenAdLoaded.value = false;
//               _loadAppOpenAd();
//             },
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               _appOpenAd = null;
//               isAppOpenAdLoaded.value = false;
//               Logger().e("App open ad failed to show: $error");
//               _loadAppOpenAd();
//             },
//           );
//         },
//         onAdFailedToLoad: (error) {
//           _appOpenAd = null;
//           isAppOpenAdLoaded.value = false;
//           Logger().e("App open ad failed to load: $error");
//         },
//       ),
//     );
//   }
//
//   void _showAppOpenAdIfAvailable() {
//     if (isAppOpenAdAvailable) {
//       Logger().e("Show App Open ad ");
//       _appOpenAd!.show();
//     } else {
//       Logger().e("App Open ad not available yet ");
//     }
//   }
//
//   @override
//   void onClose() {
//
//     if (isBannerAdLoaded.value) {
//       bannerAd.dispose();
//     }
//
//     interstitialAd?.dispose();
//     _rewardedAd?.dispose();
//     _appOpenAd?.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.onClose();
//   }
//
//   // Load Banner Ad
//   void loadBannerAd() {
//     bannerAd = BannerAd(
//       adUnitId: _appBannerAdUnitId,
//       // Replace with real ID
//       size: AdSize.banner,
//       request: AdRequest(),
//
//       listener: BannerAdListener(
//         onAdFailedToLoad: (Ad ad, LoadAdError error) {
//           ad.dispose();
//           isBannerAdLoaded.value = false;
//           Future.delayed(Duration(seconds: 10), loadBannerAd);
//         },
//
//         onAdLoaded: (Ad ad) {
//           isBannerAdLoaded.value = true;
//         },
//
//       ),
//     );
//     bannerAd.load();
//   }
//
//   // Load Interstitial Ad
//   Future<void> loadInterstitialAd() async {
//     isAdLoading.value = true;
//     try {
//       await InterstitialAd.load(
//         adUnitId: _appInterstitialAdUnitId,
//         request: const AdRequest(),
//         adLoadCallback: InterstitialAdLoadCallback(
//           onAdLoaded: (ad) {
//             interstitialAd = ad;
//             isAdLoading.value = false;
//           },
//           onAdFailedToLoad: (error) {
//             isAdLoading.value = false;
//             Logger().e('Interstitial ad failed to load: $error');
//           },
//         ),
//       );
//     } catch (e) {
//       isAdLoading.value = false;
//       Logger().e('Error loading interstitial ad: $e');
//     }
//   }
//
//   // Show Interstitial Ad
//   Future<bool> showInterstitialAd() async {
//     final completer = Completer<bool>();
//
//     if (interstitialAd == null) {
//       Logger().e('No interstitial ad loaded');
//       return false;
//     }
//
//     interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         completer.complete(true);
//         loadInterstitialAd(); // Preload next ad
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         ad.dispose();
//         completer.complete(false);
//         loadInterstitialAd();
//       },
//     );
//
//     interstitialAd!.show();
//     interstitialAd = null; // Clear current ad
//
//     return await completer.future;
//   }
//
//   // Load Rewarded Ad
//   void _loadRewardedAd() {
//     RewardedAd.load(
//       adUnitId: _appRewardAdUnitId,
//       request: AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           _rewardedAd = ad;
//           isRewardedAdLoaded.value = true;
//
//           // Set up full-screen content callback
//           ad.fullScreenContentCallback = FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (ad) {
//               _rewardedAd = null;
//               isRewardedAdLoaded.value = false;
//               _loadRewardedAd(); // Reload a new rewarded ad
//             },
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               _rewardedAd = null;
//               isRewardedAdLoaded.value = false;
//               _loadRewardedAd(); // Reload a new rewarded ad
//             },
//           );
//         },
//         onAdFailedToLoad: (error) {
//           _rewardedAd = null;
//           isRewardedAdLoaded.value = false;
//           Logger().e('Failed to load rewarded ad: ${error.message}');
//         },
//       ),
//     );
//   }
//
//   // Show Rewarded Ad
//   Future<bool> showRewardedAd() async {
//     final Completer<bool> completer = Completer<bool>();
//
//     if (_rewardedAd == null) {
//       Logger().e('Rewarded ad not loaded');
//       return false;
//     }
//
//     try {
//       _rewardedAd!.show(
//         onUserEarnedReward: (ad, reward) {
//           Logger().i('Reward earned: ${reward.amount} ${reward.type}');
//           if (!completer.isCompleted) {
//             completer.complete(true); // Successfully watched
//           }
//         },
//       );
//
//       return await completer.future;
//     } catch (e) {
//       Logger().e('Exception showing ad: $e');
//       return false;
//     }
//   }
// }

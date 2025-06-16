// lib/routes/app_pages.dart
import 'package:get/get.dart';
import 'package:quiz_project/auth/login_screen.dart';
import 'package:quiz_project/auth/register_screen.dart';
import 'package:quiz_project/ui/add_job_form_controller.dart';
import 'package:quiz_project/ui/main_screen.dart';
import 'package:quiz_project/ui/map_screen.dart';
import 'package:quiz_project/ui/my_ads_screen.dart';
import 'package:quiz_project/ui/profile_screen.dart';

import '../controllers/AuthController.dart';
import '../controllers/home_controller.dart';
import '../ui/add_job_screen.dart';
import '../ui/map_controller.dart';
import '../utils/theme_service.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: Routes.ADD_NEW,
      page: () => AddJobScreen(),
      binding: AddNewJobBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterScreen(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      bindings: [
        HomeBinding(),
        MapBinding(),
      ],
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: Routes.MAP,
      page: () => const MapScreen(),
      binding: MapBinding(),
    ),
    GetPage(
      name: Routes.MY_ADS,
      page: () => const MyAdsScreen(),
      binding: HomeBinding(),
    ),
  ];
}

abstract class Routes {
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const MAIN = '/ui';
  static const PROFILE = '/profile';
  static const MAP = '/map';
  static const MY_ADS = '/my_ads';
  static const ADD_NEW = '/create_new_job';
}




class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
class AddNewJobBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddJobFormController>(() => AddJobFormController());
  }
}
class MapBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapControllerX>(() => MapControllerX());
  }
}

class ThemeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ThemeService());
  }
}

class InitialBindings implements Bindings {
  @override
  void dependencies() {

    ThemeBinding().dependencies();
    HomeBinding().dependencies();
    AddNewJobBinding().dependencies();
    MapBinding().dependencies();

  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
class tester {

// IMPORTANT: For seeding, you cannot dynamically get the current user's ID
// at compile time. You must either:
// 1. Manually assign placeholder ownerIds (like "seed_owner_1") and later
//    update them in Firestore to actual Firebase UIDs if you want those
//    seeded jobs linked to real users.
// 2. Assign the ownerId dynamically when the addJob method is called (for
//    jobs created by logged-in users via the app's UI).


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> seedJobs() async {

    print('Starting Firestore seeding process...');
    // تغذية أكثر قوة: تحقق مما إذا كانت المجموعة فارغة قبل التغذية
    final collection = await _firestore.collection('jobs').limit(1).get();
    if (collection.docs.isNotEmpty) {
      Get.snackbar('تغذية Firestore', 'مجموعة الوظائف ليست فارغة. تخطي التغذية.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      print('Jobs collection is not empty. Skipping seeding.');
      return;
    }


    for (var job in testJobsData) {
      // تأكد من تعيين ownerId إلى معرف مستخدم Firebase موجود
      // للتغذية الفعلية، قد تحتاج إلى إنشاء بعض مستخدمي Firebase الوهميين
      // واستخدام معرفاتهم هنا، أو قبول أن هذه الوظائف سيكون لها في البداية
      // ownerIds لا تتطابق مع المستخدمين الحقيقيين.
      // في الوقت الحالي، هذه مجرد سلاسل نائبة لـ 'seed_owner_X'
      await _firestore.collection('jobs').doc(job.id).set(job.toMap()); // استخدام .set مع معرف صريح
      debugPrint('Added job: ${job.title} (ID: ${job.id})');
    }
    Get.snackbar('تغذية Firestore', 'اكتملت عملية تغذية الوظائف التجريبية.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    print('Firestore seeding process completed.');
  }
  final List<JobModel> testJobsData = [
    JobModel(
      id: const Uuid().v4(), // Use UUID for unique IDs for seeding
      title: "مطور تطبيقات موبايل",
      description: "نبحث عن مطور فلاتر أو رياكت نيتف بخبرة لا تقل سنتين لإنشاء تطبيقات جوال متميزة، مع القدرة على العمل ضمن فريق.",
      city: "دمشق",
      jobType: "دوام كامل",
      location: "شارع الحمراء، دمشق",
      latitude: 33.5132,
      longitude: 36.2913,
      createdAt: DateTime(2025, 5, 20, 10, 30),
      hashtags: ["#فلاتر", "#مطور_جوال", "#اندرويد", "#iOS"],
      contactOptions: [
        ContactOption(type: ContactType.email, value: "hr@companyalpha.com"),
        ContactOption(type: ContactType.whatsapp, value: "+963987654321"),
      ],
      ownerId: "seed_owner_1", // Placeholder owner for seeded jobs
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "مصمم تجربة مستخدم (UX/UI)",
      description: "مطلوب مصمم مبدع وذو خبرة في Figma وAdobe XD لتصميم واجهات مستخدم جذابة وسهلة الاستخدام.",
      city: "حلب",
      jobType: "دوام جزئي",
      location: "حي الفيض، حلب",
      latitude: 36.2012,
      longitude: 37.1612,
      createdAt: DateTime(2025, 5, 22, 14, 0),
      hashtags: ["#تصميم", "#UXUI", "#فيغما", "#جرافيك"],
      contactOptions: [
        ContactOption(type: ContactType.website, value: "https://www.creativevision.com/careers"),
        ContactOption(type: ContactType.email, value: "jobs@creativevision.com"),
      ],
      ownerId: "seed_owner_2",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "مسؤول تسويق رقمي",
      description: "خبرة في إدارة حملات التسويق عبر وسائل التواصل الاجتماعي، تحسين محركات البحث، وإنشاء المحتوى الرقمي.",
      city: "حمص",
      jobType: "دوام كامل",
      location: "شارع البرازيل، حمص",
      latitude: 34.7297,
      longitude: 36.7202,
      createdAt: DateTime(2025, 5, 25, 9, 0),
      hashtags: ["#تسويق_رقمي", "#سوشيال_ميديا", "#SEO"],
      contactOptions: [
        ContactOption(type: ContactType.phone, value: "+963312345678"),
        ContactOption(type: ContactType.email, value: "marketing.lead@growthagency.com"),
      ],
      ownerId: "seed_owner_1",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "مترجم لغة إنجليزية - عربي",
      description: "مطلوب مترجم مستقل بخبرة في الترجمة التقنية أو القانونية، مع الالتزام بالمواعيد النهائية.",
      city: "عن بعد",
      jobType: "عن بعد",
      location: "عن بعد",
      latitude: 0.0,
      longitude: 0.0,
      createdAt: DateTime(2025, 5, 28, 11, 45),
      hashtags: ["#ترجمة", "#لغات", "#مستقل", "#عمل_عن_بعد"],
      contactOptions: [
        ContactOption(type: ContactType.email, value: "translations@proservices.com"),
        ContactOption(type: ContactType.telegram, value: "https://t.me/@protranslations"),
      ],
      ownerId: "seed_owner_3",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "محاسب مالي",
      description: "نبحث عن محاسب ذو خبرة في إعداد التقارير المالية، تحليل البيانات، والتصنيف الضريبي.",
      city: "اللاذقية",
      jobType: "دوام كامل",
      location: "شارع 8 آذار، اللاذقية",
      latitude: 35.5186,
      longitude: 35.7923,
      createdAt: DateTime(2025, 6, 1, 9, 15),
      hashtags: ["#محاسبة", "#مالية", "#تدقيق", "#ضرائب"],
      contactOptions: [
        ContactOption(type: ContactType.email, value: "finance.dept@horizonholding.com"),
      ],
      ownerId: "seed_owner_2",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "فني دعم فني (IT Support)",
      description: "دعم فني للعملاء وحل المشكلات التقنية المتعلقة بالشبكات والأنظمة التشغيلية.",
      city: "طرطوس",
      jobType: "دوام جزئي",
      location: "شارع الثورة، طرطوس",
      latitude: 34.8876,
      longitude: 35.8883,
      createdAt: DateTime(2025, 6, 3, 13, 0),
      hashtags: ["#دعم_فني", "#IT", "#شبكات", "#صيانة"],
      contactOptions: [
        ContactOption(type: ContactType.phone, value: "+963435555555"),
        ContactOption(type: ContactType.email, value: "support.tech@solutions.com"),
      ],
      ownerId: "seed_owner_1",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "مهندس معماري",
      description: "خبرة في تصميم المشاريع المعمارية، إعداد المخططات، والإشراف على التنفيذ.",
      city: "دمشق",
      jobType: "دوام كامل",
      location: "أبو رمانة، دمشق",
      latitude: 33.5000,
      longitude: 36.3000,
      createdAt: DateTime(2025, 6, 5, 8, 0),
      hashtags: ["#هندسة", "#معمارية", "#تصميم", "#اشراف"],
      contactOptions: [
        ContactOption(type: ContactType.whatsapp, value: "+963999123456"),
        ContactOption(type: ContactType.email, value: "arch.jobs@modernbuild.com"),
      ],
      ownerId: "seed_owner_3",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "أخصائي موارد بشرية",
      description: "مساعدة في عمليات التوظيف، التدريب، تقييم الأداء، وإدارة شؤون الموظفين.",
      city: "حلب",
      jobType: "دوام كامل",
      location: "شارع تشرين، حلب",
      latitude: 36.2100,
      longitude: 37.1500,
      createdAt: DateTime(2025, 6, 6, 10, 0),
      hashtags: ["#موارد_بشرية", "#توظيف", "#تدريب", "#HR"],
      contactOptions: [
        ContactOption(type: ContactType.email, value: "hr@successcorp.com"),
        ContactOption(type: ContactType.website, value: "https://www.successcorp.com/careers"),
      ],
      ownerId: "seed_owner_2",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "مدرس لغة عربية",
      description: "مطلوب مدرس لغة عربية متمكن لطلاب المرحلة الإعدادية والثانوية، مع خبرة في المناهج السورية.",
      city: "حمص",
      jobType: "مؤقت",
      location: "حي الوعر، حمص",
      latitude: 34.7350,
      longitude: 36.7150,
      createdAt: DateTime(2025, 6, 7, 16, 0),
      hashtags: ["#تعليم", "#لغة_عربية", "#مدرس", "#مناهج"],
      contactOptions: [
        ContactOption(type: ContactType.phone, value: "+963933445566"),
      ],
      ownerId: "seed_owner_1",
      distanceInKm: null,
    ),
    JobModel(
      id: const Uuid().v4(),
      title: "كاتب محتوى إبداعي",
      description: "إنشاء محتوى جذاب ومقالات متوافقة مع معايير SEO للمدونات ووسائل التواصل الاجتماعي.",
      city: "عن بعد",
      jobType: "عن بعد",
      location: "من أي مكان",
      latitude: 0.0,
      longitude: 0.0,
      createdAt: DateTime(2025, 6, 8, 11, 0),
      hashtags: ["#كتابة", "#محتوى", "#SEO", "#إبداع", "#عن_بعد"],
      contactOptions: [
        ContactOption(type: ContactType.email, value: "content.writer@digitalplatform.com"),
        ContactOption(type: ContactType.telegram, value: "https://t.me/@contentcreator"),
      ],
      ownerId: "seed_owner_3",
      distanceInKm: null,
    ),
  ];
}


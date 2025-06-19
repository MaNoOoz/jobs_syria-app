import 'package:animate_do/animate_do.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SharedWidgets {
  Widget buildLogo({double? size}) {
    return FadeInDown(
      delay: const Duration(milliseconds: 1600),
      child: Image.asset(
        'assets/icon/icon.png',
        fit: BoxFit.cover,
        width: size ?? 150,
      ),
    );
  }

  // Widget buildLoading() {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Container(height: 100, width: 100, color: Colors.black, child: Lottie.asset("assets/images/loading.json")),
  //       ],
  //     ),
  //   );
  // }

  Widget buildCustomAppbar({required VoidCallback? onPressed}) {
    return FadeInDown(
      child: Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIconWithText({required Icon icon, required text, required VoidCallback? onPressed}) {
    return FadeInDown(
      child: Row(
        children: [
          IconButton(onPressed: onPressed, icon: icon),
          const SizedBox(
            width: 4,
          ),
          Text(text)
        ],
      ),
    );
  }

  Widget buildGif() {
    return FadeInDown(
      child: Image.asset(
        'assets/icon/icon.png',
        fit: BoxFit.cover,
        width: 280,
      ),
    );
  }

  Widget buildDesc(description) {
    return FadeInDown(
      duration: Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
        child: Text(
          '$description',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade500, height: 1.5),
        ),
      ),
    );
  }

  Widget buildTextLeft(String? text, style, {align}) {
    // text = null;
    return FadeInLeft(
      delay: const Duration(milliseconds: 600),
      child: text == null
          ? Text(
              "بك",
              style: style,
            )
          : Text(
              "$text",
              style: style,
              textAlign: align ?? TextAlign.center,
            ),
    );
  }

  Widget buildTextRight(text, style, {align}) {
    return FadeInRight(
      delay: const Duration(milliseconds: 600),
      child: AutoSizeText(
        "$text",
        minFontSize: 16.0,
        maxFontSize: 40.0,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildTextTop(text, style, {align}) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: AutoSizeText(
        "$text",
        minFontSize: 16.0,
        maxFontSize: 40.0,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildTextDown(text, style, {align}) {
    return FadeInDown(
      delay: const Duration(milliseconds: 600),
      child: AutoSizeText(
        "$text",
        style: style,
        minFontSize: 16.0,
        maxFontSize: 40.0,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildShareBtn(text, style, {required VoidCallback onPressed}) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: ElevatedButton.icon(
        // minWidth: double.infinity,
        icon: Icon(
          Icons.share_sharp,
          size: 24.0,
          color: Colors.white,
        ),
        onPressed: onPressed,
        // color: Colors.black,
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        // padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        label: Text(
          "$text",
          style: style,
        ),
      ),
    );
  }

  Widget buildRequestBtn(text, style, {required VoidCallback? onPressed}) {
    return SizedBox(
      height: 80,
      width: Get.width * 0.8,
      child: FadeInDown(
        delay: const Duration(milliseconds: 600),
        child: MaterialButton(
          minWidth: Get.width / 5,
          onPressed: onPressed,
          disabledColor: Colors.grey,
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          child: Text(
            "$text",
            style: style,
          ),
        ),
      ),
    );
  }

  Widget buildRequestBtnWithLoading(text, style,
      {required VoidCallback? onPressed, required bool isLoading, required bool isVerified}) {
    return FadeInDown(
      delay: const Duration(milliseconds: 600),
      child: MaterialButton(
        elevation: 0,
        onPressed: onPressed,
        color: Colors.black,
        minWidth: Get.width * 0.8,
        height: 50,
        child: isLoading
            ? Container(
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  strokeWidth: 3,
                  color: Colors.black,
                ),
              )
            : isVerified
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 30,
                  )
                : Text(
                    text,
                    // style: mainStyleLW,
                  ),
      ),
    );
  }
}

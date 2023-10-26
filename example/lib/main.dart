import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CropController controller = CropController(
    aspectRatio: 0.3 / 0.2,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            "Crop Image",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Transform.flip(
          flipX: controller.isFlipImage ? true : false,
          child: CropImage(
            controller: controller,
            image: Image.asset("assets/08272011229.jpg"),
            paddingSize: 25.0,
            minimumImageSize: 200,
            maximumImageSize: 200,
            onCrop: (value) {},
          ),
        ),
        bottomNavigationBar: Container(
          height: 80,
          alignment: Alignment.center,
          child: _buildButtons(),
        ),
      );

  Widget _buildButtons() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => controller.aspectRatio = 1 / 1,
            child: SvgPicture.asset(
              "assets/app_image/resent.svg",
              height: 25,
              width: 25,
            ),
          ),
          InkWell(
            onTap: () => controller.rotateRight(),
            child: SvgPicture.asset(
              "assets/app_image/refresh.svg",
              height: 25,
              width: 25,
            ),
          ),
          InkWell(
            onTap: () {
              controller.filpImage(setState(() {}));
            },
            child: SvgPicture.asset(
              "assets/app_image/flip.svg",
              height: 25,
              width: 25,
            ),
          ),
          InkWell(
            onTap: () => _finished(),
            child: SvgPicture.asset(
              "assets/app_image/cropbutton.svg",
              height: 40,
              width: 30,
            ),
          ),
        ],
      );

  Future<void> _finished() async {
    final image = await controller.croppedImage();
    // ignore: use_build_context_synchronously
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(6.0),
          titlePadding: const EdgeInsets.all(8.0),
          title: const Text('Cropped image'),
          children: [
            const SizedBox(height: 5),
            image,
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

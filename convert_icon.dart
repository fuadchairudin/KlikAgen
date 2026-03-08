import 'dart:io';
import 'package:image/image.dart';

void main() {
  final inputPath =
      'C:\\Users\\A C E R N I T R O\\.gemini\\antigravity\\brain\\9298edaa-6784-4452-92ab-63da61e55460\\klik_agen_logo_transparent_1772939461467.png';
  final pngOutputPath = 'assets\\images\\app_logo.png';
  final icoOutputPath = 'windows\\runner\\resources\\app_icon.ico';

  // Read the generated image
  final imageBytes = File(inputPath).readAsBytesSync();
  final image = decodeImage(imageBytes);

  if (image == null) {
    print('Failed to decode image.');
    return;
  }

  // Create assets directory if it doesn't exist
  Directory('assets\\images').createSync(recursive: true);

  // Resize and save as PNG for app usage
  final resizedPng = copyResize(
    image,
    width: 512,
    height: 512,
    interpolation: Interpolation.average,
  );
  File(pngOutputPath).writeAsBytesSync(encodePng(resizedPng));
  print('Saved app logo PNG to $pngOutputPath');

  // Create ICO file
  // ICO format requires specific header and directory structure
  // For simplicity, we create a single-image ICO file (256x256, typical for Windows 10/11)
  final icoImage = copyResize(
    image,
    width: 256,
    height: 256,
    interpolation: Interpolation.average,
  );
  final pngBytes = encodePng(icoImage);

  final builder = BytesBuilder();
  // ICONDIR
  builder.add([0, 0]); // Reserved
  builder.add([1, 0]); // Type: 1 for Icon
  builder.add([1, 0]); // Number of images: 1

  // ICONDIRENTRY
  builder.addByte(0); // Width (0 means 256)
  builder.addByte(0); // Height (0 means 256)
  builder.addByte(0); // Color count
  builder.addByte(0); // Reserved
  builder.add([1, 0]); // Color planes
  builder.add([32, 0]); // Bits per pixel

  final size = pngBytes.length;
  builder.add([
    size & 0xFF,
    (size >> 8) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 24) & 0xFF,
  ]); // Image size

  final offset = 6 + 16; // ICONDIR (6 bytes) + 1 ICONDIRENTRY (16 bytes)
  builder.add([
    offset & 0xFF,
    (offset >> 8) & 0xFF,
    (offset >> 16) & 0xFF,
    (offset >> 24) & 0xFF,
  ]); // Image offset

  // Add the PNG data
  builder.add(pngBytes);

  File(icoOutputPath).writeAsBytesSync(builder.toBytes());
  print('Saved app icon ICO to $icoOutputPath');
}

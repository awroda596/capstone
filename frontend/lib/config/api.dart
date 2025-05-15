import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

final baseURI = kIsWeb
    ? 'http://localhost:3000'
    : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');

//place URI's here.  
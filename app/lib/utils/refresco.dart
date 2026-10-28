import 'package:flutter/foundation.dart';

final ValueNotifier<int> refrescoDeDatos = ValueNotifier(0);

void pedirRefresco() => refrescoDeDatos.value++;

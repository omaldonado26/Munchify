// QUÉ HACE ESTE ARCHIVO
// Señal global para que las pantallas vuelvan a pedir sus datos solas, por ejemplo
// cuando llega una notificación push o cuando la app vuelve a primer plano.

import 'package:flutter/foundation.dart';

/// Señal global para volver a pedir datos al servidor sin que la persona tenga que hacer nada.
///
/// Se dispara cuando llega una notificación push o cuando la app vuelve al primer plano.
/// Las pantallas que cargan datos (ver `FuturoRecargable`) la escuchan y se actualizan en silencio.
final ValueNotifier<int> refrescoDeDatos = ValueNotifier(0);

void pedirRefresco() => refrescoDeDatos.value++;

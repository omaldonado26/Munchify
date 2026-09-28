#!/usr/bin/env bash
# Genera las carpetas android/ ios/ web/ y aplica los permisos que necesita Munchify.
# Uso (dentro de la carpeta app/):  bash configurar_plataformas.sh
set -e
flutter create --org hn.uth --project-name munchify --platforms=android,ios,web .

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.CAMERA" "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.CAMERA"/>\n    <application#' "$MANIFEST"
fi
if ! grep -q "usesCleartextTraffic" "$MANIFEST"; then
  perl -0pi -e 's#<application\b#<application android:usesCleartextTraffic="true"#' "$MANIFEST"
fi

PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ] && ! grep -q NSCameraUsageDescription "$PLIST"; then
  perl -0pi -e 's#<dict>#<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Munchify usa la camara para escanear cupones y fotografiar evidencias.</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Munchify necesita acceder a tus fotos para adjuntar capturas de evidencia.</string>\n\t<key>NSAppTransportSecurity</key>\n\t<dict><key>NSAllowsArbitraryLoads</key><true/></dict>#' "$PLIST"
fi

flutter pub get
echo "✔ Plataformas configuradas. Ejecuta: flutter run"

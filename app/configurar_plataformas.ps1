# Genera las carpetas android/ ios/ web/ y aplica los permisos que necesita Munchify (Windows).
# Uso (dentro de la carpeta app\):  powershell -ExecutionPolicy Bypass -File configurar_plataformas.ps1
$ErrorActionPreference = "Stop"
flutter create --org hn.uth --project-name munchify --platforms=android,ios,web .

$manifest = "android\app\src\main\AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "android.permission.CAMERA") {
  $xml = $xml -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`r`n    <uses-permission android:name=`"android.permission.CAMERA`"/>`r`n    <application"
}
if ($xml -notmatch "usesCleartextTraffic") {
  $xml = $xml -replace "<application", "<application android:usesCleartextTraffic=`"true`""
}
[System.IO.File]::WriteAllText((Resolve-Path $manifest), $xml)

flutter pub get
Write-Host "Plataformas configuradas. Ejecuta: flutter run"

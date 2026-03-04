#!/bin/bash
set -e
echo "Iniciando compilação do Flutter Web..."
cd /home/dan/Documentos/fleetcare/frontend
flutter build web --release

echo "Copiando para Electron e compilando Windows..."
cp -r build/web/* /home/dan/Documentos/fleetcare/electron-wrapper/web/
cd /home/dan/Documentos/fleetcare/electron-wrapper
npm run build-win || echo "Falha ao buildar electron"
cp "dist/FleetCare Setup 1.0.0.exe" /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Windows_Setup.exe || echo "Erro copiando EXE"

echo "Compilando Android APK..."
cd /home/dan/Documentos/fleetcare/frontend
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Android.apk || echo "Erro ao copiar APK"

echo "Compilando Linux App..."
flutter build linux --release
tar -czf /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Linux_App.tar.gz -C build/linux/x64/release/ bundle/ || echo "Erro zipping linux bundle"

echo "Recompilação finalizada"

#!/bin/bash
echo "Aguardando compilação do Android..." > /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/STATUS.txt

# Aguarda o APK
while [ ! -f "/home/dan/Documentos/fleetcare/frontend/build/app/outputs/flutter-apk/app-release.apk" ]; do
  sleep 15
done
cp /home/dan/Documentos/fleetcare/frontend/build/app/outputs/flutter-apk/app-release.apk /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Android.apk
echo "Android APK Concluído! Aguardando Windows/Linux..." > /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/STATUS.txt

# Aguarda o Linux
while [ ! -d "/home/dan/Documentos/fleetcare/frontend/build/linux/x64/release/bundle" ]; do
  sleep 15
done
tar -czf /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Linux_App.tar.gz -C /home/dan/Documentos/fleetcare/frontend/build/linux/x64/release/ bundle/
echo "Linux App Concluído! Aguardando Windows EXE..." > /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/STATUS.txt

# Aguarda o Windows (Electron)
while [ ! -f "/home/dan/Documentos/fleetcare/electron-wrapper/dist/FleetCare Setup 1.0.0.exe" ]; do
  sleep 15
done
cp "/home/dan/Documentos/fleetcare/electron-wrapper/dist/FleetCare Setup 1.0.0.exe" "/home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/FleetCare_Windows_Setup.exe"

echo "TUDO PRONTO! ✅ Todos os apps foram gerados com sucesso e estão prontos para a apresentação." > /home/dan/Documentos/fleetcare/FleetCare_v1.0.0.0/STATUS.txt

# E-Chat Flutter App — Setup Guide

## Tera Setup Summary
- Package: `com.easytoshort.eachat`
- Backend URL: `https://chat.webzet.store`
- Firebase Project: `e-chat-e0fd5`

---

## Step 1 — google-services.json daalo

Firebase Console → E-chat project → Project Settings → Your Apps → Android

`google-services.json` download karke yahan daalo:
```
echat-app/android/app/google-services.json
```

---

## Step 2 — Flutter install karo (agar nahi hai)

```bash
sudo snap install flutter --classic
flutter doctor
```

Java bhi chahiye:
```bash
sudo apt install openjdk-17-jdk
```

---

## Step 3 — Dependencies install karo

```bash
cd echat-app
flutter pub get
```

---

## Step 4 — Local test karo (optional)

USB se phone connect karo ya emulator chalao:
```bash
flutter devices        # connected devices dekho
flutter run            # debug mode mein chalao
```

---

## Step 5 — GitHub pe push karo

```bash
cd echat-app
git init
git add .
git commit -m "E-Chat v1.0 initial"
git remote add origin https://github.com/TERA_USERNAME/echat-app
git push -u origin main
```

Push hote hi GitHub Actions automatically APK build karega.

---

## Step 6 — APK download karo

GitHub → tera repo → Actions tab → latest workflow → Artifacts section

2 APK milenge:
- `echat-debug.apk` — testing ke liye
- `echat-release.apk` — install ke liye

---

## Possible Errors & Fix

| Error | Fix |
|-------|-----|
| `google-services.json not found` | Step 1 dobara karo |
| `minSdkVersion error` | `build.gradle` mein `minSdkVersion 21` check karo |
| `Socket not connecting` | Cloudflare Tunnel mein WebSocket ON karo |
| `Notification not coming` | Firebase Console mein app registered hai check karo |
| `Call not working` | Same WiFi pe test karo pehle (TURN server baad mein) |
| `flutter pub get fail` | `flutter doctor` chalao, SDK path check karo |
| `Build failed on GitHub` | `google-services.json` committed hai check karo |

---

## Cloudflare Tunnel WebSocket Enable karna

HestiaCP → tera domain → Nginx config mein ye add karo:

```nginx
location /socket.io/ {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

---

## Backend Commands (reminder)

```bash
# Status check
pm2 status

# Restart
pm2 restart echat-backend

# Logs
pm2 logs echat-backend

# Health check
curl https://chat.webzet.store/health
```

---

## File Structure

```
echat-app/
├── lib/
│   ├── main.dart                    ← App entry + Firebase init
│   ├── utils/constants.dart         ← URLs + Colors
│   ├── models/models.dart           ← Data models
│   ├── providers/auth_provider.dart ← State management
│   ├── services/
│   │   ├── api_service.dart         ← HTTP calls
│   │   ├── socket_service.dart      ← Real-time
│   │   ├── call_service.dart        ← WebRTC
│   │   └── notification_service.dart← FCM
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/login_screen.dart
│   │   ├── auth/register_screen.dart
│   │   ├── auth/otp_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── chat/chat_screen.dart
│   │   ├── contacts/contacts_screen.dart
│   │   ├── profile/profile_screen.dart
│   │   ├── call/incoming_call_screen.dart
│   │   └── call/call_screen.dart
│   └── widgets/message_bubble.dart
└── android/
    ├── app/
    │   ├── build.gradle
    │   ├── google-services.json     ← TU KHUD DAALNA
    │   └── src/main/AndroidManifest.xml
    ├── build.gradle
    ├── settings.gradle
    └── gradle.properties
```

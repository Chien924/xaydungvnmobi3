HUONG DAN BUILD ONLINE KHONG CAN GIT TREN VPS

1) Giai nen file zip nay.
2) Vao GitHub.com -> New repository -> dat ten: xaydungvnmobi2
3) Trong repo moi, bam: Add file -> Upload files
4) Keo TOAN BO NOI DUNG BEN TRONG thu muc xaydungvnmobi2_build_online len GitHub.
   Luu y: tren GitHub phai thay pubspec.yaml nam o ngoai cung, ngang hang voi android, lib, assets.
5) Bam Commit changes.
6) Vao Codemagic.io -> Add application -> chon repo xaydungvnmobi2.
7) Chon workflow co san trong codemagic.yaml: Build Android APK / android-apk.
8) Bam Start new build.
9) Build xong vao Artifacts tai file app-release.apk.

Goi nay da loc bo file thua:
- build
- .dart_tool
- android/.gradle
- local.properties
- crash log hs_err

Da them san:
- codemagic.yaml
- quyen INTERNET cho WebView/API
- ten app: Xay Dung VN

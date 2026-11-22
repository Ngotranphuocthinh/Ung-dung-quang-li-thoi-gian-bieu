@echo off
cd /d %~dp0
echo === Study Alarm: chay tren Chrome ===
copy /y lib\main.dart lib\main_backup.tmp >nul
call flutter create . --project-name study_alarm
copy /y lib\main_backup.tmp lib\main.dart >nul
del lib\main_backup.tmp
if exist test\widget_test.dart del test\widget_test.dart
call flutter pub get
call flutter run -d chrome
pause

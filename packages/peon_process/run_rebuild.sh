#!/bin/bash
echo "starting xvfb session"
rm -f /tmp/.X99-lock
/usr/bin/Xvfb :99 &
export DISPLAY=:99

echo "starting flutter"
flutter pub upgrade
flutter run -d linux
#!/bin/bash
# livestream_menu.sh – listet alle Streaming-Optionen auf und startet die gewählte

# Pfade
MJPG_BIN="/usr/local/bin/mjpg_streamer"
WWW_DIR="/usr/local/share/mjpg-streamer/www"
PORT=8080
VIDEO_DEV="/dev/video0"

# Arrays für Menü und Kommandos
declare -a options
declare -a commands

# 1) CSI-Kamera erkennen
if command -v vcgencmd >/dev/null 2>&1 && vcgencmd get_camera | grep -q "detected=1"; then
  options+=("CSI-Kamera: Pi Camera Module (input_raspicam.so) • 640×480 @15fps")
  commands+=("$MJPG_BIN -i \"input_raspicam.so -fps 15 -x 640 -y 480\" \
 -o \"output_http.so -w $WWW_DIR -p $PORT\"")
fi

# 2) USB-Kamera erkennen und Formate holen
if [ -e "$VIDEO_DEV" ]; then
  # Liste alle Formate/Resolutions
  raw=$(v4l2-ctl --device="$VIDEO_DEV" --list-formats-ext)
  fmt=""
  while IFS= read -r line; do
    if [[ $line =~ \[[0-9]+\]:\ \'([A-Za-z0-9_]+)\' ]]; then
      fmt="${BASH_REMATCH[1]}"
    elif [[ $line =~ Size:\ Discrete\ ([0-9]+)x([0-9]+) ]]; then
      w=${BASH_REMATCH[1]}; h=${BASH_REMATCH[2]}
      # nächste Zeile Interval parsen
      read -r nxt
      if [[ $nxt =~ \(([0-9]+\.[0-9]+)\ fps\) ]]; then
        fps=${BASH_REMATCH[1]}
      else
        fps=15
      fi
      # Menü-Eintrag
      options+=("USB-Kamera: Format=$fmt • ${w}x${h} @${fps}fps")
      # entsprechendes Kommando zusammenbauen
      if [ "$fmt" = "MJPG" ]; then
        commands+=("$MJPG_BIN -i \"input_uvc.so -d $VIDEO_DEV -r ${w}x${h} -f $fps\" \
 -o \"output_http.so -w $WWW_DIR -p $PORT\"")
      else
        # YUYV oder anderes
        commands+=("$MJPG_BIN -i \"input_uvc.so -d $VIDEO_DEV -r ${w}x${h} -f $fps -y 0\" \
 -o \"output_http.so -w $WWW_DIR -p $PORT\"")
      fi
    fi
  done <<< "$raw"
fi

# 3) prüfen, ob überhaupt Optionen da sind
if [ ${#options[@]} -eq 0 ]; then
  echo "Fehler: Keine Kamera und keine Streaming-Optionen gefunden."
  exit 1
fi

# 4) Menü anzeigen
echo "=== Verfügbare Streaming-Optionen ==="
for i in "${!options[@]}"; do
  idx=$((i+1))
  echo " $idx) ${options[i]}"
done

# 5) Nutzerauswahl einlesen
read -p $'\nBitte Nummer wählen und mit Enter bestätigen: ' choice
if ! [[ $choice =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#options[@]} ]; then
  echo "Ungültige Auswahl."
  exit 1
fi

# 6) alten Stream killen und neuen starten
pkill mjpg_streamer 2>/dev/null || true
sel=$((choice-1))
echo "Starte: ${options[sel]}"
eval "${commands[sel]}" &

exit 0

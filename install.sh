# Abhängigkeiten installieren
sudo apt update
sudo apt upgrade -y

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt install cmake git libjpeg-dev build-essential v4l-utils -y 
# Quellcode holen und kompilieren

git clone https://github.com/jacksonliam/mjpg-streamer.git
cd mjpg-streamer/mjpg-streamer-experimental
make
sudo make install


# Webserver installieren
# Wechsle in den Pfad zurück
# In dieses Verzeichnis wechseln
cd "$SCRIPT_DIR" || exit 1

sudo apt install -y nginx
sudo mkdir -p /home/pi 
sudo cp livestream_menu.sh /home/pi/livestream_menu.sh
sudo cp stream_page.html /var/www/html/index.html
sudo ./install_nginx.sh


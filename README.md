# Smart Video Stream Device

This project contains scripts to configure a Raspberry Pi as a simple
video streaming device. It installs **mjpg-streamer**, a lightweight
HTTP server for MJPEG streams, and configures an Nginx reverse proxy so
that the stream can be accessed via a web page.

A small Flask server provides an API that allows you to start and stop
the stream and switch between the available camera modes (resolution and
frame rate). The web page `stream_page.html` uses this API to control the
stream from your browser.

## Installation

Run the install script on your Raspberry Pi:

```bash
./install.sh
```

After installation, start the control server:

```bash
python3 /home/pi/stream_server.py
```

Open the Pi's IP address in your browser. The web page will display a
list of available modes detected on your device. Choose one and click
**Start Stream**.

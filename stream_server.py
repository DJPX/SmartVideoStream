#!/usr/bin/env python3
import os
import re
import subprocess
from flask import Flask, request, jsonify

MJPG_BIN = "/usr/local/bin/mjpg_streamer"
WWW_DIR = "/usr/local/share/mjpg-streamer/www"
PORT = 8080
VIDEO_DEV = "/dev/video0"

app = Flask(__name__)
stream_proc = None
options = []
commands = []


def detect_options():
    """Detect available camera modes similar to livestream_menu.sh."""
    options.clear()
    commands.clear()

    # 1) check CSI camera
    try:
        out = subprocess.check_output(
            ["bash", "-c", "command -v vcgencmd >/dev/null 2>&1 && vcgencmd get_camera"],
            text=True,
        )
        if "detected=1" in out:
            options.append("CSI-Kamera: Pi Camera Module (640x480 @15fps)")
            cmd = (
                f"{MJPG_BIN} -i 'input_raspicam.so -fps 15 -x 640 -y 480' "
                f"-o 'output_http.so -w {WWW_DIR} -p {PORT}'"
            )
            commands.append(cmd)
    except subprocess.CalledProcessError:
        pass

    # 2) USB camera
    if os.path.exists(VIDEO_DEV):
        raw = subprocess.check_output(
            ["v4l2-ctl", f"--device={VIDEO_DEV}", "--list-formats-ext"], text=True
        )
        fmt = None
        lines = raw.splitlines()
        for i, line in enumerate(lines):
            m = re.search(r"\[[0-9]+\]: '\s*([A-Za-z0-9_]+)'", line)
            if m:
                fmt = m.group(1)
            m = re.search(r"Size:\s*Discrete\s*([0-9]+)x([0-9]+)", line)
            if m:
                w, h = m.group(1), m.group(2)
                fps = "15"
                if i + 1 < len(lines):
                    m2 = re.search(r"\(([^)]+) fps\)", lines[i + 1])
                    if m2:
                        fps = m2.group(1)
                options.append(f"USB-Kamera: Format={fmt} \u2022 {w}x{h} @{fps}fps")
                if fmt == "MJPG":
                    cmd = (
                        f"{MJPG_BIN} -i 'input_uvc.so -d {VIDEO_DEV} -r {w}x{h} -f {fps}' "
                        f"-o 'output_http.so -w {WWW_DIR} -p {PORT}'"
                    )
                else:
                    cmd = (
                        f"{MJPG_BIN} -i 'input_uvc.so -d {VIDEO_DEV} -r {w}x{h} -f {fps} -y 0' "
                        f"-o 'output_http.so -w {WWW_DIR} -p {PORT}'"
                    )
                commands.append(cmd)


def start_stream(idx: int):
    global stream_proc
    stop_stream()
    if 0 <= idx < len(commands):
        stream_proc = subprocess.Popen(commands[idx], shell=True)


def stop_stream():
    global stream_proc
    if stream_proc and stream_proc.poll() is None:
        stream_proc.terminate()
        stream_proc.wait(timeout=2)
    stream_proc = None
    # Ensure no stray mjpg_streamer
    subprocess.run(["pkill", "-f", "mjpg_streamer"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


@app.route("/api/options")
def api_options():
    detect_options()
    return jsonify([{"id": i + 1, "label": opt} for i, opt in enumerate(options)])


@app.route("/api/start")
def api_start():
    mode = int(request.args.get("mode", "0")) - 1
    if mode < 0 or mode >= len(commands):
        return "Invalid mode", 400
    start_stream(mode)
    return "", 204


@app.route("/api/stop")
def api_stop():
    stop_stream()
    return "", 204


@app.route("/api/mode")
def api_mode():
    mode = int(request.args.get("mode", "0")) - 1
    if mode < 0 or mode >= len(commands):
        return "Invalid mode", 400
    start_stream(mode)
    return "", 204


if __name__ == "__main__":
    detect_options()
    app.run(host="0.0.0.0", port=5000)


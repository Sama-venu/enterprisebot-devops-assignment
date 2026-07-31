import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(
        {
            "app": os.getenv("APP_NAME"),
            "version": os.getenv("VERSION"),
            "pod": socket.gethostname(),
        }
    )


@app.route("/healthz")
def health():
    return "OK", 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080"))
    )

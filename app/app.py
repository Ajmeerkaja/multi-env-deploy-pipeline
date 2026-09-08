import os
from flask import Flask

app = Flask(__name__)
ENV = os.environ.get("APP_ENV", "unknown")

@app.route("/")
def hello():
    return f"Hello from {ENV} environment!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
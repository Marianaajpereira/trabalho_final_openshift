from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World"

@app.route('/health')
def health():
    return {"status": "healthy"}

@app.route('/health/live')
def health_live():
    return {"status": "alive"}

@app.route('/health/ready')
def health_ready():
    return {"status": "ready"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)

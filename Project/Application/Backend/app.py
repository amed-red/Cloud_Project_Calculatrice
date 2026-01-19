from flask import Flask, request, jsonify
import os

app = Flask(__name__)

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/addition', methods=['POST'])
def addition():
    try:
        data = request.get_json()
        op1 = float(data.get('operand1', 0))
        op2 = float(data.get('operand2', 0))
        result = op1 + op2
        return jsonify({"result": result, "operation": "addition"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

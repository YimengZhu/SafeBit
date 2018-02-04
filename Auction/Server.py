from flask import Flask, jsonify, request, Response
import os.path
from flask_socketio import SocketIO, emit
import hashlib



#Instantiate our Node
app = Flask(__name__)
socketio = SocketIO(app)

def root_dir():  # pragma: no cover
    return os.path.abspath(os.path.dirname(__file__))


def get_file(filename):  # pragma: no cover
    try:
        src = os.path.join(root_dir(), filename)
        # Figure out how flask returns static files
        # Tried:
        # - render_template
        # - send_file
        # This should not be so non-obvious
        return open(src).read()
    except IOError as exc:
        return str(exc)

@app.route('/', methods=['GET'])
def mine():
	content = get_file('index.html')
	return Response(content, mimetype="text/html")

@app.route('/transations/new', methods=['POST'])
def new_transaction():
	pass

@socketio.on('my event')
def test_message(message):
    print(message['data']['bid'])
    message['data']['bid'] = hashlib.md5(str(message['data']['bid']).encode("utf-8")).hexdigest()
    print(message)



app.run(host='0.0.0.0')

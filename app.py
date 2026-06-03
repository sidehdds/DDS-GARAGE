import os
from flask import Flask, render_template, request, jsonify, session, redirect
from flask_cors import CORS
from flask_socketio import SocketIO, emit, join_room
from datetime import datetime
from dotenv import load_dotenv
from modules.api.plaque import rechercher_plaque
from modules.api.diagnostic import diagnostiquer, pannes_frequentes
from modules.api.conseil import conseiller
from modules.api.tuning import analyser_tuning
from modules.api.historique import analyser_historique

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dds-fallback-secret')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='gevent')

ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'ddsgarage2024')

conversations = {}
socket_to_session = {}

def ts():
    return datetime.now().strftime("%H:%M")


# ── Pages ──────────────────────────────────────────────────────────────────

@app.route("/")
def landing():
    return render_template("landing.html")

@app.route("/diagnostic")
def index():
    return render_template("index.html")

@app.route("/tuning")
def tuning():
    return render_template("tuning.html")

@app.route("/historique")
def historique():
    return render_template("historique.html")


# ── Admin auth ─────────────────────────────────────────────────────────────

@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    if session.get('admin'):
        return redirect("/admin")
    error = False
    if request.method == "POST":
        if request.form.get("password") == ADMIN_PASSWORD:
            session['admin'] = True
            return redirect("/admin")
        error = True
    return render_template("admin_login.html", error=error)

@app.route("/admin/logout")
def admin_logout():
    session.pop('admin', None)
    return redirect("/admin/login")

@app.route("/admin")
def admin_chat():
    if not session.get('admin'):
        return redirect("/admin/login")
    return render_template("admin_chat.html")


# ── REST API ───────────────────────────────────────────────────────────────

@app.route("/api/plaque", methods=["POST"])
def api_plaque():
    data = request.get_json()
    plaque_brute = data.get("plaque", "").strip()
    if not plaque_brute:
        return jsonify({"success": False, "error": "Plaque vide"}), 400
    plaque_clean = plaque_brute.upper().replace("-", "").replace(" ", "")
    if len(plaque_clean) == 7:
        plaque_formatee = f"{plaque_clean[:2]}-{plaque_clean[2:5]}-{plaque_clean[5:]}"
    else:
        plaque_formatee = plaque_clean
    resultat = rechercher_plaque(plaque_formatee)
    if not resultat or resultat.get("error"):
        return jsonify({"success": False, "error": "Plaque introuvable"}), 404
    return jsonify({"success": True, "data": resultat, "plaque": plaque_formatee})

@app.route("/api/diagnostic", methods=["POST"])
def api_diagnostic():
    data = request.get_json()
    vehicule = data.get("vehicule", {})
    symptomes = data.get("symptomes", "").strip()
    kilometrage = data.get("kilometrage", "").strip()
    if not symptomes:
        return jsonify({"success": False, "error": "Décrivez les symptômes"}), 400
    if not vehicule:
        return jsonify({"success": False, "error": "Véhicule non identifié"}), 400
    images = data.get("images", [])
    description_bruit = data.get("description_bruit", "").strip()
    try:
        resultat = diagnostiquer(vehicule, symptomes, kilometrage, images, description_bruit)
        return jsonify({"success": True, "diagnostic": resultat})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/pannes-frequentes", methods=["POST"])
def api_pannes_frequentes():
    data = request.get_json()
    vehicule = data.get("vehicule", {})
    kilometrage = data.get("kilometrage", "").strip()
    if not vehicule:
        return jsonify({"success": False, "error": "Véhicule non identifié"}), 400
    if not kilometrage:
        return jsonify({"success": False, "error": "Kilométrage requis"}), 400
    try:
        resultat = pannes_frequentes(vehicule, kilometrage)
        return jsonify({"success": True, "pannes": resultat})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/conseil", methods=["POST"])
def api_conseil():
    data = request.get_json()
    vehicule = data.get("vehicule", {})
    diagnostic = data.get("diagnostic", "")
    historique = data.get("historique", [])
    question = data.get("question", "").strip()
    if not question:
        return jsonify({"success": False, "error": "Question vide"}), 400
    if not vehicule:
        return jsonify({"success": False, "error": "Véhicule non identifié"}), 400
    try:
        reponse = conseiller(vehicule, diagnostic, historique, question)
        return jsonify({"success": True, "reponse": reponse})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/tuning", methods=["POST"])
def api_tuning():
    data = request.get_json()
    vehicule = data.get("vehicule", {})
    if not vehicule:
        return jsonify({"success": False, "error": "Véhicule non identifié"}), 400
    try:
        resultat = analyser_tuning(vehicule)
        return jsonify({"success": True, "data": resultat})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/historique", methods=["POST"])
def api_historique():
    data = request.get_json()
    vehicule = data.get("vehicule", {})
    kilometrage = data.get("kilometrage", "").strip()
    if not vehicule:
        return jsonify({"success": False, "error": "Véhicule non identifié"}), 400
    try:
        resultat = analyser_historique(vehicule, kilometrage)
        return jsonify({"success": True, "data": resultat})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


# ── Socket Events ──────────────────────────────────────────────────────────

@socketio.on('visitor_connect')
def on_visitor_connect(data):
    session_id = data.get('session_id')
    name = data.get('name', 'Visiteur')
    if not session_id:
        return
    join_room(f'visitor_{session_id}')
    socket_to_session[request.sid] = session_id
    if session_id not in conversations:
        conversations[session_id] = {
            'name': name, 'messages': [],
            'online': True, 'socket_id': request.sid, 'unread': 0
        }
        emit('new_visitor', {
            'session_id': session_id, 'name': name, 'messages': []
        }, room='admin')
    else:
        conversations[session_id]['online'] = True
        conversations[session_id]['socket_id'] = request.sid
        emit('visitor_online', {'session_id': session_id, 'name': name}, room='admin')

@socketio.on('visitor_message')
def on_visitor_message(data):
    session_id = data.get('session_id')
    message = data.get('message', '').strip()
    msg_type = data.get('type', 'text')
    if msg_type == 'text' and not message:
        return
    if not session_id or session_id not in conversations:
        return
    msg = {'role': 'visitor', 'text': message, 'type': msg_type, 'time': ts()}
    if msg_type in ('image', 'file'):
        msg['data'] = data.get('data', '')
        msg['fileName'] = data.get('fileName', 'fichier')
    conversations[session_id]['messages'].append(msg)
    conversations[session_id]['unread'] = conversations[session_id].get('unread', 0) + 1
    emit('visitor_message', {
        'session_id': session_id,
        'name': conversations[session_id]['name'],
        'message': msg
    }, room='admin')

@socketio.on('visitor_typing')
def on_visitor_typing(data):
    session_id = data.get('session_id')
    typing = data.get('typing', False)
    if session_id:
        emit('visitor_typing', {'session_id': session_id, 'typing': typing}, room='admin')

@socketio.on('admin_join')
def on_admin_join():
    join_room('admin')
    convs = {
        sid: {
            'name': c['name'], 'messages': c['messages'],
            'online': c['online'], 'unread': c.get('unread', 0)
        }
        for sid, c in conversations.items()
    }
    emit('conversations_list', {'conversations': convs})

@socketio.on('admin_message')
def on_admin_message(data):
    session_id = data.get('session_id')
    message = data.get('message', '').strip()
    msg_type = data.get('type', 'text')
    if msg_type == 'text' and not message:
        return
    if not session_id or session_id not in conversations:
        return
    msg = {'role': 'admin', 'text': message, 'type': msg_type, 'time': ts()}
    if msg_type in ('image', 'file'):
        msg['data'] = data.get('data', '')
        msg['fileName'] = data.get('fileName', 'fichier')
    conversations[session_id]['messages'].append(msg)
    conversations[session_id]['unread'] = 0
    emit('admin_reply', msg, room=f'visitor_{session_id}')
    emit('message_sent', {'session_id': session_id, 'message': msg}, room='admin')

@socketio.on('admin_typing')
def on_admin_typing(data):
    session_id = data.get('session_id')
    typing = data.get('typing', False)
    if session_id:
        emit('admin_typing', {'typing': typing}, room=f'visitor_{session_id}')

@socketio.on('disconnect')
def on_disconnect():
    sid = request.sid
    if sid in socket_to_session:
        session_id = socket_to_session.pop(sid)
        if session_id in conversations:
            conversations[session_id]['online'] = False
            emit('visitor_offline', {'session_id': session_id}, room='admin')


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5001))
    socketio.run(app, debug=True, port=port, host='0.0.0.0', allow_unsafe_werkzeug=True)

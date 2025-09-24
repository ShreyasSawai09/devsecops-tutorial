from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import sqlite3
import os
import subprocess
import hashlib
import requests
from werkzeug.utils import secure_filename
import pickle

app = Flask(__name__)
app.secret_key = "super-secret-key-123"  # Vulnerability: Hardcoded secret key

# Vulnerability: SQL Injection Database Setup
def init_db():
    conn = sqlite3.connect('vulnerable_app.db')
    cursor = conn.cursor()
    
    # Create users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'user'
        )
    ''')
    
    # Create products table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL,
            description TEXT
        )
    ''')
    
    # Insert sample data
    cursor.execute("INSERT OR IGNORE INTO users (username, password, email, role) VALUES (?, ?, ?, ?)",
                  ('admin', 'admin123', 'admin@vulnerable-shop.com', 'admin'))
    cursor.execute("INSERT OR IGNORE INTO users (username, password, email, role) VALUES (?, ?, ?, ?)",
                  ('user', 'password', 'user@vulnerable-shop.com', 'user'))
    
    cursor.execute("INSERT OR IGNORE INTO products (name, price, description) VALUES (?, ?, ?)",
                  ('Laptop', 999.99, 'High-performance laptop'))
    cursor.execute("INSERT OR IGNORE INTO products (name, price, description) VALUES (?, ?, ?)",
                  ('Phone', 699.99, 'Latest smartphone'))
    
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        # Vulnerability: SQL Injection
        conn = sqlite3.connect('vulnerable_app.db')
        cursor = conn.cursor()
        query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
        cursor.execute(query)
        user = cursor.fetchone()
        conn.close()
        
        if user:
            session['user_id'] = user[0]
            session['username'] = user[1]
            session['role'] = user[4]
            return redirect(url_for('dashboard'))
        else:
            return render_template('login.html', error='Invalid credentials')
    
    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html', username=session['username'])

@app.route('/search')
def search():
    query = request.args.get('q', '')
    if query:
        conn = sqlite3.connect('vulnerable_app.db')
        cursor = conn.cursor()
        # Vulnerability: SQL Injection in search
        search_query = f"SELECT * FROM products WHERE name LIKE '%{query}%' OR description LIKE '%{query}%'"
        cursor.execute(search_query)
        products = cursor.fetchall()
        conn.close()
        return render_template('search.html', products=products, query=query)
    return render_template('search.html', products=[], query=query)

@app.route('/profile')
def profile():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    # Vulnerability: Insecure Direct Object Reference
    user_id = request.args.get('id', session['user_id'])
    
    conn = sqlite3.connect('vulnerable_app.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return render_template('profile.html', user=user)
    return "User not found", 404

@app.route('/execute', methods=['POST'])
def execute_command():
    # Vulnerability: Command Injection
    if 'role' not in session or session['role'] != 'admin':
        return jsonify({'error': 'Unauthorized'}), 403
    
    command = request.json.get('command', '')
    try:
        # Extremely dangerous - direct command execution
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return jsonify({
            'output': result.stdout,
            'error': result.stderr,
            'return_code': result.returncode
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/upload', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        if 'file' not in request.files:
            return render_template('upload.html', error='No file selected')
        
        file = request.files['file']
        if file.filename == '':
            return render_template('upload.html', error='No file selected')
        
        # Vulnerability: Unrestricted File Upload
        filename = file.filename  # Not using secure_filename
        upload_path = os.path.join('uploads', filename)
        
        # Create uploads directory if it doesn't exist
        os.makedirs('uploads', exist_ok=True)
        file.save(upload_path)
        
        return render_template('upload.html', success=f'File uploaded: {filename}')
    
    return render_template('upload.html')

@app.route('/api/user/<int:user_id>')
def api_get_user(user_id):
    # Vulnerability: Missing authentication + Sensitive data exposure
    conn = sqlite3.connect('vulnerable_app.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, username, email, role FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return jsonify({
            'id': user[0],
            'username': user[1],
            'email': user[2],
            'role': user[3]
        })
    return jsonify({'error': 'User not found'}), 404

@app.route('/deserialize', methods=['POST'])
def deserialize_data():
    # Vulnerability: Insecure Deserialization
    if 'role' not in session or session['role'] != 'admin':
        return jsonify({'error': 'Unauthorized'}), 403
    
    try:
        data = request.json.get('data', '')
        # Dangerous: deserializing user input
        result = pickle.loads(data.encode('latin1'))
        return jsonify({'result': str(result)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/redirect')
def redirect_url():
    # Vulnerability: Open Redirect
    target = request.args.get('url', '/')
    return redirect(target)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

# Vulnerability: Debug mode enabled in production
if __name__ == '__main__':
    init_db()
    # Vulnerability: Running with debug=True and host='0.0.0.0'
    app.run(debug=True, host='0.0.0.0', port=5000)
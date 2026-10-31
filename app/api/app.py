import os

import psycopg
from flask import Flask, jsonify, request

app = Flask(__name__)


def connect():
    conn = psycopg.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    )
    conn.execute("CREATE TABLE IF NOT EXISTS tasks (id SERIAL PRIMARY KEY, title TEXT NOT NULL)")
    return conn


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/tasks")
def list_tasks():
    with connect() as conn:
        rows = conn.execute("SELECT id, title FROM tasks ORDER BY id").fetchall()
    return jsonify([{"id": row[0], "title": row[1]} for row in rows])


@app.post("/tasks")
def add_task():
    title = request.get_json()["title"]
    with connect() as conn:
        conn.execute("INSERT INTO tasks (title) VALUES (%s)", (title,))
    return jsonify(title=title), 201

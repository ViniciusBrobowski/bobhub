import os

import psycopg
from flask import Flask, Response

app = Flask(__name__)


def text_response(content, status=200):
    return Response(content, status=status, mimetype="text/plain")


@app.get("/")
def index():
    return text_response("BobHub OCI Application\n")


@app.get("/health")
def health():
    return text_response("healthy\n")


@app.get("/whoami")
def whoami():
    return text_response(
        f"cloud={os.getenv('APP_CLOUD', 'unknown')}\n"
        f"hostname={os.getenv('APP_HOSTNAME', 'unknown')}\n"
        f"private_ip={os.getenv('APP_PRIVATE_IP', 'unknown')}\n"
        f"version=v0.3.0\n"
    )


@app.get("/db-health")
def db_health():
    try:
        with psycopg.connect(
            host=os.environ["DB_HOST"],
            port=5432,
            dbname=os.environ["DB_NAME"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            sslmode="verify-full",
            sslrootcert="/etc/ssl/certs/ca-certificates.crt",
            connect_timeout=5,
        ) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()

        return text_response(
            "database=azure-postgresql\n"
            "status=healthy\n"
            "cloud=oci\n"
        )

    except Exception:
        return text_response(
            "database=azure-postgresql\n"
            "status=unhealthy\n"
            "cloud=oci\n",
            status=503,
        )
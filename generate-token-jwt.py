import jwt # pip install PyJWT==2.10.1
import time

SECRET_KEY = "clave-super-secreta"

def generate_jwt(username="testuser"):
    payload = {
        "sub": username,
        "iat": int(time.time()),
        "exp": int(time.time()) + 60 * 1  # expira en 1 minuto
    }

    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
    return token

if __name__ == "__main__":
    import sys
    username = sys.argv[1] if len(sys.argv) > 1 else "testuser"
    token = generate_jwt(username)
    print(f"Token JWT para '{username}':\n{token}")
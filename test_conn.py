import socket
import requests

def check_port(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(2)
        result = s.connect_ex((host, port))
        if result == 0:
            print(f"Port {port} is OPEN.")
            try:
                r = requests.get(f"http://{host}:{port}/")
                print(f"Response: {r.status_code}")
                return True
            except Exception as e:
                print(f"Port open but request failed: {e}")
        else:
            print(f"Port {port} is CLOSED.")
            return False

if __name__ == "__main__":
    check_port("127.0.0.1", 8001)

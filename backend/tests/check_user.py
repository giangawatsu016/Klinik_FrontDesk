import requests
API_URL='http://localhost:8001'
try:
    resp = requests.post(f'{API_URL}/auth/login', data={'username':'iknina', 'password':'password'})
    resp.raise_for_status()
    print("Token Resp:", resp.json())
    token = resp.json().get("access_token")
    headers = {'Authorization': f'Bearer {token}'}
    me = requests.get(f'{API_URL}/auth/me', headers=headers)
    print("User Me:", me.json())
except Exception as e:
    print("Error:", e)

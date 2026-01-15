import os
import sys
from dotenv import load_dotenv

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from services.satu_sehat_service import satu_sehat_client

print("Testing KFA Search...")
try:
    results = satu_sehat_client.search_kfa_products("Paracetamol")
    print("\n--- Results ---")
    for r in results:
        print(r)
    print("--- End of Results ---")
except Exception as e:
    print(f"Test Failed: {e}")

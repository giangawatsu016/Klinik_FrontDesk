import sys
import os

# Add parent directory to path to import backend modules
sys.path.append(os.getcwd())

from backend.services.frappe_service import frappe_client

def reset_frappe():
    print("WARNING: This will delete ALL Customers and Events from the remote Frappe instance.")
    
    # 1. Delete Events (Appointments)
    print("Fetching Events (Appointments)...")
    events = frappe_client.get_list("Event")
    print(f"Found {len(events)} Events.")
    
    for event in events:
        frappe_client.delete_document("Event", event['name'])
        
    print("All Events deleted.")

    # 2. Delete Customers (Patients)
    print("Fetching Customers...")
    
    while True:
        try:
            customers = frappe_client.get_list("Customer")
            if not customers:
                print("No more Customers found.")
                break
                
            print(f"Found batch of {len(customers)} Customers. Deleting...")
            
            for customer in customers:
                frappe_client.delete_document("Customer", customer['name'])
        except Exception as e:
            print(f"Error in deletion loop: {e}")
            break
        
    print("All Customers deleted.")
    print("Remote Frappe Reset Complete.")

if __name__ == "__main__":
    reset_frappe()

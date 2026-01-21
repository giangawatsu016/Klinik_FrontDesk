import sys
import os

# Add root to sys.path
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(os.path.dirname(current_dir))
    if root_dir not in sys.path:
        sys.path.append(root_dir)

from backend.services.frappe_service import frappe_client
import requests
import json

def force_delete_patient(patient_name):
    print(f"Attempting to force delete Patient: {patient_name}")
    
    # 1. Find Linked Contacts
    # Native Frappe Client usage because we need custom filters for Child Table
    # Contact has a child table 'links'. We need to query Contacts where links.link_name = patient_name
    # Since REST API list filtering on child table is tricky, we'll try to find Contacts where name is like patient_name (default naming)
    # OR better, if we built a proper Dynamic Link query.
    
    # Simple approach: Fetch all contacts, filter in python (inefficient but works for small data)
    # Better approach: Search contact by 'link_name' field if exposing it, but it is in child table.
    
    # Correct way via REST API for Dynamic Links:
    # We can't easily filter by child table via simple REST API without server script.
    # But usually, Contact name is "FirstName LastName".
    # Let's try to fetch links associated.
    
    # Workaround: "Silvi Mayora - 1" usually has a contact named "Silvi Mayora-Silvi Mayora - 1" (as seen in error message).
    # We can try to guess the contact name or search common patterns.
    
    # Error invalidates: "linked with Contact Silvi Mayora-Silvi Mayora - 1"
    # So we can target that specific contact name logic if we can parsing it, OR:
    
    # Let's try to delete the Patient and parse the error message? No, that's brittle.
    
    # Let's Search for Contacts that *might* belong to this patient.
    # ERPNext usually links them.
    
    # Try fetching Contact list using the patient name as a filter? No.
    
    # Let's try to GET the Patient doc, sometimes it has links? No.
    
    # Let's just hardcode the logic to find the likely Contact name.
    # The error message says: "Silvi Mayora-Silvi Mayora - 1"
    # This looks like "{PatientName}-{PatientName}" pattern or "{Customer}-{Patient}"?
    
    # Actually, let's use the `frappe_client` to list Contacts and look for matches.
    contacts = frappe_client.get_list("Contact", filters={})
    
    # We need to find the specific contact.
    # Since I cannot easily query child tables, I will try to delete the specific contact mentioned in the screenshot if known, 
    # OR I will simply ask the user to run this script which will try to find it.
    
    # AUTOMATED STRATEGY:
    # 1. Try to delete Patient.
    # 2. If fail, catch error.
    # 3. IF error message contains "linked with Contact", extract Contact Name.
    # 4. Delete Contact.
    # 5. Retry Patient delete.
    
    response = frappe_client.delete_document("Patient", patient_name)
    if not response:
        # It failed (printed error in service). 
        # But `delete_document` in service swallows the error text and just prints it.
        # I need to modify implementation or just do the request manually here to capture the text.
        pass

    # Manual Request to capture error
    url = f"{frappe_client.base_url}/api/resource/Patient/{patient_name}"
    print(f"DELETE {url}")
    resp = requests.delete(url, headers=frappe_client.headers)
    
    if resp.status_code == 200 or resp.status_code == 202:
        print("Successfully deleted Patient.")
        return

    print(f"Failed to delete. Status: {resp.status_code}")
    print(f"Response: {resp.text}")
    
    if "LinkExistsError" in resp.text or "linked with" in resp.text:
        import re
        # Regex to find contact name: "linked with Contact (.*?) at Row"
        # Message: "... linked with Contact Silvi Mayora-Silvi Mayora - 1 at Row: 1"
        match = re.search(r"linked with Contact (.*?) at Row", resp.text)
        if match:
            contact_name = match.group(1).strip()
            print(f"Found linked Contact: {contact_name}")
            
            # Delete Contact
            print(f"Deleting Contact {contact_name}...")
            del_resp = requests.delete(f"{frappe_client.base_url}/api/resource/Contact/{contact_name}", headers=frappe_client.headers)
            
            if del_resp.status_code == 200 or del_resp.status_code == 202:
                print("Contact deleted.")
                # Retry Patient
                print("Retrying Patient deletion...")
                requests.delete(url, headers=frappe_client.headers)
                print("Patient deleted (hopefully).")
            else:
                print(f"Could not delete Contact: {del_resp.text}")

if __name__ == "__main__":
    # Hardcoded target from screenshot
    target_patient = "Silvi Mayora - 1" 
    force_delete_patient(target_patient)

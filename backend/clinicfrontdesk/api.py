import frappe
from frappe import _

@frappe.whitelist(allow_guest=True)
def get_doctors():
    """
    Get list of doctors.
    Method: GET
    URL: /api/method/api_clinic.clinicfrontdesk.api.get_doctors
    """
    try:
        doctors = frappe.get_all("Doctors", fields=["*"], ignore_permissions=True)
        return {
            "status": "success",
            "data": doctors
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Doctors API Error")
        return {
            "status": "error",
            "message": str(e)
        }

@frappe.whitelist(allow_guest=True)
def get_doctor(name):
    """
    Get single doctor details.
    """
    try:
        if not frappe.db.exists("Doctors", name):
            return {
                "status": "error",
                "message": "Doctor not found"
            }
            
        doctor = frappe.get_doc("Doctors", name)
        return {
            "status": "success",
            "data": doctor
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Doctor API Error")
        return {
            "status": "error",
            "message": str(e)
        }

@frappe.whitelist(allow_guest=True)
def get_issuers():
    """
    Get list of issuers (Payment Categories).
    """
    try:
        # Assuming an 'Issuer' DocType exists or using a hardcoded list for now
        # because the original FastAPI logic is being replaced.
        # In Frappe, we can either fetch from a DocType or return a dynamic list.
        issuers = frappe.get_all("Issuer", fields=["*"], ignore_permissions=True)
        return {
            "status": "success",
            "data": issuers
        }
    except Exception as e:
        # Fallback to empty list or basic categories if DocType not yet created
        return {
            "status": "success",
            "data": [
                {"issuer": "Umum", "nama": "Umum", "issuerId": 1},
                {"issuer": "BPJS", "nama": "BPJS Kesehatan", "issuerId": 2}
            ]
        }

@frappe.whitelist(allow_guest=True)
def get_queue():
    return {"status": "success", "data": []}

@frappe.whitelist(allow_guest=True)
def search_patients(query=None):
    return {"status": "success", "data": []}

@frappe.whitelist(allow_guest=True)
def register_patient(**kwargs):
    # Dummy implementation - in production, this should create a Patient record
    data = frappe.form_dict
    return {"status": "success", "data": data}

@frappe.whitelist(allow_guest=True)
def add_to_queue(**kwargs):
    return {"status": "success", "message": "Added to queue"}

@frappe.whitelist(allow_guest=True)
def get_patients():
    return {"status": "success", "data": []}

@frappe.whitelist(allow_guest=True)
def get_dashboard_overview():
    return {"status": "success", "data": {}}

@frappe.whitelist(allow_guest=True)
def get_idle_doctors():
    return {"status": "success", "data": []}

@frappe.whitelist(allow_guest=True)
def get_app_config(key):
    # Dummy implementation
    return {"status": "success", "data": {"value": ""}}

@frappe.whitelist(allow_guest=True)
def save_app_config(key, value):
    return {"status": "success", "message": "Config saved"}

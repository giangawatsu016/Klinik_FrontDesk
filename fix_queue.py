import frappe

frappe.connect(site="clinic.localhost")
try:
    result = frappe.db.sql("SELECT name FROM `tabClinic FrontDesk Queue` WHERE name LIKE 'FDQ-.%%'")
    if result:
        for row in result:
            frappe.db.sql("DELETE FROM `tabClinic FrontDesk Queue` WHERE name=%s", row[0])
            print(f"Deleted: {row[0]}")
        frappe.db.commit()
        print("Commit done")
    else:
        print("No stuck entries found")
except Exception as e:
    print(f"Error: {e}")
finally:
    frappe.destroy()

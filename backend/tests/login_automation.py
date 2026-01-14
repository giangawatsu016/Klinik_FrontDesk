import os
import time
from datetime import datetime
from playwright.sync_api import sync_playwright
from docx import Document
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH

# --- CONFIGURATION ---
FRONTEND_URL = "http://localhost:8080" # Ganti sesuai URL Flutter Anda (misal: localhost:xxxxx)
REPORT_DIR = "test_reports"

# Credentials
VALID_USER = "admin"
VALID_PASS = "admin123"
INVALID_USER = "wronguser"
INVALID_PASS = "wrongpass"

# Scenarios
SCENARIOS = [
    {"name": "1. Login Sukses (Valid/Valid)", "u": VALID_USER, "p": VALID_PASS, "expect_success": True},
    {"name": "2. Login Gagal (Invalid/Invalid)", "u": INVALID_USER, "p": INVALID_PASS, "expect_success": False},
    {"name": "3. Login Gagal (Valid/Invalid)", "u": VALID_USER, "p": INVALID_PASS, "expect_success": False},
    {"name": "4. Login Gagal (Invalid/Valid)", "u": INVALID_USER, "p": VALID_PASS, "expect_success": False},
    {"name": "5. Login Gagal (Empty/Empty)", "u": "", "p": "", "expect_success": False},
    {"name": "6. Login Gagal (Valid/Empty)", "u": VALID_USER, "p": "", "expect_success": False},
    {"name": "7. Login Gagal (Invalid/Empty)", "u": INVALID_USER, "p": "", "expect_success": False},
    {"name": "8. Login Gagal (Empty/Valid)", "u": "", "p": VALID_PASS, "expect_success": False},
    {"name": "9. Login Gagal (Empty/Invalid)", "u": "", "p": INVALID_PASS, "expect_success": False},
]

def ensure_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

def run_tests():
    ensure_dir(REPORT_DIR)
    
    # Initialize Report
    doc = Document()
    doc.add_heading('Laporan Test Automation Login', 0)
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    doc.add_paragraph(f"Tanggal Run: {today_str}")
    doc.add_paragraph(f"Target URL: {FRONTEND_URL}")
    doc.add_paragraph("-" * 50)

    with sync_playwright() as p:
        # Launch Browser
        browser = p.chromium.launch(headless=False) # Headless=False to see it running
        context = browser.new_context(viewport={'width': 1280, 'height': 720})
        
        for scenario in SCENARIOS:
            print(f"Running: {scenario['name']}...")
            
            page = context.new_page()
            try:
                page.goto(FRONTEND_URL)
                
                # Wait for username field (Flutter puts inputs in nested structure, usually identified by label or type)
                # Note: Flutter Web accessibility labels/semantics can be tricky. 
                # We often target by 'semantics-label' or standard input types if enabled.
                # Assuming standard HTML renderer or inputs are accessible. 
                # Using broad selectors for safety.
                
                # Wait for load
                page.wait_for_timeout(2000)

                # 1. Fill Username
                user_input = page.get_by_label("Username") # Adjust selector based on your Flutter Code
                if not user_input.count(): 
                     user_input = page.locator("input[type='text']").first # Fallback
                
                if scenario["u"]:
                    user_input.fill(scenario["u"])
                else:
                    user_input.fill("")

                # 2. Fill Password
                pass_input = page.get_by_label("Password") # Adjust selector
                if not pass_input.count():
                     pass_input = page.locator("input[type='password']").first # Fallback

                if scenario["p"]:
                     pass_input.fill(scenario["p"])
                else:
                     pass_input.fill("")

                # 3. Click Login
                # Login button usually has text "Login"
                login_btn = page.get_by_role("button", name="Login")
                if not login_btn.count():
                     login_btn = page.locator("text=Login") # Fallback
                
                login_btn.click()
                
                # 4. Wait for Result
                page.wait_for_timeout(2000) # Wait for animation/api
                
                # Capture Screenshot
                screenshot_path = os.path.join(REPORT_DIR, f"screen_{scenario['name'].split('.')[0].strip()}.png")
                page.screenshot(path=screenshot_path)
                
                # Validate Logic (Simplified for Visual Report)
                # Check for dashboard element OR Error Snackbar
                
                # Add to Report
                p = doc.add_paragraph()
                p.add_run(f"\nScenario: {scenario['name']}").bold = True
                doc.add_paragraph(f"Input: User='{scenario['u']}' | Pass='{scenario['p']}'")
                
                # Embed Screenshot
                doc.add_picture(screenshot_path, width=Inches(5.0))
                doc.add_paragraph("-" * 30)
                
            except Exception as e:
                print(f"Error in {scenario['name']}: {e}")
                doc.add_paragraph(f"ERROR executing scenario: {e}")
            
            finally:
                page.close()

        browser.close()

    # Save Report
    report_filename = f"Test_Auto_Login_{today_str}.docx"
    doc.save(os.path.join(REPORT_DIR, report_filename))
    print(f"\n[OK] Report generated: {os.path.join(REPORT_DIR, report_filename)}")

if __name__ == "__main__":
    url_input = input(f"Enter Frontend URL (default: {FRONTEND_URL}): ")
    if url_input.strip():
        FRONTEND_URL = url_input.strip()
    
    run_tests()

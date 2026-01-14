

import time
from playwright.sync_api import sync_playwright
import sys

# Default URL
URL = "http://localhost:61182/"
if len(sys.argv) > 1:
    URL = sys.argv[1]

def inspect():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        print(f"Navigating to {URL}...")
        page.goto(URL)
        
        print("Waiting for 10s for hydration...")
        page.wait_for_timeout(10000)

        print("Pressing Tab keys to force accessibility tree generation...")
        page.keyboard.press("Tab")
        page.wait_for_timeout(500)
        page.keyboard.press("Tab")
        page.wait_for_timeout(500)
        page.keyboard.press("Tab")
        page.wait_for_timeout(1000)
        
        # JS to traverse deep DOM including Shadow Roots
        print("\n--- DEEP DOM DUMP ---")
        dump_script = """
        (() => {
            function dump(node, depth=0) {
                let output = "";
                let indent = " ".repeat(depth * 2);
                
                if (node.nodeType === Node.ELEMENT_NODE) {
                    let desc = node.tagName.toLowerCase();
                    if (node.id) desc += `#${node.id}`;
                    if (node.className) desc += `.${node.className}`;
                    if (node.getAttribute("aria-label")) desc += ` [aria-label="${node.getAttribute("aria-label")}"]`;
                    if (node.tagName === "INPUT") {
                         desc += ` [type="${node.type}"]`;
                         desc += ` [name="${node.name}"]`;
                    }
                    output += `${indent}<${desc}>\n`;
                    
                    if (node.shadowRoot) {
                        output += `${indent}  #shadow-root\n`;
                        Array.from(node.shadowRoot.childNodes).forEach(child => {
                            output += dump(child, depth + 2);
                        });
                    }
                }
                
                Array.from(node.childNodes).forEach(child => {
                    output += dump(child, depth + 1);
                });
                return output;
            }
            return dump(document.body);
        })()
        """
        try:
            tree = page.evaluate(dump_script)
            print(tree[:5000]) # Limit output
        except Exception as e:
            print(f"Error dumping DOM: {e}")

        print("\n--- LOCATOR CHECK ---")
        print(f"Inputs found by locator('input'): {page.locator('input').count()}")
        print(f"Semantics found by locator('flt-semantics'): {page.locator('flt-semantics').count()}")

        browser.close()

if __name__ == "__main__":
    inspect()


filename = r"c:\Users\1672\.gemini\antigravity\scratch\Klinik_Admin\frontend\lib\screens\registration.dart"
keyword = "_submitToQueue"

try:
    with open(filename, "r", encoding="utf-8") as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if keyword in line and "{" in line and "void" in line:
                print(f"Found definition at line {i+1}: {line.strip()}")
            elif keyword in line:
                print(f"Occurrence at line {i+1}: {line.strip()}")
except Exception as e:
    print(f"Error: {e}")

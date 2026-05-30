import os
import re

count = 0
dirs_to_check = ['lib', 'packages']
for d in dirs_to_check:
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.endswith('.dart'):
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8') as file:
                    content = file.read()
                
                # regex to find .withOpacity(x)
                new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as file:
                        file.write(new_content)
                    count += 1
                    print(f"Fixed {path}")

print(f"Fixed opacity in {count} files")

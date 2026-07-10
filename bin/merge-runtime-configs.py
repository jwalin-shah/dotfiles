#!/usr/bin/env python3
import sys, json, os, re

def strip_comments(text):
    # Strip single line comments
    text = re.sub(r'(?m)^\s*//.*$', '', text)
    # Strip inline comments (careful with URLs, but ok for simple configs)
    text = re.sub(r'(?<!:)//.*$', '', text, flags=re.MULTILINE)
    # Strip block comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    return text

def deep_merge(live, base):
    """
    Merges base into live. Base overrides live for existing keys.
    For lists, if base has a list, it usually replaces, BUT for permissions we might want to union.
    Let's union lists to be safe, or just replace if they are primitive arrays?
    Let's union lists if they contain strings/primitives, otherwise replace.
    Actually, let's just do what `jq '.[0] * .[1]'` does for dicts, but for lists, replace them with base if base provides them.
    Wait! If base provides "permissions.allow", we want to ENFORCE the dotfiles' allow list. 
    So base replacing live's list is correct.
    """
    if isinstance(live, dict) and isinstance(base, dict):
        merged = live.copy()
        for k, v in base.items():
            if k in merged:
                merged[k] = deep_merge(merged[k], v)
            else:
                merged[k] = v
        return merged
    else:
        # Base overrides
        return base

def main():
    if len(sys.argv) != 3:
        print("Usage: merge-runtime-configs.py <base_file> <live_file>")
        sys.exit(1)
        
    base_file = sys.argv[1]
    live_file = sys.argv[2]
    
    if not os.path.exists(base_file):
        return

    with open(base_file, 'r') as f:
        base_text = strip_comments(f.read())
        try:
            base_json = json.loads(base_text)
        except json.JSONDecodeError as e:
            print(f"Error parsing base file {base_file}: {e}")
            return

    if not os.path.exists(live_file):
        os.makedirs(os.path.dirname(live_file), exist_ok=True)
        with open(live_file, 'w') as f:
            json.dump(base_json, f, indent=2)
        return

    with open(live_file, 'r') as f:
        live_text = strip_comments(f.read())
        try:
            live_json = json.loads(live_text)
        except json.JSONDecodeError as e:
            print(f"Error parsing live file {live_file}: {e}. Overwriting with base.")
            live_json = {}

    merged = deep_merge(live_json, base_json)

    with open(live_file, 'w') as f:
        json.dump(merged, f, indent=2)

if __name__ == "__main__":
    main()

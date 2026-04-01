"""Add colored language tags above code blocks in all _entries/*.md files."""

import glob
import re

TAG_MAP = {
    'sh': ('shell', 'shell'),
    'bash': ('shell', 'shell'),
    'sql': ('sql', 'sql'),
    'psql': ('psql', 'psql'),
    'kql': ('kql', 'kql'),
}

SPAN_PATTERN = re.compile(r'<span class="lang-tag')

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    changed = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Check if this line is a code fence with a language
        if stripped.startswith('```'):
            lang = stripped[3:].strip()
            if lang in TAG_MAP:
                tag_class, tag_text = TAG_MAP[lang]
                span = f'<span class="lang-tag lang-tag-{tag_class}">{tag_text}</span>\n'

                # Check if the previous non-empty line already has a lang-tag
                already_tagged = False
                for j in range(len(new_lines) - 1, -1, -1):
                    prev = new_lines[j].strip()
                    if prev == '':
                        continue
                    if SPAN_PATTERN.search(prev):
                        already_tagged = True
                    # Also skip if it was the old **`label`** format
                    if prev in ('**`shell`**', '**`psql`**', '**`sql`**', '**`kql`**'):
                        already_tagged = True
                    break

                if not already_tagged:
                    new_lines.append(span)
                    changed = True

        new_lines.append(line)

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        return True
    return False


def main():
    files = sorted(glob.glob(r'_entries\*.md'))
    total_changed = 0
    for f in files:
        if process_file(f):
            print(f'  Updated: {f}')
            total_changed += 1
        else:
            print(f'  Skipped: {f} (no code blocks to tag)')
    print(f'\nDone. {total_changed} files updated out of {len(files)} total.')


if __name__ == '__main__':
    main()

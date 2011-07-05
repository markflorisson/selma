import re
import sys

stored = set()
invalid = set()
for lineno, line in enumerate(open(sys.argv[1])):
    if line.lstrip().startswith('.method'):
        stored = set()
    else:
        m = re.search('istore (\d+)', line)
        if m:
            stored.add(m.group(1))

        m = re.search('iload (\d+)', line)
        if m and m.group(1) not in stored and line not in invalid:
            invalid.add(line)
            print 'Invalid iload on line %d: %s' % (lineno + 1, line.strip())

# The two summary tables the charts are drawn from, from the raw tables of one
# DartNative run and two Flutter runs (Flutter: the better run per row).
#   python3 summary.py <dartnative.txt> <flutter1.txt> [<flutter2.txt>...]
import re, sys
def rows(path):
    out = {}
    for line in open(path):
        m = re.match(r'^\| ([a-z][^|]*?) \| (\w+) \| ([\d.]+) \|', line)
        if m: out[m.group(1)] = float(m.group(3))
    return out
dn = rows(sys.argv[1]); fl = [rows(p) for p in sys.argv[2:]]
def f(name): return min(r[name] for r in fl if name in r)
def ratio(a, b):
    r = a / b
    if r >= 1.05:
        return f'{r:.0f}x faster' if r >= 100 else f'{r:.1f}x faster'
    if r <= 1 / 1.05: return f'{1/r:.1f}x slower'
    return 'same'
head = '| shared_preferences, Flutter (ms) | dartnative_shared_preferences (ms) | dartnative_shared_preferences |'
print('| Operation ' + head)
print('| --- | ---: | ---: | ---: |')
for label, name in [('Write, 1 key', 'string, every set awaited'),
                    ('Write, 1000 keys', 'string, every set awaited, 1000 keys'),
                    ('Read, 1 key', 'string read'),
                    ('Read, 1000 keys', 'string read, 1000 keys')]:
    print(f'| {label} | {f(name):.3f} | {dn[name]:.3f} | {ratio(f(name), dn[name])} |')
print()
print('| Type ' + head)
print('| --- | ---: | ---: | ---: |')
for t in ['string', 'integer', 'double', 'boolean', 'string list']:
    name = f'{t}, every set awaited'
    print(f'| {t} | {f(name):.3f} | {dn[name]:.3f} | {ratio(f(name), dn[name])} |')

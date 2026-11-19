import sys,re
def rows(path):
    out={}
    for line in open(path):
        m=re.match(r'^\| ([a-z][^|]*?) \| (\w+) \| ([\d.]+) \|',line)
        if m: out[m.group(1)]=(m.group(2),float(m.group(3)))
    return out
# --stored-ratio: a ratio also between stored writes that got to different
# points (Android: Flutter's committed, ours mapped); the durability column
# names both, and the page says what each guarantees.
stored_ratio='--stored-ratio' in sys.argv
args=[a for a in sys.argv[1:] if not a.startswith('--')]
dn=rows(args[0]); fl=[rows(p) for p in args[1:]]
order=list(dn.keys())
print('| Case | Flutter (ms) | DartNative (ms) | DartNative | Durability, Flutter / DartNative |')
print('| --- | ---: | ---: | ---: | --- |')
group=None
for name in order:
    d_dur,d_ms=dn[name]
    cands=[f[name] for f in fl if name in f]
    f_dur=cands[0][0]; f_ms=min(c[1] for c in cands)
    g='Reads' if d_dur=='read' else ('Writes not awaited' if 'not awaited' in name else 'Stored writes')
    if g!=group:
        group=g; print(f'| **{g}** | | | | |')
    # Both survive the app being killed right after and reach storage
    # later: comparable (see Durability.mapped).
    same = f_dur==d_dur or {f_dur,d_dur}=={'userDefaults','mapped'} or (
        stored_ratio and {f_dur,d_dur}=={'committed','mapped'})
    if same:
        r=f_ms/d_ms
        fmt=(lambda x: f'{x:.0f}x') if r>=10 else (lambda x: f'{x:.1f}x')
        ratio=f'{fmt(r)} faster' if r>=1.05 else (f'{1/r:.1f}x slower' if r<=1/1.05 else 'same')
    else:
        ratio=''
    dur=d_dur if f_dur==d_dur else f'{f_dur} / {d_dur}'
    print(f'| {name} | {f_ms:.3f} | {d_ms:.3f} | {ratio} | {dur} |')

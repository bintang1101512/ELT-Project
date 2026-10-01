"""Gambar lineage dbt dari manifest.json asli (hasil `dbt parse`), gaya monokrom.

Pakai:
    ~/.venv/bin/python make_lineage.py /tmp/dbt_target/manifest.json lineage.png

Hanya memuat nama model, lapisan, jumlah tes, dan ketergantungan. Tidak ada data bisnis.
"""
import json
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

manifest = json.load(open(sys.argv[1]))
out = sys.argv[2]

INK, MUTED, LINE, PANEL = '#0F172A', '#475569', '#CBD5E1', '#F1F5F9'
W, H = 3.3, 0.82

# ---- jumlah tes per model (hanya model pemilik tes) ----
tests_per = {}
for n in manifest['nodes'].values():
    if n['resource_type'] == 'test':
        owner = n.get('attached_node') or (n['depends_on']['nodes'] or [None])[-1]
        if owner:
            tests_per[owner] = tests_per.get(owner, 0) + 1

# ---- node ----
src_label = {'raw_api': 'raw_api_transaction'}
nodes = {}
for uid, v in manifest['sources'].items():
    nodes[uid] = dict(name=src_label.get(v['name'], v['name']), layer='raw', kind='source')
for uid, v in manifest['nodes'].items():
    if v['resource_type'] == 'model':
        layer = 'gold' if v['schema'].endswith('gold') else 'staging'
        nodes[uid] = dict(name=v['name'], layer=layer, kind='incremental model')
    elif v['resource_type'] == 'snapshot':
        nodes[uid] = dict(name=v['name'], layer='snapshot', kind='SCD Type 2 snapshot')

edges = []
for uid, v in manifest['nodes'].items():
    if v['resource_type'] in ('model', 'snapshot'):
        for dep in v['depends_on']['nodes']:
            if dep in nodes:
                edges.append((dep, uid))

# ---- posisi (x, y) dan tinggi kotak ----
X_RAW, X_STG, X_GOLD = 0.0, 4.6, 11.4
SCD_LINE_FRAC = 0.28   # garis ke snapshot keluar dari bagian bawah kotak stg_box_status
POS_BY_NAME = {
    'raw_api_transaction': (X_RAW, 5.4),
    'raw_api_box': (X_RAW, 3.2),
    'raw_api_vp': (X_RAW, 1.8),
    'raw_api_pickup': (X_RAW, 0.0),
    'stg_transaction': (X_STG, 6.0),
    'stg_user': (X_STG, 4.8),
    'stg_box_status': (X_STG, 3.2),
    'stg_vp': (X_STG, 1.8),
    'stg_pickup': (X_STG, 0.0),
    'gold_layer': (X_GOLD, 4.45),
    'box_status_SCD': (X_GOLD, 3.2 + H * SCD_LINE_FRAC - H / 2),
}
HEIGHT = {'gold_layer': 1.45}
pos, hgt = {}, {}
for uid, n in nodes.items():
    if n['name'] not in POS_BY_NAME:
        raise SystemExit('posisi belum didefinisikan untuk ' + n['name'])
    pos[uid] = POS_BY_NAME[n['name']]
    hgt[uid] = HEIGHT.get(n['name'], H)
by_name = {n['name']: uid for uid, n in nodes.items()}

fig, ax = plt.subplots(figsize=(16, 8.4), facecolor='white')
ax.set_xlim(-1.0, 15.6)
ax.set_ylim(-1.4, 7.8)
ax.axis('off')

for x, t in [(X_RAW, 'RAW (BigQuery)'), (X_STG, 'STAGING (dbt incremental)'), (X_GOLD, 'GOLD / SNAPSHOT')]:
    ax.text(x + W / 2, 7.35, t, ha='center', va='center', fontsize=12, fontweight='bold', color=INK)
    ax.plot([x - 0.1, x + W + 0.1], [7.1, 7.1], color=INK, lw=1.4)


def arrow_head(x2, y2, color=MUTED, lw=1.3):
    ax.add_patch(FancyArrowPatch((x2 - 0.3, y2), (x2, y2), arrowstyle='-|>', mutation_scale=13,
                                 color=color, lw=lw, zorder=2, shrinkA=0, shrinkB=0))


def elbow(x1, y1, x2, y2, xm, color=MUTED, lw=1.3):
    """Garis siku: keluar horizontal, belok vertikal di xm, masuk horizontal ke tujuan."""
    ax.plot([x1, xm, xm, x2 - 0.3], [y1, y1, y2, y2], color=color, lw=lw, solid_capstyle='round', zorder=1)
    arrow_head(x2, y2, color, lw)


def straight_with_gaps(x1, y, x2, gaps, color=MUTED, lw=1.3, half=0.12):
    """Garis lurus dengan celah kecil di titik persilangan (line hop)."""
    xs = [x1]
    for g in sorted(gaps):
        xs += [g - half, g + half]
    xs.append(x2 - 0.3)
    for i in range(0, len(xs) - 1, 2):
        ax.plot([xs[i], xs[i + 1]], [y, y], color=color, lw=lw, solid_capstyle='round', zorder=1)
    arrow_head(x2, y, color, lw)


GOLD_SRC = ['stg_transaction', 'stg_user', 'stg_box_status', 'stg_vp']
LANE0, LANE_STEP = 0.45, 0.4
lane_x = {nm: X_STG + W + LANE0 + LANE_STEP * i for i, nm in enumerate(GOLD_SRC)}
gold_uid = by_name['gold_layer']

# rencana garis ke gold: (y awal, y akhir, x jalur vertikal)
gold_plan = {}
for i, nm in enumerate(GOLD_SRC):
    ys = pos[by_name[nm]][1] + H / 2
    if nm == 'stg_box_status':
        ys = pos[by_name[nm]][1] + H * 0.74   # bagian atas kotak, terpisah dari garis ke snapshot
    ye = pos[gold_uid][1] + hgt[gold_uid] * (0.88 - 0.76 * i / (len(GOLD_SRC) - 1))
    gold_plan[nm] = (ys, ye, lane_x[nm])

for a, b in edges:
    na, nb = nodes[a]['name'], nodes[b]['name']
    (x1, y1), (x2, y2) = pos[a], pos[b]
    if nb == 'gold_layer' and na in gold_plan:
        ys, ye, xm = gold_plan[na]
        elbow(x1 + W, ys, x2, ye, xm)
    elif nb == 'box_status_SCD':
        y = y1 + H * SCD_LINE_FRAC
        gaps = [xm for nm, (ys, ye, xm) in gold_plan.items() if min(ys, ye) < y < max(ys, ye)]
        straight_with_gaps(x1 + W, y, x2, gaps)
    elif na == 'raw_api_transaction':
        k = [nodes[e[1]]['name'] for e in edges if e[0] == a].index(nb)
        elbow(x1 + W, y1 + H * (0.3 + 0.4 * k), x2, y2 + hgt[b] / 2, x1 + W + (x2 - x1 - W) / 2)
    else:
        elbow(x1 + W, y1 + H / 2, x2, y2 + hgt[b] / 2, x1 + W + (x2 - x1 - W) / 2)

style = {
    'source': (PANEL, LINE, INK),
    'incremental model': ('white', INK, INK),
    'SCD Type 2 snapshot': ('white', INK, INK),
}
for uid, n in nodes.items():
    x, y = pos[uid]
    h = hgt[uid]
    face, edge, txt = style[n['kind']]
    lw = 2.2 if n['layer'] in ('gold', 'snapshot') else 1.4
    ax.add_patch(FancyBboxPatch((x, y), W, h, boxstyle='round,pad=0.02,rounding_size=0.12',
                                facecolor=face, edgecolor=edge, linewidth=lw, zorder=3))
    ty = y + h / 2 + 0.17 if h > H else y + h * 0.64
    sy = y + h / 2 - 0.17 if h > H else y + h * 0.27
    ax.text(x + 0.18, ty, n['name'], fontsize=11.5, fontweight='bold', color=txt, va='center', zorder=4)
    sub = n['kind']
    t = tests_per.get(uid)
    if t:
        sub += '  \u2022  %d tests' % t
    ax.text(x + 0.18, sy, sub, fontsize=8.8, color=MUTED, va='center', zorder=4)

px, py = pos[by_name['stg_pickup']]
ax.text(px + 0.05, py - 0.3, 'standalone (not used in the gold layer yet)', fontsize=9, color=MUTED,
        style='italic', va='center')

n_src = sum(1 for n in nodes.values() if n['kind'] == 'source')
n_mod = sum(1 for n in nodes.values() if n['kind'] == 'incremental model')
n_snap = sum(1 for n in nodes.values() if n['kind'] == 'SCD Type 2 snapshot')
n_tests = sum(1 for v in manifest['nodes'].values() if v['resource_type'] == 'test')
ax.text(-0.9, -1.15,
        'dbt lineage  \u2022  %d sources  \u2022  %d models  \u2022  %d snapshot (SCD Type 2)  \u2022  %d data tests'
        % (n_src, n_mod, n_snap, n_tests), fontsize=10.5, color=MUTED, ha='left')
ax.text(15.5, -1.15, 'Generated from dbt manifest.json', fontsize=9, color=MUTED, ha='right')

fig.savefig(out, dpi=140, bbox_inches='tight', facecolor='white', pad_inches=0.3)
print('OK', out, len(nodes), 'node,', len(edges), 'edge,', n_tests, 'tes')

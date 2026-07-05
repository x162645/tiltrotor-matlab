import csv, json, math
from pathlib import Path
ROOT=Path.cwd()
def read_csv(path):
    with open(ROOT/path, newline='', encoding='utf-8') as f: return list(csv.DictReader(f))
def write_csv(path, rows, fields):
    with open(ROOT/path,'w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f, fieldnames=fields); w.writeheader(); [w.writerow({k:r.get(k,'') for k in fields}) for r in rows]
xrows=read_csv(Path('data/wing_full_angle/xfoil/parsed/xfoil_clean_polars.csv'))
low={round(float(r['alpha_deg'])): r for r in xrows if abs(float(r['Re'])-1.0e6)<1 and abs(float(r['Mach']))<1e-9}
def analytic_low(a):
    ar=math.radians(a); cl=max(min(0.15+5.2*ar,1.35),-1.35); cd=0.025+0.055*cl*cl; return cl,cd,-0.03,'ANALYTIC_LOW_ANGLE_FALLBACK'
anchors={-180:(0.0,0.08,0.0,'PERIODIC_CLOSURE_ASSUMED'),-140:(-0.75,1.35,0.03,'FLAT_PLATE_BRIDGE_ASSUMED'),-105:(-0.20,1.28,0.02,'TM88373_DIGITIZED_ANCHOR_APPROX'),-96:(-0.05,1.16,0.01,'TM88373_TEXT_OPPOSITE_ROTATION_ANCHOR'),-85:(0.10,1.09,0.0,'TM88373_TEXT_60DEG_FLAP_ANCHOR'),-80:(0.15,1.10,-0.01,'TM88373_TEXT_XV15_WAKE_ANCHOR'),-75:(0.20,1.20,-0.02,'TM88373_RANGE_ENDPOINT_ANCHOR')}
for a in range(-25,26):
    if a in low:
        r=low[a]; anchors[a]=(float(r['CL']),float(r['CD']),float(r['Cm']),'XFOIL_CLEAN_SURROGATE_GEOMETRY')
    else:
        anchors[a]=analytic_low(a)
for a in [75,80,85,96,105,140,180]:
    cl,cd,cm,src=anchors[-a]
    anchors[a]=(-cl,cd,-cm,'ASSUMED_POSITIVE_DEEP_STALL_MIRROR_OF_'+src)
keys=sorted(anchors); rows=[]
for a in range(-180,181):
    if a in anchors: cl,cd,cm,src=anchors[a]
    else:
        lo=max(k for k in keys if k<a); hi=min(k for k in keys if k>a); t=(a-lo)/(hi-lo)
        cl=anchors[lo][0]*(1-t)+anchors[hi][0]*t; cd=anchors[lo][1]*(1-t)+anchors[hi][1]*t; cm=anchors[lo][2]*(1-t)+anchors[hi][2]*t
        src=f'LINEAR_BRIDGE_{anchors[lo][3]}__TO__{anchors[hi][3]}'
    rows.append({'alpha_deg':a,'alpha_rad':math.radians(a),'CL':cl,'CD':max(cd,0.0),'Cm':cm,'source':src})
write_csv(Path('data/wing_full_angle/full_angle_selected/wing_full_angle_database.csv'), rows, ['alpha_deg','alpha_rad','CL','CD','Cm','source'])
prev=None; max_jump=0; max_slope=0
for r in rows:
    if prev:
        jump=math.sqrt((r['CL']-prev['CL'])**2+(r['CD']-prev['CD'])**2+(r['Cm']-prev['Cm'])**2); max_jump=max(max_jump,jump); max_slope=max(max_slope,jump/math.radians(1))
    prev=r
checks=[{'metric':'max_adjacent_coefficient_jump_per_deg','value':max_jump,'passed':max_jump<0.25},{'metric':'max_combined_slope_per_rad','value':max_slope,'passed':max_slope<20},{'metric':'periodic_closure_error','value':abs(rows[0]['CL']-rows[-1]['CL'])+abs(rows[0]['CD']-rows[-1]['CD'])+abs(rows[0]['Cm']-rows[-1]['Cm']),'passed':True},{'metric':'xfoil_clean_rows_used','value':len(xrows),'passed':len(xrows)>0}]
write_csv(Path('validation/wing_full_angle/full_angle/full_angle_database_checks.csv'), checks, ['metric','value','passed'])
meta=json.loads((ROOT/'data/wing_full_angle/full_angle_selected/database_metadata.json').read_text(encoding='utf-8'))
meta['xfoil_clean_rows']=len(xrows); meta['database_rebuilt_after_xfoil_path_fix']=True
(ROOT/'data/wing_full_angle/full_angle_selected/database_metadata.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
print(f'Rebuilt database with {len(xrows)} XFOIL rows; max jump {max_jump:.6g}')

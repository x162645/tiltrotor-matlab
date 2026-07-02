import csv, hashlib, math, subprocess, shutil
from pathlib import Path
ROOT=Path.cwd(); XFOIL=Path(r"E:\tiltrotor\tools\external\xfoil\xfoil.exe")
airfoil=ROOT/"data/wing_full_angle/airfoils/naca64a223_surrogate.dat"
rows=[]; manifest=[]
def write_csv(path, rows, fields):
    with open(ROOT/path, "w", newline="", encoding="utf-8") as f:
        w=csv.DictWriter(f, fieldnames=fields); w.writeheader(); [w.writerow({k:r.get(k,"") for k in fields}) for r in rows]
for Re in [0.6e6,1.0e6,1.4e6]:
  for Mach in [0.0,0.10]:
    run_dir=ROOT/f"data/wing_full_angle/xfoil/raw/Re{int(Re):07d}_M{Mach:.2f}_clean"
    run_dir.mkdir(parents=True, exist_ok=True)
    local=run_dir/"airfoil.dat"; shutil.copyfile(airfoil, local)
    polar=run_dir/"polar.txt"; inp=run_dir/"xfoil.inp"; log=run_dir/"xfoil.log"
    if polar.exists(): polar.unlink()
    cmds=["LOAD airfoil.dat","PANE","OPER",f"VISC {Re:.0f}",f"MACH {Mach:.3f}","ITER 220","PACC","polar.txt","","ASEQ -25 25 1","PACC","","QUIT"]
    inp.write_text("\n".join(cmds)+"\n", encoding="ascii")
    status="NOT_RUN"; err=""; accepted=0
    try:
      with open(inp,"rb") as fin, open(log,"wb") as fout:
        p=subprocess.run([str(XFOIL)], stdin=fin, stdout=fout, stderr=subprocess.STDOUT, cwd=str(run_dir), timeout=120)
      status="RAN" if p.returncode==0 else f"EXIT_{p.returncode}"
    except subprocess.TimeoutExpired:
      status="TIMEOUT"; err="timeout 120 s"
    if polar.exists():
      for line in polar.read_text(errors="ignore").splitlines():
        parts=line.split()
        if len(parts)>=5:
          try:
            a,cl,cd,cdp,cm=[float(parts[i]) for i in range(5)]
          except ValueError:
            continue
          rows.append({"Re":Re,"Mach":Mach,"flap_deg":0,"alpha_deg":a,"CL":cl,"CD":cd,"Cm":cm,"source":"XFOIL_CLEAN_SURROGATE_GEOMETRY"}); accepted+=1
    manifest.append({"Re":Re,"Mach":Mach,"flap_deg":0,"status":status,"accepted_points":accepted,"input":str(inp.relative_to(ROOT)),"polar":str(polar.relative_to(ROOT)),"log":str(log.relative_to(ROOT)),"error":err})
for flap in [20,40,50,60]:
  manifest.append({"Re":"0.6e6-1.4e6","Mach":"0/0.10","flap_deg":flap,"status":"NOT_ATTEMPTED_GEOMETRY_ROUTE_UNVERIFIED","accepted_points":0,"input":"","polar":"","log":"","error":"XFOIL flap geometry modification for surrogate 64A223 not validated; not fabricated."})
write_csv(Path("data/wing_full_angle/xfoil/parsed/xfoil_clean_polars.csv"), rows, ["Re","Mach","flap_deg","alpha_deg","CL","CD","Cm","source"])
write_csv(Path("data/wing_full_angle/xfoil/xfoil_attempt_manifest.csv"), manifest, ["Re","Mach","flap_deg","status","accepted_points","input","polar","log","error"])
print(f"XFOIL rows: {len(rows)}")
for m in manifest[:6]: print(m)

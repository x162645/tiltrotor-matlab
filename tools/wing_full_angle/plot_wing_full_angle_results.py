from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
FIG = ROOT / "docs" / "wing_full_angle" / "figures"
FIG.mkdir(parents=True, exist_ok=True)

xfoil = pd.read_csv(ROOT / "data" / "wing_full_angle" / "xfoil" / "parsed" / "xfoil_clean_polars.csv")
db = pd.read_csv(ROOT / "data" / "wing_full_angle" / "full_angle_selected" / "wing_full_angle_database.csv")
legacy = pd.read_csv(ROOT / "validation" / "wing_full_angle" / "zero_nacelle_bump" / "legacy_zero_nacelle_7_12_step025.csv")
full = pd.read_csv(ROOT / "validation" / "wing_full_angle" / "zero_nacelle_bump" / "full_angle_zero_nacelle_7_12_step025.csv")

plt.figure(figsize=(8, 5))
for (re, mach), g in xfoil.groupby(["Re", "Mach"]):
    label = f"Re={re/1e6:.1f}e6 M={mach:.2f}"
    plt.plot(g["alpha_deg"], g["CL"], label=label)
plt.xlabel("alpha [deg]")
plt.ylabel("CL")
plt.title("Clean-airfoil XFOIL CL grid")
plt.grid(True, alpha=0.3)
plt.legend(fontsize=8)
plt.tight_layout()
plt.savefig(FIG / "xfoil_clean_cl_grid.png", dpi=160)
plt.close()

plt.figure(figsize=(8, 5))
nom = db
for coeff in ["CL", "CD", "Cm"]:
    plt.plot(nom["alpha_deg"], nom[coeff], label=coeff)
plt.xlabel("alpha [deg]")
plt.ylabel("coefficient")
plt.title("Full-angle coefficient database")
plt.grid(True, alpha=0.3)
plt.legend()
plt.tight_layout()
plt.savefig(FIG / "full_angle_database_nominal.png", dpi=160)
plt.close()

plt.figure(figsize=(8, 5))
plt.plot(legacy["V"], legacy["thetaDeg"], "o-", label="legacy theta")
plt.plot(full["V"], full["thetaDeg"], "o-", label="full-angle theta")
plt.xlabel("V [m/s]")
plt.ylabel("trim theta [deg]")
plt.title("0-deg nacelle trim comparison")
plt.grid(True, alpha=0.3)
plt.legend()
plt.tight_layout()
plt.savefig(FIG / "zero_nacelle_theta_comparison.png", dpi=160)
plt.close()

plt.figure(figsize=(8, 5))
plt.plot(legacy["V"], legacy["branchWeight"], "o-", label="legacy branchWeight")
plt.plot(full["V"], full["branchWeight"], "o-", label="full-angle branchWeight")
plt.xlabel("V [m/s]")
plt.ylabel("diagnostic branch weight")
plt.title("Legacy blend weight removed from full-angle model")
plt.grid(True, alpha=0.3)
plt.legend()
plt.tight_layout()
plt.savefig(FIG / "branch_weight_removed.png", dpi=160)
plt.close()

print("figures written to", FIG)

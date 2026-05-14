import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = r"c:\Users\danie\Documents\TCC-getDP"
POWER_BASE = os.path.join(ROOT, "tape", "res", "test", "power.txt")
POWER_NEU = os.path.join(ROOT, "tape", "res", "test", "power_neumann.txt")
TLINE_BASE = os.path.join(ROOT, "hts-ta", "res", "tLine.txt")
TLINE_NEU = os.path.join(ROOT, "hts-ta-neumann", "res", "tLine.txt")

# Novos caminhos para as correntes
CURRENT1 = os.path.join(ROOT, "tape", "res", "test", "current1.txt")
CURRENT2 = os.path.join(ROOT, "tape", "res", "test", "current2.txt")
CURRENT3 = os.path.join(ROOT, "tape", "res", "test", "current3.txt")

OUT_DIR = os.path.join(ROOT, "tape", "res", "test")


def read_power(path: str):
    time_values, dissipation = [], []
    with open(path, "r", encoding="utf-8", errors="ignore") as file:
        for line in file:
            cols = line.strip().split()
            if len(cols) >= 6:
                time_values.append(float(cols[0]))
                dissipation.append(float(cols[4]) + float(cols[5]))
    return time_values, dissipation


def read_tline(path: str):
    line_coord, t_values = [], []
    with open(path, "r", encoding="utf-8", errors="ignore") as file:
        for line in file:
            cols = line.strip().split()
            if len(cols) >= 3:
                line_coord.append(float(cols[1]))
                t_values.append(float(cols[2]))
    return line_coord, t_values


# Nova função para ler os arquivos de corrente
def read_current(path: str):
    time_values, current_values = [], []
    if not os.path.exists(path):
        return time_values, current_values

    with open(path, "r", encoding="utf-8", errors="ignore") as file:
        for line in file:
            # Ignora os cabeçalhos gerados pelo GetDP
            if line.startswith("#"):
                continue
            cols = line.strip().split()
            if len(cols) >= 2:
                time_values.append(float(cols[0]))
                current_values.append(float(cols[1]))
    return time_values, current_values


def plot_power_comparison():
    if not (os.path.exists(POWER_BASE) and os.path.exists(POWER_NEU)):
        print("Missing power input files.")
        return None

    time_base, diss_base = read_power(POWER_BASE)
    time_neu, diss_neu = read_power(POWER_NEU)
    sample_count = min(len(time_base), len(time_neu), len(diss_base), len(diss_neu))

    plt.figure(figsize=(9, 5))
    plt.plot(time_base[:sample_count], diss_base[:sample_count], label="Baseline", linewidth=1.8)
    plt.plot(time_neu[:sample_count], diss_neu[:sample_count], label="Neumann", linewidth=1.8, alpha=0.9)
    plt.xlabel("Time [s]")
    plt.ylabel("Dissipation (col5 + col6)")
    plt.title("Power comparison")
    plt.grid(True, alpha=0.25)
    plt.legend()
    plt.tight_layout()

    output_path = os.path.join(OUT_DIR, "power_comparison.png")
    plt.savefig(output_path, dpi=170)
    plt.close()
    return output_path


def plot_tline_comparison():
    if not (os.path.exists(TLINE_BASE) and os.path.exists(TLINE_NEU)):
        print("Missing tLine input files.")
        return None

    coord_base, values_base = read_tline(TLINE_BASE)
    coord_neu, values_neu = read_tline(TLINE_NEU)
    sample_count = min(len(coord_base), len(coord_neu), len(values_base), len(values_neu), 2000)

    plt.figure(figsize=(9, 5))
    plt.plot(coord_base[:sample_count], values_base[:sample_count], label="Baseline", linewidth=1.2)
    plt.plot(coord_neu[:sample_count], values_neu[:sample_count], label="Neumann", linewidth=1.2, alpha=0.9)
    plt.xlabel("Line coordinate (col2)")
    plt.ylabel("t value (col3)")
    plt.title("tLine comparison (sample window)")
    plt.grid(True, alpha=0.25)
    plt.legend()
    plt.tight_layout()

    output_path = os.path.join(OUT_DIR, "tline_comparison.png")
    plt.savefig(output_path, dpi=170)
    plt.close()
    return output_path


# Nova função para plotar as 3 correntes juntas
def plot_current_sharing():
    t1, i1 = read_current(CURRENT1)
    t2, i2 = read_current(CURRENT2)
    t3, i3 = read_current(CURRENT3)

    if not t1 and not t2 and not t3:
        print("Nenhum arquivo de corrente encontrado.")
        return None

    plt.figure(figsize=(9, 5))
    
    # Plota as linhas apenas se houver dados disponíveis
    if t1: plt.plot(t1, i1, label="I1 (Fita Topo)", linewidth=1.8, color="blue")
    if t2: plt.plot(t2, i2, label="I2 (Fita Meio)", linewidth=1.8, color="red")
    if t3: plt.plot(t3, i3, label="I3 (Fita Base)", linewidth=1.8, color="green", linestyle="--")

    plt.xlabel("Tempo [s]")
    plt.ylabel("Corrente [A]")
    plt.title("Current Sharing - Efeito de Blindagem no Stack")
    plt.grid(True, alpha=0.25)
    plt.legend()
    plt.tight_layout()

    output_path = os.path.join(OUT_DIR, "current_sharing.png")
    plt.savefig(output_path, dpi=170)
    plt.close()
    return output_path


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    p1 = plot_power_comparison()
    p2 = plot_tline_comparison()
    p3 = plot_current_sharing()

    if p1:
        print(f"WROTE: {p1}")
    if p2:
        print(f"WROTE: {p2}")
    if p3:
        print(f"WROTE: {p3}")


if __name__ == "__main__":
    main()
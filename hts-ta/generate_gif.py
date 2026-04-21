#!/usr/bin/env python3
"""
Gera um GIF animado a partir dos frames PNG exportados pelo Gmsh de res/b.pos.

Uso:
  python3 generate_gif.py --pos res/b.pos --out res/b.gif --fps 20
"""

from __future__ import annotations

import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile


def parse_args() -> argparse.Namespace:
    def positive_int(value: str) -> int:
        parsed = int(value)
        if parsed <= 0:
            raise argparse.ArgumentTypeError("fps deve ser maior que zero")
        return parsed

    parser = argparse.ArgumentParser(description="Gera GIF temporal da simulação")
    parser.add_argument("--pos", default="res/b.pos", help="Arquivo .pos de entrada")
    parser.add_argument("--out", default="res/b.gif", help="GIF de saída")
    parser.add_argument("--fps", type=positive_int, default=20, help="Frames por segundo")
    return parser.parse_args()


def require_command(cmd: str) -> None:
    if shutil.which(cmd) is None:
        raise RuntimeError(
            f"Comando '{cmd}' não encontrado. Instale o {cmd} para exportar os frames."
        )


def export_frames_with_gmsh(pos_file: str, frame_dir: str) -> None:
    require_command("gmsh")

    abs_pos = os.path.abspath(pos_file)
    if not os.path.isfile(abs_pos):
        raise FileNotFoundError(f"Arquivo não encontrado: {abs_pos}")

    geo_script = os.path.join(frame_dir, "export_frames.geo")
    with open(geo_script, "w", encoding="utf-8") as f:
        f.write(f'Merge "{abs_pos}";\n')
        f.write("General.Terminal = 1;\n")
        f.write("General.Trackball = 0;\n")
        f.write("n = View[0].NbTimeStep;\n")
        f.write("If (n < 1)\n")
        f.write("  n = 1;\n")
        f.write("EndIf\n")
        f.write("For step In {0:n-1}\n")
        f.write("  View[0].TimeStep = step;\n")
        f.write("  Draw;\n")
        f.write(
            f'  Print Sprintf("{os.path.abspath(frame_dir)}/frame_%05g.png", step);\n'
        )
        f.write("EndFor\n")
        f.write("Exit;\n")

    cmd = ["gmsh", "-nopopup", geo_script]
    subprocess.run(cmd, check=True)

    exported = glob.glob(os.path.join(frame_dir, "frame_*.png"))
    if not exported:
        raise RuntimeError("Não foi possível exportar frames PNG com o Gmsh.")


def build_gif_with_pillow(frame_dir: str, out_file: str, fps: int) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise RuntimeError(
            "Biblioteca Pillow não encontrada. Instale com: python3 -m pip install pillow"
        ) from exc

    frame_paths = sorted(glob.glob(os.path.join(frame_dir, "frame_*.png")))
    if not frame_paths:
        raise RuntimeError("Nenhum frame PNG encontrado para montar o GIF.")

    images = []
    for path in frame_paths:
        with Image.open(path) as img:
            images.append(img.copy())

    duration_ms = max(1, round(1000 / fps))
    os.makedirs(os.path.dirname(os.path.abspath(out_file)), exist_ok=True)
    images[0].save(
        out_file,
        save_all=True,
        append_images=images[1:],
        duration=duration_ms,
        loop=0,
    )


def main() -> int:
    args = parse_args()
    with tempfile.TemporaryDirectory(prefix="hts_ta_gif_") as temp_dir:
        export_frames_with_gmsh(args.pos, temp_dir)
        build_gif_with_pillow(temp_dir, os.path.abspath(args.out), args.fps)
    print(f"GIF gerado em: {os.path.abspath(args.out)}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"Erro: {exc}", file=sys.stderr)
        sys.exit(1)

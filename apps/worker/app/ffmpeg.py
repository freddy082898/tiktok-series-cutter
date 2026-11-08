import shutil
import subprocess


def ffmpeg_version() -> str | None:
    """Renvoie la version de FFmpeg installée, ou None si absent."""
    path = shutil.which("ffmpeg")
    if path is None:
        return None
    out = subprocess.run([path, "-version"], capture_output=True, text=True, timeout=10)
    first = out.stdout.splitlines()[0] if out.stdout else ""
    parts = first.split()
    return parts[2] if len(parts) > 2 else first or None

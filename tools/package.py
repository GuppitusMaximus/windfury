"""Build an installable archive containing exactly the addon folder."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'dist'
out.mkdir(exist_ok=True)
archive = out / 'ShambaGamba-WindFury-Proc-1.0.2.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
    for path in sorted((root / 'Windfury').rglob('*')):
        if path.is_file():
            package.write(path, path.relative_to(root))
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert 'Windfury/Windfury.toc' in package.namelist()
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
( out / 'SHA256SUMS.txt').write_text(f'{checksum}  {archive.name}\n')
print(f'{archive.name}: {archive.stat().st_size:,} bytes; SHA-256 {checksum}')

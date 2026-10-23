"""Validate and render the project presentation and its speech document."""
from pathlib import Path
import json
import posixpath
import re
import subprocess
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path("docs/presentation")
OUT = ROOT / "previews"
OUT.mkdir(exist_ok=True)
A = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
P = "{http://schemas.openxmlformats.org/presentationml/2006/main}"
REL = "{http://schemas.openxmlformats.org/package/2006/relationships}"
report = {"slides": 8, "speaker_notes": 8, "target_speech_seconds": 250}

def validate_package(path):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None, "ZIP checksum failed"
        names = set(z.namelist())
        for name in names:
            if name.endswith((".xml", ".rels")):
                root = ET.fromstring(z.read(name))
                if name.endswith(".rels"):
                    if name == "_rels/.rels":
                        base = ""
                    else:
                        base = name.rsplit("/_rels/", 1)[0]
                    for item in root:
                        if item.get("TargetMode") == "External":
                            continue
                        target = posixpath.normpath(posixpath.join(base, item.get("Target", "")))
                        assert target in names, f"Missing relationship target: {target}"
        return len(names)

report["pptx_parts"] = validate_package(ROOT / "Treadlight-presentation.pptx")
report["docx_parts"] = validate_package(ROOT / "Treadlight-speech.docx")
with zipfile.ZipFile(ROOT / "Treadlight-presentation.pptx") as z:
    slides = sorted((n for n in z.namelist() if re.fullmatch(r"ppt/slides/slide\d+.xml", n)), key=lambda x:int(re.search(r"slide(\d+)",x).group(1)))
    notes = [n for n in z.namelist() if re.fullmatch(r"ppt/notesSlides/notesSlide\d+.xml", n)]
    assert len(slides) == len(notes) == 8
    text_by_slide = []
    for name in slides:
        root = ET.fromstring(z.read(name))
        text_by_slide.append([e.text or "" for e in root.iter(A+"t")])
        for xf in root.iter(A+"xfrm"):
            off, ext = xf.find(A+"off"), xf.find(A+"ext")
            if off is not None and ext is not None:
                x,y,cx,cy = (int(off.get("x")),int(off.get("y")),int(ext.get("cx")),int(ext.get("cy")))
                assert x >= 0 and y >= 0 and x+cx <= 12192001 and y+cy <= 6858001
    assert all("\ufffd" not in t for group in text_by_slide for t in group)
for name in ["Treadlight-presentation","Treadlight-speech"]:
    ext = "pptx" if name.endswith("presentation") else "docx"
    subprocess.run(["libreoffice","-env:UserInstallation=file:///tmp/treadlight-office-profile","--headless","--convert-to","pdf","--outdir",str(ROOT),str(ROOT/(name+"."+ext))],check=True,timeout=120)
    assert (ROOT/(name+".pdf")).stat().st_size > 1000
slide_pdf = ROOT / "Treadlight-presentation.pdf"
raw = subprocess.check_output(["pdftotext","-layout",str(slide_pdf),"-"]).decode("utf-8")
pages = raw.split("\f")
while pages and not pages[-1].strip():
    pages.pop()
assert len(pages) == 8, f"Unexpected PDF slide count {len(pages)}"
def norm(s):
    return "".join(s.split())
missing=[]
for i,expected in enumerate(text_by_slide):
    actual=norm(pages[i])
    for t in expected:
        if norm(t) and norm(t) not in actual:
            missing.append({"slide":i+1,"text":t})
report["missing_rendered_text"]=missing
assert not missing, f"Rendered text missing: {missing}"
subprocess.run(["pdftoppm","-scale-to","1280","-png",str(slide_pdf),str(OUT/"slide")],check=True,timeout=120)
subprocess.run(["pdftoppm","-scale-to","1000","-png",str(ROOT/"Treadlight-speech.pdf"),str(OUT/"speech")],check=True,timeout=120)
from PIL import Image, ImageOps
sheet = Image.new("RGB",(1280,1440),"#081720")
pngs=sorted(OUT.glob("slide-*.png"))
assert len(pngs)==8
for i,png in enumerate(pngs):
    im=Image.open(png).convert("RGB")
    im=ImageOps.contain(im,(640,360))
    sheet.paste(im,((i%2)*640,(i//2)*360))
sheet.save(OUT/"overview.jpg",quality=90)
report["speech_pdf_pages"]=len(list(OUT.glob("speech-*.png")))
report["status"]="passed"
(ROOT/"validation.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps(report,ensure_ascii=False,indent=2))

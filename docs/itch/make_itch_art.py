"""Gera a arte da página do itch.io e o ícone do jogo: emblema (olho na
fechadura), logo de osso com sangue escorrendo, banner 960x300, capa
630x500, fundo de papel de parede 512 e os ícones do Godot.
Fonte: Noto Serif Display Bold (licença OFL).
Uso: python3 docs/itch/make_itch_art.py (na raiz do repositório).
Precisa de docs/itch/fundo_menu.png (o menu sem a interface, 640x360)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs/itch/imagens")
FONT = "/usr/share/fonts/truetype/noto/NotoSerifDisplay-Bold.ttf"
SMALL = "/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf"
BG_MENU = os.path.join(ROOT, "docs/itch/fundo_menu.png")

BONE_TOP = (246, 236, 214)
BONE_MID = (196, 182, 156)
BONE_BOT = (92, 78, 66)
BLOOD = (150, 8, 14)
BLOOD_HI = (210, 30, 34)


def vgrad(size, stops):
    """Gradiente vertical: stops = [(posição 0..1, cor), ...]."""
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        k = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            a, ca = stops[i]
            b, cb = stops[i + 1]
            if a <= k <= b:
                t = (k - a) / max(1e-6, b - a)
                c = tuple(int(ca[j] + (cb[j] - ca[j]) * t) for j in range(3))
                d.line([(0, y), (w, y)], fill=c)
                break
    return img


def emblem(size=512):
    S = size
    C = S / 2
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Brilho de vela atrás do aro.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((C - S * 0.47, C - S * 0.47, C + S * 0.47, C + S * 0.47), fill=(170, 30, 20, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.05))
    img.alpha_composite(glow)
    # Aro de ferro, com rebites, e um aro fino de osso por dentro.
    d.ellipse((C - S * 0.44, C - S * 0.44, C + S * 0.44, C + S * 0.44), fill=(52, 48, 52, 255))
    d.ellipse((C - S * 0.42, C - S * 0.42, C + S * 0.42, C + S * 0.42), fill=(86, 80, 82, 255))
    d.ellipse((C - S * 0.36, C - S * 0.36, C + S * 0.36, C + S * 0.36), fill=(40, 36, 40, 255))
    d.ellipse((C - S * 0.345, C - S * 0.345, C + S * 0.345, C + S * 0.345), fill=BONE_MID + (255,))
    d.ellipse((C - S * 0.33, C - S * 0.33, C + S * 0.33, C + S * 0.33), fill=(14, 10, 14, 255))
    for i in range(12):
        a = math.tau * i / 12
        x = C + math.cos(a) * S * 0.39
        y = C + math.sin(a) * S * 0.39
        r = S * 0.018
        d.ellipse((x - r, y - r, x + r, y + r), fill=(150, 140, 136, 255))
        d.ellipse((x - r * 0.5, y - r * 0.7, x + r * 0.2, y - r * 0.1), fill=(210, 204, 198, 255))
    # Buraco de fechadura.
    kh = Image.new("L", (S, S), 0)
    kd = ImageDraw.Draw(kh)
    kr = S * 0.13
    ky = C - S * 0.07
    kd.ellipse((C - kr, ky - kr, C + kr, ky + kr), fill=255)
    kd.polygon([(C - kr * 0.55, ky + kr * 0.6), (C + kr * 0.55, ky + kr * 0.6), (C + kr * 0.95, C + S * 0.23), (C - kr * 0.95, C + S * 0.23)], fill=255)
    hole = Image.new("RGBA", (S, S), (6, 2, 4, 255))
    hd = ImageDraw.Draw(hole)
    # O olho que espia de dentro.
    ew, eh = kr * 1.55, kr * 0.85
    hd.ellipse((C - ew, ky - eh, C + ew, ky + eh), fill=(226, 214, 196, 255))
    for i in range(7):
        a = -0.9 + i * 0.3
        hd.line([(C + math.cos(a) * ew * 0.95, ky + math.sin(a) * eh * 0.6), (C + math.cos(a) * ew * 0.45, ky + math.sin(a) * eh * 0.25)], fill=(170, 40, 40, 255), width=max(1, S // 256))
    ir = kr * 0.55
    hd.ellipse((C - ir, ky - ir, C + ir, ky + ir), fill=(120, 14, 18, 255))
    hd.ellipse((C - ir * 0.45, ky - ir * 0.45, C + ir * 0.45, ky + ir * 0.45), fill=(4, 0, 0, 255))
    hd.ellipse((C - ir * 0.35, ky - ir * 0.55, C - ir * 0.05, ky - ir * 0.25), fill=(255, 250, 240, 255))
    img.paste(hole, (0, 0), kh)
    # Borda de latão escurecido na fechadura.
    edge = kh.filter(ImageFilter.MaxFilter(max(3, (S // 128) | 1)))
    ring = Image.new("RGBA", (S, S), (120, 92, 52, 255))
    em = Image.composite(Image.new("L", (S, S), 255), Image.new("L", (S, S), 0), edge)
    em = Image.eval(Image.composite(Image.new("L", (S, S), 0), em, kh), lambda v: v)
    img.paste(ring, (0, 0), em)
    # Lágrima de sangue escorrendo do pé da fechadura.
    d2 = ImageDraw.Draw(img)
    tx = C + S * 0.01
    ty = C + S * 0.23
    d2.rectangle((tx - S * 0.012, ty - S * 0.01, tx + S * 0.012, ty + S * 0.13), fill=BLOOD + (255,))
    d2.ellipse((tx - S * 0.026, ty + S * 0.11, tx + S * 0.026, ty + S * 0.17), fill=BLOOD + (255,))
    d2.ellipse((tx - S * 0.012, ty + S * 0.118, tx - S * 0.002, ty + S * 0.135), fill=BLOOD_HI + (255,))
    return img


def logo(text, size, spacing, drips=True, seed=7):
    """Letras de osso com sombra escura e sangue escorrendo de baixo."""
    font = ImageFont.truetype(FONT, size)
    widths = [font.getbbox(c)[2] - font.getbbox(c)[0] for c in text]
    total = sum(widths) + spacing * (len(text) - 1)
    H = int(size * 1.9)
    W = total + size
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    x = size // 2
    top = int(size * 0.12)
    for c, wdt in zip(text, widths):
        md.text((x - font.getbbox(c)[0], top - font.getbbox(c)[1] + int(size * 0.05)), c, font=font, fill=255)
        x += wdt + spacing
    bbox = mask.getbbox()
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # Sombra e contorno.
    shadow = mask.filter(ImageFilter.MaxFilter(max(3, (size // 14) | 1))).filter(ImageFilter.GaussianBlur(size / 30))
    out.paste((8, 2, 4, 255), (0, int(size * 0.04)), shadow)
    # Gradiente de osso, rachado por linhas finas.
    grad = vgrad((W, H), [(0, BONE_TOP), (bbox[1] / H, BONE_TOP), ((bbox[1] + bbox[3]) / 2 / H, BONE_MID), (bbox[3] / H, BONE_BOT), (1, BONE_BOT)])
    gd = ImageDraw.Draw(grad)
    rnd = random.Random(seed)
    for _ in range(int(W / 6)):
        x0 = rnd.randint(0, W)
        y0 = rnd.randint(bbox[1], bbox[3])
        gd.line([(x0, y0), (x0 + rnd.randint(-size // 8, size // 8), y0 + rnd.randint(2, size // 6))], fill=(70, 58, 50), width=1)
    out.paste(grad, (0, 0), mask)
    if drips:
        # Escorridos: começam na base de algumas letras.
        dd = ImageDraw.Draw(out)
        base = bbox[3] - int(size * 0.06)
        x = size // 2
        for i, (c, wdt) in enumerate(zip(text, widths)):
            if c != " " and rnd.random() < 0.7:
                for k in range(rnd.randint(1, 2)):
                    dx = x + rnd.randint(int(wdt * 0.2), int(wdt * 0.8))
                    ln = rnd.randint(int(size * 0.12), int(size * 0.55))
                    wd = max(2, int(size * rnd.uniform(0.03, 0.06)))
                    dd.rectangle((dx - wd // 2, base - size * 0.08, dx + wd // 2, base + ln), fill=BLOOD + (255,))
                    dd.ellipse((dx - wd, base + ln - wd, dx + wd, base + ln + wd * 1.2), fill=BLOOD + (255,))
                    dd.line([(dx - wd // 4, base), (dx - wd // 4, base + ln * 0.8)], fill=BLOOD_HI + (255,), width=max(1, wd // 4))
            x += wdt + spacing
        # Uma faixa de sangue por cima do pé das letras.
        band = Image.new("L", (W, H), 0)
        bd = ImageDraw.Draw(band)
        bd.rectangle((0, base - size * 0.1, W, base + 2), fill=255)
        band = Image.composite(band, Image.new("L", (W, H), 0), mask)
        out.paste(BLOOD + (255,), (0, 0), band)
    return out.crop(out.getbbox())


def subtitle(text, size, color=(190, 40, 40), spacing=6):
    font = ImageFont.truetype(SMALL, size)
    w = sum(font.getbbox(c)[2] - font.getbbox(c)[0] for c in text) + spacing * (len(text) - 1)
    img = Image.new("RGBA", (w + 4, int(size * 1.5)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = 0
    for c in text:
        d.text((x - font.getbbox(c)[0], 0), c, font=font, fill=color + (255,))
        x += font.getbbox(c)[2] - font.getbbox(c)[0] + spacing
    return img


def cover_crop(img, w, h, focus_x=0.5, focus_y=0.5):
    sw, sh = img.size
    scale = max(w / sw, h / sh)
    img = img.resize((int(sw * scale) + 1, int(sh * scale) + 1), Image.NEAREST)
    x = int((img.width - w) * focus_x)
    y = int((img.height - h) * focus_y)
    return img.crop((x, y, x + w, y + h))


def shade(img, top=0.4, bottom=0.8):
    w, h = img.size
    grad = Image.new("L", (1, h))
    for y in range(h):
        k = y / (h - 1)
        grad.putpixel((0, y), int(255 * min(1.0, top * (1 - k) ** 2 + bottom * k ** 3)))
    grad = grad.resize((w, h))
    return Image.composite(Image.new("RGB", (w, h), (6, 4, 6)), img, grad)


def make_banner(em, lg):
    bg = Image.open(BG_MENU).convert("RGB")
    img = shade(cover_crop(bg, 960, 300, 0.75, 0.25), 0.35, 0.7).convert("RGBA")
    veil = Image.new("RGBA", (960, 300), (0, 0, 0, 0))
    vd = ImageDraw.Draw(veil)
    for x in range(960):
        a = int(200 * max(0.0, 1 - x / 700))
        vd.line([(x, 0), (x, 300)], fill=(6, 3, 6, a))
    img.alpha_composite(veil)
    e = em.resize((190, 190), Image.LANCZOS)
    img.alpha_composite(e, (40, 50))
    l2 = lg.copy()
    l2.thumbnail((640, 150), Image.LANCZOS)
    img.alpha_composite(l2, (250, 64))
    sub = subtitle("A CASA MORVANT", 22)
    img.alpha_composite(sub, (250 + (l2.width - sub.width) // 2, 64 + l2.height + 12))
    img.convert("RGB").save(os.path.join(OUT, "banner_960x300.png"))


def make_cover(em, lg):
    bg = Image.open(BG_MENU).convert("RGB")
    img = shade(cover_crop(bg, 630, 500, 0.8, 0.4), 0.25, 0.85).convert("RGBA")
    e = em.resize((210, 210), Image.LANCZOS)
    img.alpha_composite(e, (315 - 105, 18))
    l2 = lg.copy()
    l2.thumbnail((560, 140), Image.LANCZOS)
    img.alpha_composite(l2, (315 - l2.width // 2, 240))
    sub = subtitle("A CASA MORVANT", 20)
    img.alpha_composite(sub, (315 - sub.width // 2, 240 + l2.height + 14))
    d = ImageDraw.Draw(img)
    d.line([(150, 446), (480, 446)], fill=(120, 20, 20), width=2)
    small = ImageFont.truetype(SMALL, 15)
    t = "Saguão · Quartos · Porões · Sótão · Teatro"
    w = d.textlength(t, font=small)
    d.text((315 - w / 2, 456), t, font=small, fill=(220, 208, 190))
    img.convert("RGB").save(os.path.join(OUT, "capa_630x500.png"))


def make_tile():
    """Papel de parede adamascado, quase preto, que se repete sem emenda."""
    S = 512
    img = Image.new("RGB", (S, S), (18, 12, 16))
    d = ImageDraw.Draw(img)
    ink = (30, 20, 26)
    hi = (38, 26, 32)

    def motif(cx, cy):
        for dx in (-S, 0, S):
            for dy in (-S, 0, S):
                x, y = cx + dx, cy + dy
                d.ellipse((x - 46, y - 70, x + 46, y + 70), outline=ink, width=4)
                d.ellipse((x - 24, y - 40, x + 24, y + 40), fill=ink)
                d.polygon([(x, y - 96), (x + 14, y - 70), (x, y - 58), (x - 14, y - 70)], fill=hi)
                d.polygon([(x, y + 96), (x + 14, y + 70), (x, y + 58), (x - 14, y + 70)], fill=hi)
                for s in (-1, 1):
                    d.arc((x + s * 40 - 30, y - 30, x + s * 40 + 30, y + 30), 0, 360, fill=ink, width=3)
                    d.ellipse((x + s * 62 - 6, y - 6, x + s * 62 + 6, y + 6), fill=hi)
    motif(128, 128)
    motif(384, 384)
    # Listras verticais finas, como no papel do saguão.
    for x in range(0, S, 64):
        d.line([(x, 0), (x, S)], fill=(24, 16, 20), width=1)
    img.save(os.path.join(OUT, "fundo_512.png"))


def make_icons(em):
    base = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    bd = ImageDraw.Draw(base)
    bd.rounded_rectangle((0, 0, 1023, 1023), radius=180, fill=(16, 10, 14, 255))
    base.alpha_composite(em.resize((960, 960), Image.LANCZOS), (32, 32))
    base.save(os.path.join(OUT, "icone_1024.png"))
    icons = os.path.join(ROOT, "game/icons")
    os.makedirs(icons, exist_ok=True)
    for s in (256, 128, 64, 32):
        base.resize((s, s), Image.LANCZOS).save(os.path.join(icons, "icon_%d.png" % s))
    base.resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, "game/icon.png"))
    base.resize((256, 256), Image.LANCZOS).save(os.path.join(icons, "icon.ico"), sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])


os.makedirs(OUT, exist_ok=True)
EM = emblem(1024)
EM.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "emblema_512.png"))
LG = logo("HOLLOWVEIL", 150, 8)
LG.save(os.path.join(OUT, "logo.png"))
make_banner(EM, LG)
make_cover(EM, LG)
make_tile()
make_icons(EM)
print("ok")

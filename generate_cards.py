import os
from PIL import Image, ImageDraw, ImageFont

# Card parameters
CARD_WIDTH, CARD_HEIGHT = 140, 190
SUITS = ["S", "H", "D", "C"]
RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
COLORS = {"S": (220,220,220), "C": (200,255,200), "H": (255,200,200), "D": (255,255,200)}
TEXT_COLORS = {"S": (0,0,0), "C": (0,80,0), "H": (255,0,0), "D": (255,0,0)}

os.makedirs("src/cards", exist_ok=True)

# Try to get a default font
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", 36)
except:
    font = ImageFont.load_default()

for suit in SUITS:
    for rank in RANKS:
        img = Image.new("RGB", (CARD_WIDTH, CARD_HEIGHT), COLORS[suit])
        d = ImageDraw.Draw(img)
        label = f"{rank}{suit}"
        # Use textbbox for Pillow >=8.0, fallback to getsize for older
        try:
            bbox = d.textbbox((0, 0), label, font=font)
            w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        except AttributeError:
            w, h = font.getsize(label)
        d.rectangle([0,0,CARD_WIDTH-1,CARD_HEIGHT-1], outline=(0,0,0), width=3)
        d.text(((CARD_WIDTH-w)//2, (CARD_HEIGHT-h)//2), label, fill=TEXT_COLORS[suit], font=font)
        img.save(f"src/cards/{label}.png")
print("Card images generated in src/cards/")

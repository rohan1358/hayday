from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import json,math,random
random.seed(8)
root=Path.cwd();art=root/'hayday/assets';out=root/'outputs/katalog-kawasan'
rows=json.loads((out/'inventaris-kawasan.json').read_text(encoding='utf-8'))
W,H=8500,7370
im=Image.new('RGB',(W,H),'#82ca38')
grass=Image.open(art/'colorful_garden/grass_meadow.png').convert('RGB');grass=grass.resize((950,950))
for y in range(0,H,950):
 for x in range(0,W,950):im.paste(grass,(x,y))
sky=Image.open(art/'cheerful/countryside.png').convert('RGBA');sky=sky.resize((W,650));im.paste(sky,(0,0),sky)
d=ImageDraw.Draw(im)
fontpath=art/'fonts/nunito/Nunito[wght].ttf';bold=art/'fonts/lilitaone/LilitaOne-Regular.ttf'
def ft(n,title=False):return ImageFont.truetype(str(bold if title else fontpath),n)
def label(x,y,s,n=42,ink='#ffffff',center=True):
 f=ft(n,True);box=d.textbbox((0,0),s,font=f);w=box[2]-box[0]
 d.text((x-w/2 if center else x,y),s,font=f,fill=ink,stroke_width=2,stroke_fill='#365427')
def paste(sprite,x,y,w,h):
 sprite=sprite.copy();sprite.thumbnail((int(w),int(h)),Image.Resampling.LANCZOS)
 im.paste(sprite,(int(x-sprite.width/2),int(y-sprite.height)),sprite)
def atlas(name):
 sheet=Image.open(art/'reference_atlases'/f'{name}.png').convert('RGBA')
 cols,rs=(5,4) if name=='crops' else ((6,4) if name in ['ranch','production'] else ((4,5) if name=='mine' else ((3,8) if name=='crop_stages' else (4,4))))
 sprites=[]
 for row in range(rs):
  for col in range(cols):
   a=sheet.crop((col*sheet.width//cols+3,row*sheet.height//rs+3,(col+1)*sheet.width//cols-3,(row+1)*sheet.height//rs-3))
   bbox=a.getbbox()
   if bbox:a=a.crop(bbox)
   sprites.append(a)
 return sprites
# One continuous world: avenues connect district centers, with no catalog panels.
centers=[]
for i,r in enumerate(rows):
 row=i//5;col=i%5
 centers.append((850+col*1480+ (100 if row%2 else 0),1110+row*1130))
def road(points,width=75):
 d.line(points,fill='#8b9c54',width=width+14,joint='curve')
 d.line(points,fill='#e0ca9b',width=width,joint='curve')
 for a,b in zip(points,points[1:]):
  length=math.dist(a,b);num=max(1,int(length/56))
  for j in range(num):
   t=j/num;x=a[0]+(b[0]-a[0])*t;y=a[1]+(b[1]-a[1])*t
   d.line((x-20,y-9,x+18,y+9),fill='#bca882',width=3)
for row in range(5):
 road([(270,1510+row*1130),(7520,1510+row*1130)],90)
for col in range(5):road([(1470+col*1480,700),(1470+col*1480,6510)],85)
# Natural river sits at the far right edge.
river=Image.open(art/'waterfall/river_waterfall.png').convert('RGBA')
paste(river,8000,6570,1570,3400)
# Landscape clusters: buildings at the rear, useful objects and produce in front.
counts={}
for i,(r,(cx,cy)) in enumerate(zip(rows,centers)):
 assets=[]
 for sh in r['sheets']:
  # Growth variants belong beside the field, harvested trees beside orchard.
  assets+=atlas(sh)
 counts[r['key']]=len(assets)
 n=len(assets);cols=6 if n>24 else 5;rs=math.ceil(n/cols)
 cellw=235;cellh=min(205,790/max(1,rs))
 left=cx-(cols-1)*cellw/2;top=cy-180
 # Planting beds and buildings remain on grass with paths between rows.
 for j,a in enumerate(assets):
  rr=j//cols;cc=j%cols
  x=left+cc*cellw+(18 if rr%2 else -12)
  y=top+rr*cellh
  # Items are grounded, not enclosed by cards or sprite-sheet borders.
  d.ellipse((x-67,y-15,x+67,y+14),fill='#70ae32')
  paste(a,x,y,218,cellh*1.15)
 # Signs state the real unlock level and purchased condition.
 sy=cy+710
 d.rectangle((cx-8,sy+55,cx+8,sy+103),fill='#80532c')
 d.rounded_rectangle((cx-345,sy-18,cx+345,sy+78),radius=22,fill='#87602e',outline='#ffefb2',width=5)
 label(cx,sy-7,r['name'],42)
 label(cx,sy+41,f"LEVEL {r['level']}  •  TERBUKA & DIBELI",25,'#ffec8f')
 # Flowered corners link the districts visually, using existing garden art.
 for dx in [-610,610]:
  flower=Image.open(art/'colorful_garden/flower_patch.png').convert('RGBA')
  paste(flower,cx+dx,cy+680,105,90)
# Shared decoration objects distributed along the perimeter avenue.
shared=[]
for sh in ['decoration','terrain','upgrades']:shared+=atlas(sh)
road([(200,6930),(8300,6930)],105)
for j,a in enumerate(shared):
 x=160+(j%32)*257;y=6760+(j//32)*350
 paste(a,x,y,210,230)
# HUD follows the reference; level 50 represents the fully purchased preview.
logo=Image.open(art/'cheerful/logo.png').convert('RGBA');paste(logo,610,360,1120,340)
for box in [(1210,55,2630,310),(2790,55,3860,310),(4000,55,5000,310),(5190,55,8290,310)]:
 d.rounded_rectangle(box,radius=75,fill='#fff4d1',outline='#c9a85b',width=9)
label(1910,83,'LEVEL 50',76,'#277542');label(1910,188,'SEMUA KAWASAN TERBUKA',36,'#38613d')
label(3325,94,'KOIN  999.999',62,'#8d621e');label(4500,94,'PERMATA  999',56,'#9c4fbc')
label(6740,90,'KEBUN LENGKAP • SEMUA ASET DIBELI',55,'#277542')
label(6740,183,'25 kawasan ditata sesuai level asli dalam game',40,'#48623c')
# Small explanatory banner, without changing the real save or economy.
d.rounded_rectangle((1700,440,6800,585),radius=40,fill='#fff4d1',outline='#bc9957',width=5)
label(4250,465,'PETA RENCANA KEBUN  •  ASET ASLI PROYEK  •  LEVEL 1–50',49,'#35633e')
label(4250,7260,'Rancangan tata letak penuh — seluruh gambar berasal dari aset game; level mengikuti world_regions.gd.',32,'#ffffff')
path=out/'CheerfulGarden-Peta-Kebun-Lengkap-Level50.png';im.save(path,optimize=True)
p=im.copy();p.thumbnail((2040,2040));p.save(out/'preview-peta-kebun.jpg',quality=92)
(out/'peta-kebun-manifest.json').write_text(json.dumps({'regions':rows,'illustrations_per_region':counts,'size':[W,H],'source':'existing project assets','preview_only':True},ensure_ascii=False,indent=2),encoding='utf-8')
print(path);print('Placed',sum(counts.values()),'regional sprites +',len(shared),'shared sprites')

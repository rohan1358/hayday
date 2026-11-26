from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import re,json,csv,textwrap
root=Path.cwd(); art=root/'hayday/assets'; out=root/'outputs/katalog-kawasan'
s=(root/'hayday/scripts/world_regions.gd').read_text(encoding='utf-8')
rows=[]
for line in s.split('const DATA := {',1)[1].split('const LATE_ACTIVITIES',1)[0].splitlines():
 m=re.search(r'"(\w+)": \{"name":"([^"]+)", "level":(\d+)',line)
 if not m: continue
 key,name,level=m.groups();desc=re.search(r'"description":"([^"]+)"',line);main=re.search(r'"art":"([^"]+)"',line)
 rows.append(dict(key=key,name=name,level=int(level),description=desc.group(1) if desc else '',main=main.group(1) if main else ''))
sheets={'desa':['village','people'],'ladang':['crops','crop_stages'],'hutan':['forest'],'peternakan':['ranch'],'produksi':['production'],'logistik':['logistics'],'kebun_buah':['orchard','orchard_harvested'],'penggilingan':['production'],'rumah_kaca':['greenhouse'],'taman_bermain':['playground'],'pasar_desa':['market'],'pemancingan':['fishing'],'tambang':['mine'],'festival':['festival','festival_extra'],'camping':['camping'],'permukiman':['village','people'],'kafe':['cafe'],'berkuda':['horse'],'stasiun':['train'],'sekolah':['school'],'botani':['greenhouse'],'resor_danau':['fishing'],'kota_wisata':['market'],'arena':['festival_extra'],'pelabuhan':['harbor']}
reuse={'sekolah':'Bangunan utama memakai rumah desa.','botani':'Bangunan utama memakai rumah kaca.','resor_danau':'Bangunan utama memakai aset pemancingan.','kota_wisata':'Bangunan utama memakai kios pasar.'}
base={'desa':'Rumah, tetangga, surat, dan papan pesanan.','ladang':'Tanaman, petak, serta tahap pertumbuhan.','hutan':'Pohon liar, kayu, dan perlengkapan hutan.','peternakan':'Kandang, hewan, hasil ternak, dan pakan.','produksi':'Dapur, pabrik, bahan, dan hasil olahan.','logistik':'Gudang, truk, peti, dan pengiriman.','kebun_buah':'12 pohon buah + tampilan sesudah dipetik.'}
rows.sort(key=lambda x:(x['level'],next(i for i,r in enumerate(re.findall(r'"(\w+)": \{"name"',s)) if r==x['key'])))
for r in rows:r['sheets']=sheets[r['key']];r['status']=reuse.get(r['key'],'Aset utama tersedia.');r['missing']=[n for n in r['sheets'] if not (art/'reference_atlases'/f'{n}.png').exists()]
# Existing authored sprites arranged into an overview; no generated replacements.
W=5100;CW=980;CH=1210;GAP=30;TOP=390
image=Image.new('RGB',(W,TOP+6*(CH+GAP)+160),'#e9efdf');d=ImageDraw.Draw(image)
fontfile=art/'fonts/nunito/Nunito[wght].ttf';titlefile=art/'fonts/lilitaone/LilitaOne-Regular.ttf'
def font(n,title=False):return ImageFont.truetype(str(titlefile if title else fontfile),n)
def text(x,y,value,n=28,fill='#36553d',title=False):d.text((x,y),value,font=font(n,title),fill=fill)
def wrap(value,width=53):return textwrap.wrap(value,width=width,break_long_words=False)
d.rounded_rectangle((30,25,W-30,TOP-25),radius=35,fill='#164c39')
text(70,50,'CHEERFUL GARDEN',85,'#fff1ba',True)
text(74,151,'KATALOG ASET PER KAWASAN  |  LEVEL 1–50',51,'#ffffff',True)
text(74,225,'25 kawasan sesuai data game • urutan berdasarkan level buka • aset asli dari proyek',33,'#daedcd')
text(74,278,'Hijau: tersedia   /   Kuning: aset utama masih memakai ulang   /   Merah: file belum tersedia',30,'#fff1ba')
text(74,325,'Gambar referensi bukan jaminan seluruh objek sudah aktif sebagai fitur permainan.',27,'#daedcd')
def paste_fit(path,box):
 im=Image.open(path).convert('RGBA');im.thumbnail((int(box[2]-box[0]),int(box[3]-box[1])),Image.Resampling.LANCZOS)
 image.paste(im,(int((box[0]+box[2]-im.width)/2),int((box[1]+box[3]-im.height)/2)),im)
for i,r in enumerate(rows):
 col=i%5;row=i//5;x=40+col*(CW+GAP);y=TOP+row*(CH+GAP)
 d.rounded_rectangle((x,y,x+CW,y+CH),radius=28,fill='#fff8e8',outline='#c4d1af',width=3)
 d.rounded_rectangle((x+15,y+15,x+CW-15,y+100),radius=20,fill='#28734e')
 text(x+35,y+33,f"{i+1:02d}  {r['name']}",37,'#ffffff',True)
 d.rounded_rectangle((x+CW-178,y+25,x+CW-26,y+89),radius=16,fill='#f9d77d')
 text(x+CW-157,y+39,f"LV {r['level']:02d}",33,'#543e25',True)
 for j,line in enumerate(wrap(base.get(r['key'],r['description']),58)[:2]):text(x+30,y+118+j*34,line,27)
 listed=r['sheets'];n=len(listed)
 if n==1:paste_fit(art/'reference_atlases'/f'{listed[0]}.png',(x+25,y+205,x+CW-25,y+1025))
 else:
  for j,sh in enumerate(listed):
   # Two complete sheets are placed side by side, keeping every sprite visible.
   left=x+25+j*(CW-50)/2
   paste_fit(art/'reference_atlases'/f'{sh}.png',(left,y+205,left+(CW-60)/2,y+1025))
   text(left+5,y+1026,sh.replace('_',' '),22,'#64785c')
 amber=r['key'] in reuse;color='#f8dfa0' if amber else '#dceecb'
 d.rounded_rectangle((x+20,y+1070,x+CW-20,y+CH-18),radius=17,fill=color)
 status=r['status'] if not r['missing'] else 'BELUM TERSEDIA: '+', '.join(r['missing'])
 for j,line in enumerate(wrap(status,57)):text(x+36,y+1084+j*30,line,25,'#6e511b' if amber else '#285a38')
 text(x+36,y+1152,'Utama khusus perlu dilengkapi' if amber else 'Ilustrasi ditemukan di proyek',24,'#6e511b' if amber else '#285a38')
# Fifth row already holds 21–25; sixth row holds shared assets outside districts.
shared=[('Dekorasi Kebun',['decoration']),('Jalan & Permukaan',['terrain']),('Upgrade Bangunan',['upgrades']),('Karakter & NPC',['people']),('Tanaman & Musim',[])]
for i,(name,files) in enumerate(shared):
 x=40+i*(CW+GAP);y=TOP+5*(CH+GAP)
 d.rounded_rectangle((x,y,x+CW,y+CH),radius=28,fill='#f8f2e7',outline='#d6c8ad',width=3)
 d.rounded_rectangle((x+15,y+15,x+CW-15,y+100),radius=20,fill='#846244');text(x+35,y+34,name,36,'#ffffff',True)
 text(x+30,y+126,'ASET BERSAMA • BUKAN KAWASAN BARU',26,'#846244')
 if files:paste_fit(art/'reference_atlases'/f'{files[0]}.png',(x+25,y+200,x+CW-25,y+1030))
 else:paste_fit(art/'crop_illustrations/plants.png',(x+25,y+200,x+CW-25,y+1030))
 for j,line in enumerate(wrap('Dipakai lintas kawasan. Level tiap item mengikuti katalog dan progres game.',53)):text(x+30,y+1085+j*34,line,26)
text(60,image.height-105,'Sumber: world_regions.gd, reference_assets.gd, dan gambar aset proyek.  •  Audit 16 November 2026',29)
image.save(out/'CheerfulGarden-Semua-Kawasan-Level-1-50.png',optimize=True)
preview=image.copy();preview.thumbnail((1530,2500));preview.save(out/'preview-kawasan.jpg',quality=88)
(out/'inventaris-kawasan.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
print('Regions:',len(rows),'Missing sheets:',sum(len(r['missing']) for r in rows),'Output:',image.size)

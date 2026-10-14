"""Export source sprite rectangles with their original padding and colors."""
from pathlib import Path
import json, hashlib, shutil
from PIL import Image
root=Path(__file__).resolve().parents[1];dest=root/'TreeSeaAssistant/Assets.xcassets'
(dest/'Contents.json').write_text(json.dumps({'info':{'version':1,'author':'xcode'}}))
def asset(name,image):
 folder=dest/(name+'.imageset');folder.mkdir(parents=True,exist_ok=True)
 image_path=folder/'image.png'
 unchanged=False
 if image_path.exists():
  with Image.open(image_path) as existing:unchanged=existing.size==image.size and existing.convert('RGBA').tobytes()==image.convert('RGBA').tobytes()
 if not unchanged:image.save(image_path)
 (folder/'Contents.json').write_text(json.dumps({'images':[{'idiom':'universal','filename':'image.png'}],'info':{'version':1,'author':'xcode'}}))
manifest=json.loads((root/'图标/manifest.json').read_text()); index={};hashes={}
for entry in manifest['assets']:
 sprite=entry.get('sprite')
 if not sprite: continue
 original=Image.open(root/'图标'/entry['file']).convert('RGBA')
 image=original.crop((sprite['x'],sprite['y'],sprite['x']+sprite['width'],sprite['y']+sprite['height']))
 canvas=Image.new('RGBA',(sprite['sourceWidth'],sprite['sourceHeight']))
 canvas.paste(image,(sprite['offsetX'],sprite['offsetY']))
 name='game-'+entry['assetKey'].replace('/','-').replace('.png','')
 asset(name,canvas);index[entry['assetKey']]=name
 hashes[name]=hashlib.sha256((dest/(name+'.imageset/image.png')).read_bytes()).hexdigest()
for name,path in [('cover-phone','backgrounds/blackstream-atlas-cover-v4.png'),('cover-pad','backgrounds/blackstream-atlas-cover-v4.png'),('botanical','backgrounds/blackstream-atlas-cover-v4.png'),('emblem','branding/wayfinder-icon-v2.png')]:
 image=Image.open(root/'自建素材'/path);image.thumbnail((1536,1536),Image.Resampling.LANCZOS);asset(name,image)
icon=Image.open(root/'自建素材/branding/wayfinder-icon-v2.png').convert('RGBA').resize((1024,1024),Image.Resampling.LANCZOS)
canvas=Image.new('RGB',(1024,1024),(6,10,8));canvas.paste(icon,mask=icon.getchannel('A'))
folder=dest/'AppIcon.appiconset';folder.mkdir(exist_ok=True);canvas.save(folder/'AppIcon.png')
(folder/'Contents.json').write_text(json.dumps({'images':[{'idiom':'universal','platform':'ios','size':'1024x1024','filename':'AppIcon.png'}],'info':{'version':1,'author':'xcode'}}))
(root/'TreeSeaAssistant/Resources/asset-index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2))
(root/'docs/acceptance/integrated-assets.json').write_text(json.dumps({'spriteCount':len(index),'transform':'source rectangle and padding; no recoloring','spritesSHA256':hashes},indent=2))
print('Exported',len(index),'source sprites, new cover and AppIcon; preparing five floor backgrounds and transparent traveler')

for floor in range(1,6):
 image=Image.open(root/f'图标/raw/themes/blackstream/backgrounds/area-{floor}.png');image.thumbnail((1536,1536),Image.Resampling.LANCZOS);asset(f'map-area-{floor}',image)
folder=dest/'start-traveler.imageset';folder.mkdir(exist_ok=True)
shutil.copyfile(root/'自建素材/branding/start-traveler-v2.svg',folder/'traveler.svg')
(folder/'Contents.json').write_text(json.dumps({'images':[{'idiom':'universal','filename':'traveler.svg'}],'info':{'version':1,'author':'xcode'},'properties':{'preserves-vector-representation':True}}))

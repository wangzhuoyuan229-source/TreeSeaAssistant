"""Export source sprite rectangles with their original padding and colors."""
from pathlib import Path
import json, hashlib
from PIL import Image
root=Path(__file__).resolve().parents[1];dest=root/'TreeSeaAssistant/Assets.xcassets'
(dest/'Contents.json').write_text(json.dumps({'info':{'version':1,'author':'xcode'}}))
def asset(name,image):
 folder=dest/(name+'.imageset');folder.mkdir(parents=True,exist_ok=True)
 image.save(folder/'image.png')
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
for name,path in [('cover-phone','backgrounds/iphone-animal-cover-v2.png'),('cover-pad','backgrounds/ipad-animal-botanical-cover-v3.png'),('botanical','backgrounds/ipad-ink-botanical-v1.png'),('emblem','branding/app-emblem-overlay-v1.png')]:
 image=Image.open(root/'自建素材'/path);image.thumbnail((1536,1536),Image.Resampling.LANCZOS);asset(name,image)
icon=Image.open(root/'自建素材/branding/app-icon-master-v1.png').convert('RGBA').resize((1024,1024),Image.Resampling.LANCZOS)
canvas=Image.new('RGB',(1024,1024),(6,10,8));canvas.paste(icon,mask=icon.getchannel('A'))
folder=dest/'AppIcon.appiconset';folder.mkdir(exist_ok=True);canvas.save(folder/'AppIcon.png')
(folder/'Contents.json').write_text(json.dumps({'images':[{'idiom':'universal','platform':'ios','size':'1024x1024','filename':'AppIcon.png'}],'info':{'version':1,'author':'xcode'}}))
(root/'TreeSeaAssistant/Resources/asset-index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2))
(root/'docs/acceptance/integrated-assets.json').write_text(json.dumps({'spriteCount':len(index),'transform':'source rectangle and padding; no recoloring','spritesSHA256':hashes},indent=2))
print('Exported',len(index),'source sprites, 4 downsampled backgrounds, and AppIcon')

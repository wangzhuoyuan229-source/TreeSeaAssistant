"""Validate project references and resources; this is not an Xcode build."""
from pathlib import Path
import subprocess,json,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
subprocess.run(['plutil','-lint',str(root/'TreeSeaAssistant.xcodeproj/project.pbxproj')],check=True)
raw=subprocess.check_output(['plutil','-convert','json','-o','-',str(root/'TreeSeaAssistant.xcodeproj/project.pbxproj')])
project=json.loads(raw);objects=project['objects']; targets=[o for o in objects.values() if o['isa']=='PBXNativeTarget']
assert len(targets)==3
for o in objects.values():
 if o['isa']=='PBXFileReference' and o.get('sourceTree')=='SOURCE_ROOT':assert (root/o['path']).exists(),o['path']
 if o['isa']=='PBXBuildFile':assert o.get('fileRef',o.get('productRef')) in objects
 if o['isa']=='PBXSourcesBuildPhase':
  for file in o['files']:assert file in objects
scheme=ET.parse(root/'TreeSeaAssistant.xcodeproj/xcshareddata/xcschemes/TreeSeaAssistant.xcscheme')
assert len(scheme.findall('.//TestableReference'))==2
index=json.loads((root/'TreeSeaAssistant/Resources/asset-index.json').read_text())
assert len(index)==71
for name in index.values():assert (root/'TreeSeaAssistant/Assets.xcassets'/(name+'.imageset/image.png')).exists()
swift=list((root/'TreeSeaAssistant').rglob('*.swift'))+list((root/'Tests').rglob('*.swift'))
subprocess.run(['swiftc','-frontend','-parse']+[str(p) for p in swift],check=True)
print('Validated 3 targets, 2 scheme test targets, source/resource references, 71 sprites and Swift syntax')

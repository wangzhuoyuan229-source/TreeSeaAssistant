"""Transcribe pinned research resources without promoting their review status."""
import json, re, hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / '.build-evidence/upstream'
OUT = ROOT / 'Packages/TreeSeaCore/Sources/TreeSeaCore/Resources'
MAA='59bd4cecf6420f963add79ee005f969a7f5d6131'
HLSH='b81965ba78918d8d6effb0e5006dc3c9b2e617c9'
names=['诡意行商','秘境行商','安全的角落','不期而遇','得偿所愿','失与得','先行一步','误入奇境','狭路相逢','应急助力','险路小径']
kinds=['strangeShop','secretShop','safeCorner','encounter','wish','lossGain','advance','wonderland','narrowEncounter','emergencyAid','dangerousPath']
def provenance(repo,commit,path):
 return {'sourceURL':f'https://github.com/{repo}/blob/{commit}/{path}','commit':commit,'status':'researchReference'}
def write(name,value): (OUT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
distance=json.loads((RAW/'hlsh-distance.json').read_text())
counts=json.loads((RAW/'hlsh-count.json').read_text())
rules=[]
for name,kind in zip(names,kinds):
 for floor,roman in enumerate(['I','II','III','IV','V'],1):
  d=distance[name][roman]; c=counts[name][roman]
  dr={'forbidden':{}} if d is None else {'unrestricted':{}} if d=='undetermined' else {'closedRange':{'min':d[0],'max':d[1]}}
  if c is None: cr={'range':{'min':0,'max':0}}
  elif isinstance(c,str):
   if '或' in c: cr={'discrete':{'_0':[int(x.strip()) for x in c.split('或')]}}
   else:
    parts=[int(x) for x in c.split('-')]; cr={'range':{'min':parts[0],'max':parts[-1]}}
  elif isinstance(c,int): cr={'range':{'min':c,'max':c}}
  elif isinstance(c,list): cr={'range':{'min':c[0],'max':c[-1]}}
  elif isinstance(c,dict) and 'min' in c: cr={'range':{'min':c['min'],'max':c['max']}}
  else: raise ValueError(c)
  rules.append({'kind':kind,'floor':floor,'distance':dr,'count':cr,'provenance':provenance('ega0123/hlsh-helper',HLSH,'data/rules/node_distance_rules.json')})
templates=[]
for t in json.loads((RAW/'maa-templates.json').read_text())['templates']:
 cols=t['columns']; start=t['start']; ends=t['terminals']
 points=sorted(set(tuple(p) for e in t['edges'] for p in e)|{tuple(start)}|{tuple(p) for p in ends})
 nodes=[]
 for row,col in points:
  kind='start' if [row,col]==start else 'exit' if [row,col] in ends else 'unknown'
  nodes.append({'id':row*cols+col,'row':row,'column':col,'observedKind':kind,'originalKind':kind,'progress':'unopened','traversability':'available','identityEvidence':'templateInferred','traversalEvidence':'unresolved','battleScope':'unconfirmed','rewardClaimed':False,'confirmedAPGain':0,'lookoutRevealCount':0})
 edges=[{'a':min(a[0]*cols+a[1],b[0]*cols+b[1]),'b':max(a[0]*cols+a[1],b[0]*cols+b[1]),'state':'inferred'} for a,b in t['edges']]
 m={'floor':t['floor'],'rows':t['rows'],'columns':cols,'nodes':nodes,'edges':edges,'initialStartID':start[0]*cols+start[1],'currentNodeID':start[0]*cols+start[1],'exitIDs':[p[0]*cols+p[1] for p in ends],'startEvidence':'templateInferred','originalCoverage':'partial','topologyVerified':False,'templateID':t['id'],'mapRevision':0}
 templates.append({'id':t['id'],'map':m,'provenance':provenance('MaaAssistantArknights/MaaAssistantArknights',MAA,'resource/roguelike/BlackFlow/map_templates.json')})
write('catalog.json',{'rules':{'version':'hlsh-'+HLSH[:7],'order':kinds,'rules':rules},'templates':{'version':'maa-'+MAA[:7],'templates':templates}})
# MovementSpec values transcribed from pinned BlackFlowModel.cpp 687-811.
movements=[]
rows=[('报废轮子','orthogonalTwo','all',1,1,False,False,0,0,0),('报废假肢','surroundingEight','all',1,1,False,False,0,0,0),('标准引擎','surroundingEight','all',1,3,False,False,0,0,0),('重弹簧','manhattanTwo','all',0,1,False,True,0,0,0),('气垫底座','manhattanTwo','all',1,2,False,False,0,0,0),('试作外骨骼','orthogonalThree','all',1,2,False,False,0,0,0),('小八界','fullMap','nonCombat',0,1,True,True,0,0,0),('一次性喷气背包','fullMap','all',0,1,False,False,0,0,0),('老妈妈的融雪','fullMap','nonCombat',1,1,False,False,0,2,0),('坎诺特的触须','fullMap','shop',1,2,False,False,0,0,4),('结构性原理','fullMap','all',1,3,False,False,0,0,0),('简易遥控器','surroundingEight','all',0,1,False,False,3,0,0)]
for i,(name,ran,target,cost,charges,random,expires,ap,hope,ingots) in enumerate(rows,1):
 movements.append({'id':f'M{i:02d}','sourceID':f'rogue_6_scrap_M_{i:02d}','name':name,'aliases':[],'range':ran,'targetFilter':target,'apCost':cost,'minimumAPToStart':1,'initialCharges':charges,'randomTarget':random,'expiresOnFloorEnd':expires,'effects':{'ap':ap,'hope':hope,'ingots':ingots},'provenance':provenance('MaaAssistantArknights/MaaAssistantArknights',MAA,'src/MaaCore/Task/Roguelike/BlackFlow/BlackFlowModel.cpp')})
write('movement-catalog.json',{'version':'maa-'+MAA[:7],'movements':movements})
print(f'Transcribed {len(rules)} rules, {len(templates)} research templates, {len(movements)} movements')

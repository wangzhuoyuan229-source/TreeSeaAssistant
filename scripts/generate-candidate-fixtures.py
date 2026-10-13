"""Execute the pinned upstream functions; no vendor module is shipped in the App."""
import json, sys, types
from pathlib import Path
root=Path(__file__).resolve().parents[1]
raw=root/'.build-evidence/upstream'
pkg=types.ModuleType('rules'); pkg.__path__=[]; sys.modules['rules']=pkg
loader=types.ModuleType('rules.rule_loader'); loader.RuleSet=object; sys.modules['rules.rule_loader']=loader
mod=types.ModuleType('rules.candidate_filter'); mod.__file__=str(raw/'hlsh-filter.py'); sys.modules[mod.__name__]=mod
exec(compile((raw/'hlsh-filter.py').read_text(),mod.__file__,'exec'),mod.__dict__)
catalog=json.loads((root/'Packages/TreeSeaCore/Sources/TreeSeaCore/Resources/catalog.json').read_text())
names=dict(zip(catalog['rules']['order'],['诡意行商','秘境行商','安全的角落','不期而遇','得偿所愿','失与得','先行一步','误入奇境','狭路相逢','应急助力','险路小径']))
class Distance:
 def __init__(self,kind): self.kind=kind
 def allows(self,floor,distance):
  rule=next(r for r in catalog['rules']['rules'] if r['kind']==self.kind and r['floor']==floor)['distance']
  return False if 'forbidden' in rule else True if 'unrestricted' in rule else rule['closedRange']['min']<=distance<=rule['closedRange']['max']
class Rules:
 categories={'unknown_mystery':list(names.values())}
 distance_rules={name:Distance(kind) for kind,name in names.items()}
 def generation_limit(self,name,floor):
  kind=next(k for k,n in names.items() if n==name)
  r=next(r for r in catalog['rules']['rules'] if r['kind']==kind and r['floor']==floor)['count']['range']
  return types.SimpleNamespace(minimum=r['min'],maximum=r['max'],allowed_counts=None)
 def generation_maximum(self,name,floor): return self.generation_limit(name,floor).maximum
rules=Rules(); reverse={n:k for k,n in names.items()}; cases=[]
for floor in range(1,6):
 for dist in range(16):
  for count in [0,1,2]:
   visible={'秘境行商':count}
   result=mod.filter_candidates(rules,category='unknown_mystery',floor=floor,distance_from_start=dist,appeared_counts=visible)
   cases.append({'floor':floor,'distance':dist,'secretShopCount':count,'expected':[reverse[n] for n in result]})
out=root/'Packages/TreeSeaCore/Tests/TreeSeaCoreTests/Fixtures'
(out/'hlsh-local-candidates.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2)+'\n')
cases=[]
for floor in range(1,6):
 predictions={str(i):mod.filter_candidates(rules,category='unknown_mystery',floor=floor,distance_from_start=i+2) for i in range(6)}
 result=mod.propagate_global_capacities(rules,floor=floor,predictions=predictions)
 cases.append({'floor':floor,'domains':{k:[reverse[n] for n in v] for k,v in predictions.items()},'expected':{k:[reverse[n] for n in v] for k,v in result.items()}})
(out/'hlsh-global-candidates.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2)+'\n')
print('Executed upstream: 240 local cases and 5 global cases')

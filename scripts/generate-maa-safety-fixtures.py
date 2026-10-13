"""Run the exact pinned SafetyValueSolver with deterministic synthetic callbacks.
Only the OnDemand game-host adapter is omitted; the solver body is unmodified.
"""
from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[1];raw=root/'.build-evidence/upstream';out=raw/'safety-harness';out.mkdir(exist_ok=True)
(out/'BlackFlowSafetyValue.h').write_bytes((raw/'maa-safety.h').read_bytes())
(out/'BlackFlowStateSpace.h').write_text('#pragma once\n#include <cstdint>\n#include <limits>\nnamespace asst::blackflow {using SafetyStateId = std::uint32_t; inline constexpr int UnreachableActionPointRequirement = std::numeric_limits<int>::max() / 4;}\n')
source=(raw/'maa-safety.cpp').read_text();source=source[:source.index('LazySafetyValueProblem make_on_demand_safety_value_problem(')]+'\n} // namespace asst::blackflow\n'
(out/'Solver.cpp').write_text(source)
(out/'main.cpp').write_text('''#include "BlackFlowSafetyValue.h"
#include <iostream>
#include <map>
using namespace asst::blackflow;
int main(){
 for(int scenario=0;scenario<4;++scenario){
  std::map<SafetyStateId,std::vector<SafetyValueAction>> edges;
  if(scenario==0)edges={{0,{{"walk-1",1,1,{{1,0}}}}},{1,{{"walk-2",1,1,{{2,0}}}}}};
  if(scenario==1)edges={{0,{{"M12",0,1,{{1,3}}},{"walk-1",1,1,{{3,0}}}}},{1,{{"walk-2",4,1,{{2,0}}}}},{3,{{"walk-2",4,1,{{2,0}}}}}};
  if(scenario==2)edges={{0,{{"M08",0,1,{{2,0}}}}}};
  if(scenario==3)edges={{0,{{"walk-1",1,1,{{1,0}}}}},{1,{{"walk-back",1,1,{{0,0}}},{"walk-2",1,1,{{2,0}}}}}};
  LazySafetyValueProblem p;p.is_goal=[](SafetyStateId id){return id==2;};p.expand_actions=[edges](SafetyStateId id,std::vector<SafetyValueAction>& actions,std::string& error){auto it=edges.find(id);actions=it==edges.end()?std::vector<SafetyValueAction>{}:it->second;return true;};
  SafetyValueSolver solver(p);const int requirement=solver.N(0);
  for(int ap=0;ap<=5;++ap)std::cout<<scenario<<","<<ap<<","<<requirement<<","<<solver.certifies(0,ap)<<"\\n";
 }
}
''')
binary=out/'run';subprocess.run(['xcrun','clang++','-std=c++20','-I',str(out),str(out/'Solver.cpp'),str(out/'main.cpp'),'-o',str(binary)],check=True)
cases=[]
for line in subprocess.check_output([str(binary)],text=True).splitlines():
 scenario,ap,required,reachable=map(int,line.split(','));cases.append({'scenario':scenario,'ap':ap,'minimumRequiredAP':required,'reachable':bool(reachable)})
fixture={'sourceCommit':'59bd4cecf6420f963add79ee005f969a7f5d6131','sourceFunction':'BlackFlowSafetyValue.cpp:SafetyValueSolver','harnessDifference':'OnDemand host adapter omitted; original solver and header retained; state ID aliases supplied for synthetic callbacks','cases':cases}
(root/'Packages/TreeSeaCore/Tests/TreeSeaCoreTests/Fixtures/maa-safety-planning.json').write_text(json.dumps(fixture,indent=2)+'\n')
print('Executed pinned SafetyValueSolver:',len(cases),'deterministic AP scenarios')

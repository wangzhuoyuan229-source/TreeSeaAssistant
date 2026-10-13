"""Compile exact pinned C++ pure helpers and save their outputs for Swift replay."""
from pathlib import Path
import subprocess,json,re
root=Path(__file__).resolve().parents[1];raw=root/'.build-evidence/upstream'
def function(text,name):
 start=text.index(name);start=text.rfind('\n',0,start)+1
 brace=text.index('{',start);depth=1;end=brace+1
 while depth:
  if text[end]=='{':depth+=1
  if text[end]=='}':depth-=1
  end+=1
 return text[start:end]
geometry=function((raw/'maa-compact.cpp').read_text(),'bool geometry_matches(')
ap=function((raw/'maa-model.cpp').read_text(),'int action_points_after(')
source='''#include <algorithm>
#include <limits>
#include <cstdint>
#include <cstdlib>
#include <iostream>
struct GridPosition {int row;int column;};
enum class MovementRange {WalkEdges,OrthogonalTwo,SurroundingEight,ManhattanTwo,OrthogonalThree,FullMap};
'''+geometry+'\n'+ap+'''
int main(){
 const MovementRange ranges[]={MovementRange::OrthogonalTwo,MovementRange::SurroundingEight,MovementRange::ManhattanTwo,MovementRange::OrthogonalThree,MovementRange::FullMap};
 for(int range=0;range<5;++range)for(int row=0;row<5;++row)for(int col=0;col<5;++col)std::cout<<range<<","<<row<<","<<col<<","<<geometry_matches({2,2},{row,col},ranges[range])<<"\\n";
 for(int current=0;current<9;++current)for(int cost=0;cost<4;++cost)for(int gain=0;gain<4;++gain)std::cout<<"AP,"<<current<<","<<cost<<","<<gain<<","<<action_points_after(current,cost,gain)<<"\\n";
}
'''
cpp=raw/'fixture-helpers.cpp';cpp.write_text(source);binary=raw/'fixture-helpers'
subprocess.run(['xcrun','clang++','-std=c++20',str(cpp),'-o',str(binary)],check=True)
lines=subprocess.check_output([str(binary)],text=True).splitlines();geometryCases=[];resourceCases=[]
for line in lines:
 fields=line.split(',')
 if fields[0]=='AP':
  current,cost,gain,result=map(int,fields[1:]);resourceCases.append({'ap':current,'cost':cost,'gain':gain,'result':result})
 else:
  ran,row,col,allowed=map(int,fields);geometryCases.append({'range':ran,'row':row,'column':col,'sourceAllows':bool(allowed),'appAllows':bool(allowed) and (row,col)!=(2,2)})
out=root/'Packages/TreeSeaCore/Tests/TreeSeaCoreTests/Fixtures'
(out/'maa-movements.json').write_text(json.dumps({'sourceCommit':'59bd4cecf6420f963add79ee005f969a7f5d6131','functions':['BlackFlowCompactStateSpace.cpp:geometry_matches','BlackFlowModel.cpp:action_points_after'],'appDifference':'Same-cell targets excluded; AP affordability checked before applying the source transfer','geometry':geometryCases,'resources':resourceCases},indent=2)+'\n')
print('Compiled pinned source helpers:',len(geometryCases),'geometry +',len(resourceCases),'resource outputs')

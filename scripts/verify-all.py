"""Run local checks in dependency order and record actual exits, including iOS blockers."""
from pathlib import Path
import subprocess, json, re, sys
root=Path(__file__).resolve().parents[1];logs=root/'.build-evidence';logs.mkdir(exist_ok=True)
commands=[('core',['bash','scripts/test-core.sh']),('support-recognition',['bash','scripts/test-support.sh']),('project',['python3','scripts/validate-project.py']),('ui-host-diagnostic',['python3','scripts/typecheck-ui-diagnostic.py']),('ios',['bash','scripts/verify-ios.sh'])]
results=[]
for name,argv in commands:
 log=logs/('final-'+name+'.log')
 with log.open('w') as f:result=subprocess.run(argv,cwd=root,stdout=f,stderr=subprocess.STDOUT)
 text=log.read_text();match=re.search(r'Test run with (\d+) tests in (\d+) suites passed',text)
 status='passed' if result.returncode==0 else 'blocked' if name=='ios' and result.returncode in [2,3] else 'failed'
 record={'name':name,'command':argv,'exitCode':result.returncode,'status':status,'log':str(log.relative_to(root))}
 if match:record['testsPassed']=int(match[1]);record['suites']=int(match[2])
 results.append(record);print(name,status,'exit',result.returncode,record.get('testsPassed',''))
report={'startedClientDate':'2026-10-13','verificationClientDate':'2026-10-14','timezone':'Asia/Shanghai','overall':'incomplete: iOS build and device acceptance not completed','commands':results,'hostTestsPassed':sum(x.get('testsPassed',0) for x in results if x['status']=='passed'),'deviceAcceptance':'not performed','realScreenshotAcceptance':'not performed'}
(root/'docs/acceptance/verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
sys.exit(1 if any(x['status']=='failed' for x in results) else 0)

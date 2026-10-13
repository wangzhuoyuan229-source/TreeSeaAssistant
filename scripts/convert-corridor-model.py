"""Convert the pinned ONNX graph and compare raw logits without training."""
from pathlib import Path
import json, hashlib, platform
import numpy as np
import onnx, onnxruntime as ort, torch, coremltools as ct
from onnx2torch import convert
root=Path(__file__).resolve().parents[1]
source=root/'.build-evidence/upstream/maa-corridor.onnx'
model=onnx.load(str(source));onnx.checker.check_model(model)
network=convert(model).eval()
example=torch.zeros(1,3,40,160)
traced=torch.jit.trace(network,example)
converted=ct.convert(traced,inputs=[ct.TensorType(name='input',shape=(1,3,40,160),dtype=np.float32)],outputs=[ct.TensorType(name='logit',dtype=np.float32)],convert_to='mlprogram',minimum_deployment_target=ct.target.iOS17,compute_precision=ct.precision.FLOAT32)
converted.author='MAA contributors; Swift iOS adaptation'
converted.short_description='Pinned BlackFlow corridor raw-logit classifier; no node-type probability output'
path=root/'TreeSeaAssistant/Models/BlackFlowCorridor.mlpackage'
converted.save(str(path))
reference=ort.InferenceSession(str(source),providers=['CPUExecutionProvider'])
random=np.random.default_rng(20261013)
results=[]
for name,tensor in [('dark',np.full((1,3,40,160),-2,dtype=np.float32)),('light',np.full((1,3,40,160),2,dtype=np.float32)),('noise',random.uniform(-2,2,(1,3,40,160)).astype(np.float32)),('corridor',np.pad(np.ones((1,3,8,160),dtype=np.float32),((0,0),(0,0),(16,16),(0,0)),constant_values=-2))]:
 expected=float(np.asarray(reference.run(None,{'input':tensor})[0]).reshape(-1)[0])
 actual=float(np.asarray(converted.predict({'input':tensor})['logit']).reshape(-1)[0])
 error=abs(expected-actual)
 results.append({'name':name,'onnx':expected,'coreml':actual,'absoluteError':error,'decisionEqual':(expected>=2.2421875)==(actual>=2.2421875)})
 assert error<=1e-4,(name,error)
 assert results[-1]['decisionEqual']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
files={str(p.relative_to(path)):sha(p) for p in path.rglob('*') if p.is_file()}
report={'sourceCommit':'59bd4cecf6420f963add79ee005f969a7f5d6131','sourceSHA256':sha(source),'runtimeSHA256':sha(root/'.build-evidence/upstream/maa-runtime.json'),'coremlFiles':files,'tools':{'torch':torch.__version__,'onnx':onnx.__version__,'onnxruntime':ort.__version__,'coremltools':ct.__version__,'python':platform.python_version()},'syntheticOutputComparison':results,'gameScreenshotValidation':'not performed'}
(root/'docs/acceptance/model-conversion.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(results,indent=2))

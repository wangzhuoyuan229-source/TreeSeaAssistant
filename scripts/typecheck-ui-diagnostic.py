"""Host-only diagnostic. UIKit, keyboard placement and size-class are adapted.
This checks common SwiftUI bodies but cannot prove the iOS App builds or runs.
The alias selects the existing State property wrapper without missing CLT macros.
Run scripts/test-support.sh first. No product target or source is modified.
"""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1];out=root/'.build-evidence/ui-typecheck';out.mkdir(parents=True,exist_ok=True)
for folder in ['Navigation','Views','Design']:
 for p in (root/'TreeSeaAssistant'/folder).glob('*.swift'):
  s=p.read_text().replace('import SwiftUI','import SwiftUI\nimport AppKit\nimport TreeSeaAppSupport\n@testable import TreeSeaRecognition').replace('.keyboardType(.numberPad)','').replace('placement:.keyboard','placement:.automatic').replace('UIImage(data:','NSImage(data:').replace('Image(uiImage:','Image(nsImage:').replace('@Environment(\\.horizontalSizeClass) private var sizeClass','private let sizeClass:UserInterfaceSizeClass? = .regular').replace('@State ','@LegacyState ')
  (out/p.name).write_text(s)
(out/'LegacyState.swift').write_text('import SwiftUI\ntypealias LegacyState<Value> = SwiftUI.State<Value>\n')
cmd=['swiftc','-typecheck','-target','arm64-apple-macos14.0','-default-isolation','MainActor','-I',str(root/'.build/arm64-apple-macosx/debug/Modules'),'-plugin-path','/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins']+[str(p) for p in out.glob('*.swift')]
subprocess.run(cmd,cwd=root,check=True)
print('Host diagnostic typecheck passed; iOS build/UI acceptance remains unverified')

"""Generate the repository's iOS-only project using deterministic PBX identifiers."""
from pathlib import Path
import hashlib, json, subprocess
root=Path(__file__).resolve().parents[1]; project=root/'TreeSeaAssistant.xcodeproj';project.mkdir(exist_ok=True)
previousProject=project/'project.pbxproj'
previousObjects=json.loads(subprocess.check_output(['plutil','-convert','json','-o','-',str(previousProject)]))['objects'] if previousProject.exists() else {}
objects={}
def uid(name):return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def ref(name):return uid(name)
def put(identity,isa,**fields):
 if isa=='XCBuildConfiguration':
  previousSettings=previousObjects.get(uid(identity),{}).get('buildSettings',{})
  if 'DEVELOPMENT_TEAM' in previousSettings:fields['buildSettings']['DEVELOPMENT_TEAM']=previousSettings['DEVELOPMENT_TEAM']
 objects[uid(identity)]={'isa':isa,**fields};return uid(identity)
def buildfile(name,file,**extra):return put('build:'+name,'PBXBuildFile',fileRef=file,**extra)
products=[];groups=[];sourceLists={}
for target,folder in [('app','TreeSeaAssistant'),('unit','Tests/TreeSeaAssistantTests'),('ui','Tests/TreeSeaAssistantUITests')]:
 refs=[];builds=[]
 for p in sorted((root/folder).rglob('*.swift')):
  name=str(p.relative_to(root));r=put('file:'+name,'PBXFileReference',lastKnownFileType='sourcecode.swift',path=name,sourceTree='SOURCE_ROOT');refs.append(r);builds.append(buildfile(name,r))
 groups.append(put('group:'+target,'PBXGroup',children=refs,name={'app':'App','unit':'Unit Tests','ui':'UI Tests'}[target],sourceTree='<group>'));sourceLists[target]=builds
resources=[]
for path,typ in [('TreeSeaAssistant/Assets.xcassets','folder.assetcatalog'),('TreeSeaAssistant/Resources/asset-index.json','text.json'),('TreeSeaAssistant/Models/corridor-runtime.json','text.json'),('TreeSeaAssistant/Resources/recognition-reference.png','image.png')]:
 r=put('file:'+path,'PBXFileReference',lastKnownFileType=typ,path=path,sourceTree='SOURCE_ROOT');resources.append(buildfile(path,r));groups.append(r)
model='TreeSeaAssistant/Models/BlackFlowCorridor.mlpackage';r=put('file:'+model,'PBXFileReference',lastKnownFileType='folder.mlpackage',path=model,sourceTree='SOURCE_ROOT');groups.append(r);sourceLists['app'].append(buildfile(model,r))
pkg=put('package','XCLocalSwiftPackageReference',relativePath='Packages/TreeSeaCore')
packageProducts={}
for key in ['app','unit']:
 packageProducts[key]=put('product:'+key,'XCSwiftPackageProductDependency',package=pkg,productName='TreeSeaCore')
 configs=[]
 for mode in ['Debug','Release']:
  settings={'SWIFT_VERSION':'6.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'1,2','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SDKROOT':'iphoneos','GENERATE_INFOPLIST_FILE':'YES','PRODUCT_NAME':'$(TARGET_NAME)','CODE_SIGN_STYLE':'Automatic','SWIFT_STRICT_CONCURRENCY':'complete','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if mode=='Debug' else '', 'SUPPORTS_MACCATALYST':'NO','SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD':'NO'}
  if key=='app':settings.update({'PRODUCT_BUNDLE_IDENTIFIER':'com.treesea.assistant','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','INFOPLIST_KEY_CFBundleDisplayName':'黑流树海','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','MARKETING_VERSION':'0.2.0','CURRENT_PROJECT_VERSION':'2','SWIFT_DEFAULT_ACTOR_ISOLATION':'MainActor'})
  if key=='app' and mode=='Release':settings['EXCLUDED_SOURCE_FILE_NAMES']='recognition-reference.png'
  if key!='app':settings.update({'PRODUCT_BUNDLE_IDENTIFIER':'com.treesea.assistant.tests','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/TreeSeaAssistant.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TreeSeaAssistant','BUNDLE_LOADER':'$(TEST_HOST)'})
  configs.append(put(f'config:{key}:{mode}','XCBuildConfiguration',name=mode,buildSettings=settings))
 put('configs:'+key,'XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
# UI configurations: hosted by app through TEST_TARGET_NAME, not TEST_HOST.
configs=[]
for mode in ['Debug','Release']:
 configs.append(put('config:ui:'+mode,'XCBuildConfiguration',name=mode,buildSettings={'SWIFT_VERSION':'6.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'1,2','SDKROOT':'iphoneos','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','GENERATE_INFOPLIST_FILE':'YES','PRODUCT_BUNDLE_IDENTIFIER':'com.treesea.assistant.uitests','PRODUCT_NAME':'$(TARGET_NAME)','TEST_TARGET_NAME':'TreeSeaAssistant','SWIFT_STRICT_CONCURRENCY':'complete'}))
put('configs:ui','XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
for key,name,kind in [('app','TreeSeaAssistant','application'),('unit','TreeSeaAssistantTests','bundle.unit-test'),('ui','TreeSeaAssistantUITests','bundle.ui-testing')]:
 product=put('binary:'+key,'PBXFileReference',explicitFileType='wrapper.application' if key=='app' else 'wrapper.cfbundle',includeInIndex=0,path=name+('.app' if key=='app' else '.xctest'),sourceTree='BUILT_PRODUCTS_DIR');products.append(product)
 source=put('sources:'+key,'PBXSourcesBuildPhase',buildActionMask=2147483647,files=sourceLists[key],runOnlyForDeploymentPostprocessing=0)
 fs=[]
 if key in packageProducts:fs=[put('link:'+key,'PBXBuildFile',productRef=packageProducts[key])]
 frameworks=put('frameworks:'+key,'PBXFrameworksBuildPhase',buildActionMask=2147483647,files=fs,runOnlyForDeploymentPostprocessing=0)
 phases=[source,frameworks]
 if key=='app':
  phases.append(put('resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=resources,runOnlyForDeploymentPostprocessing=0))
  embed=put('embed:core','PBXBuildFile',productRef=packageProducts[key],settings={'ATTRIBUTES':['CodeSignOnCopy','RemoveHeadersOnCopy']})
  phases.append(put('embed-frameworks','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=10,files=[embed],name='Embed Frameworks',runOnlyForDeploymentPostprocessing=0))
 deps=[]
 if key!='app':
  proxy=put('proxy:'+key,'PBXContainerItemProxy',containerPortal=ref('project'),proxyType=1,remoteGlobalIDString=ref('target:app'),remoteInfo='TreeSeaAssistant')
  deps=[put('dep:'+key,'PBXTargetDependency',target=ref('target:app'),targetProxy=proxy)]
 put('target:'+key,'PBXNativeTarget',buildConfigurationList=ref('configs:'+key),buildPhases=phases,buildRules=[],dependencies=deps,name=name,productName=name,productReference=product,productType='com.apple.product-type.'+kind,packageProductDependencies=[packageProducts[key]] if key in packageProducts else [])
productGroup=put('products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main=put('main','PBXGroup',children=groups+[productGroup],sourceTree='<group>')
projectConfigs=[]
for mode in ['Debug','Release']:projectConfigs.append(put('projectconfig:'+mode,'XCBuildConfiguration',name=mode,buildSettings={'CLANG_ENABLE_MODULES':'YES','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @loader_path/Frameworks','ONLY_ACTIVE_ARCH':'YES' if mode=='Debug' else 'NO','ENABLE_TESTABILITY':'YES' if mode=='Debug' else 'NO','SWIFT_VERSION':'6.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0'}))
put('projectconfigs','XCConfigurationList',buildConfigurations=projectConfigs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
put('project','PBXProject',attributes={'LastUpgradeCheck':'2600','BuildIndependentTargetsInParallel':'YES','TargetAttributes':{ref('target:unit'):{'TestTargetID':ref('target:app')},ref('target:ui'):{'TestTargetID':ref('target:app')}}},buildConfigurationList=ref('projectconfigs'),compatibilityVersion='Xcode 14.0',developmentRegion='zh-Hans',hasScannedForEncodings=0,knownRegions=['zh-Hans','en','Base'],mainGroup=main,productRefGroup=productGroup,projectDirPath='',projectRoot='',packageReferences=[pkg],targets=[ref('target:app'),ref('target:unit'),ref('target:ui')])
def serialize(v):
 if isinstance(v,dict):return '{ '+ ' '.join(json.dumps(str(k),ensure_ascii=False)+' = '+serialize(val)+';' for k,val in v.items())+' }'
 if isinstance(v,list):return '( '+', '.join(serialize(x) for x in v)+(' ,' if v else '')+' )'
 if isinstance(v,int):return str(v)
 return json.dumps(v,ensure_ascii=False)
text='// !$*UTF8*$!\n'+serialize({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':ref('project')})+'\n'
(project/'project.pbxproj').write_text(text)
scheme=project/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
def buildRef(key,name):return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ref("target:"+key)}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:TreeSeaAssistant.xcodeproj"/>'
(scheme/'TreeSeaAssistant.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildRef('app','TreeSeaAssistant.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildRef('unit','TreeSeaAssistantTests.xctest')}</TestableReference><TestableReference skipped="NO">{buildRef('ui','TreeSeaAssistantUITests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildRef('app','TreeSeaAssistant.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildRef('app','TreeSeaAssistant.app')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated iPhone/iPad project, 3 targets, shared scheme with 2 test targets')

"""Regenerate derived skin PNGs and the dependency-free Xcode project.
Run with Python 3 + Pillow. The generated Xcode project is already included.
"""
import hashlib
import json
import pathlib
import plistlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
RES = ROOT / 'WinampClassic/Resources'

def sprite(dst, name, box, point):
    source = Image.open(RES / (name + '.png')).convert('RGB')
    x, y, w, h = box
    assert 0 <= x and 0 <= y and x + w <= source.width and y + h <= source.height, (name, box)
    dst.paste(source.crop((x, y, x+w, y+h)), point)

main = Image.open(RES/'main.png').convert('RGB')
sprite(main, 'titlebar', (27, 0, 275, 14), (0, 0))
for x, src in [(6, 0), (244, 9), (264, 18)]:
    sprite(main, 'titlebar', (src, 0, 9, 9), (x, 3))
sprite(main, 'titlebar', (0, 18, 9, 9), (254, 3))
sprite(main, 'cbuttons', (0, 0, 114, 18), (16, 88))
sprite(main, 'cbuttons', (114, 0, 22, 16), (136, 89))
sprite(main, 'shufrep', (28, 0, 47, 15), (164, 89))
sprite(main, 'shufrep', (0, 0, 28, 15), (210, 89))
sprite(main, 'shufrep', (0, 61, 23, 12), (219, 58))
sprite(main, 'shufrep', (23, 73, 23, 12), (242, 58))
sprite(main, 'monoster', (29, 12, 28, 12), (212, 41))
sprite(main, 'monoster', (0, 12, 29, 12), (239, 41))
main.save(RES/'main_base.png')

playlist = Image.new('RGB', (275, 232))
for box, point in [((0,0,25,20),(0,0)), ((127,0,12,20),(25,0)),
                   ((127,0,25,20),(37,0)), ((127,0,25,20),(62,0)),
                   ((26,0,100,20),(87,0)), ((127,0,13,20),(187,0)),
                   ((127,0,25,20),(200,0)), ((127,0,25,20),(225,0)),
                   ((153,0,25,20),(250,0)), ((0,72,125,38),(0,194)),
                   ((126,72,150,38),(125,194))]:
    sprite(playlist, 'pledit', box, point)
for y in range(20, 194, 29):
    for sx, dx, w in [(0,0,12),(31,255,5),(36,260,8),(44,268,7)]:
        sprite(playlist, 'pledit', (sx,42,w,29), (dx,y))
sprite(playlist, 'pledit', (52,53,8,18), (260,20))
playlist.save(RES/'playlist_base.png')

# Honest visual composition of the bundled skin, not an iOS simulator screenshot.
preview_main = main.copy()
for name, box, point in [('volume',(0,300,68,13),(107,57)),('volume',(15,422,14,11),(145,58)),
                         ('balance',(9,0,38,13),(177,57)),('balance',(15,422,14,11),(189,58)),
                         ('posbar',(0,0,248,10),(16,72)),('posbar',(248,0,29,10),(16,72)),
                         ('playpaus',(18,0,9,9),(26,28))]:
    sprite(preview_main,name,box,point)
for x in [48,60,78,90]: sprite(preview_main,'numbers',(0,0,9,13),(x,26))
for i,c in enumerate('WINAMP - ADD MUSIC'):
    sx,sy = ((ord(c)-65)*5,0) if 'A' <= c <= 'Z' else ((75,6) if c=='-' else (150,0))
    sprite(preview_main,'text',(sx,sy,5,6),(111+i*5,27))
eq = Image.open(RES/'eqmain.png').convert('RGB').crop((0,0,275,116))
sprite(eq,'eqmain',(0,134,275,14),(0,0))
sprite(eq,'eqmain',(69,119,25,12),(14,18))
sprite(eq,'eqmain',(35,119,33,12),(39,18))
sprite(eq,'eqmain',(224,164,44,12),(217,18))
sprite(eq,'eqmain',(0,116,9,9),(264,3))
sprite(eq,'eqmain',(0,294,113,19),(86,17))
ImageDraw.Draw(eq).line((88,26,196,26),fill=(217,217,102))
for i in range(11):
    x=21 if i==0 else 78+(i-1)*18
    position=31; frame=27-position*28//64
    sprite(eq,'eqmain',(13+(frame%14)*15,164 if frame<14 else 229,14,63),(x,38))
    sprite(eq,'eqmain',(0,164,11,11),(x+1,38+51-(63-position)*52//64))
sprite(preview_main,'shufrep',(0,73,23,12),(219,58))
preview = Image.new('RGB',(275,464))
preview.paste(preview_main,(0,0)); preview.paste(eq,(0,116)); preview.paste(playlist,(0,232))
preview.resize((825,1392),Image.Resampling.NEAREST).save(ROOT/'skin-preview.png')

# Write a conventional OpenStep pbxproj; stable IDs make diffs readable.
objects = {}
def ident(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def put(object_key, **value):
    key = ident(object_key); objects[key] = value; return key
source_paths = sorted((ROOT/'WinampClassic').glob('*.swift'))
resource_paths = sorted([*RES.glob('*.png'), *RES.glob('*.mp3'), ROOT/'WinampClassic/Assets.xcassets'])
source_refs, resource_refs, source_builds, resource_builds = [], [], [], []
for paths, refs, builds, kind in [(source_paths,source_refs,source_builds,'sourcecode.swift'),(resource_paths,resource_refs,resource_builds,'image.png')]:
    for path in paths:
        rel = path.relative_to(ROOT).as_posix()
        filetype = {'.mp3': 'audio.mp3', '.xcassets': 'folder.assetcatalog'}.get(path.suffix, kind)
        ref = put('file:'+rel,isa='PBXFileReference',lastKnownFileType=filetype,path=rel,sourceTree='<group>')
        refs.append(ref)
        builds.append(put('build:'+rel,isa='PBXBuildFile',fileRef=ref))
product = put('product',isa='PBXFileReference',explicitFileType='wrapper.application',includeInIndex=0,path='WinampClassic.app',sourceTree='BUILT_PRODUCTS_DIR')
products = put('products',isa='PBXGroup',children=[product],name='Products',sourceTree='<group>')
sources = put('sources',isa='PBXGroup',children=source_refs,name='Swift',sourceTree='<group>')
resources = put('resources',isa='PBXGroup',children=resource_refs,name='Classic skin',sourceTree='<group>')
group = put('group',isa='PBXGroup',children=[sources,resources,products],sourceTree='<group>')
source_phase = put('source-phase',isa='PBXSourcesBuildPhase',buildActionMask=2147483647,files=source_builds,runOnlyForDeploymentPostprocessing=0)
resource_phase = put('resource-phase',isa='PBXResourcesBuildPhase',buildActionMask=2147483647,files=resource_builds,runOnlyForDeploymentPostprocessing=0)
framework_phase = put('framework-phase',isa='PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)
configs = {}; target_configs = {}
for name in ['Debug','Release']:
    configs[name] = put('project:'+name,isa='XCBuildConfiguration',name=name,buildSettings={
        'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'16.0','CLANG_ENABLE_MODULES':'YES',
        'SWIFT_VERSION':'5.0','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O',
        'DEBUG_INFORMATION_FORMAT':'dwarf' if name=='Debug' else 'dwarf-with-dsym',
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if name=='Debug' else '',
        'ENABLE_TESTABILITY':'YES' if name=='Debug' else 'NO'})
    target_configs[name] = put('target:'+name,isa='XCBuildConfiguration',name=name,buildSettings={
        'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.personal.winampclassic',
        'INFOPLIST_FILE':'WinampClassic/Info.plist','CODE_SIGN_STYLE':'Automatic',
        'TARGETED_DEVICE_FAMILY':'1','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator',
        'SUPPORTS_MACCATALYST':'NO','CURRENT_PROJECT_VERSION':'7','MARKETING_VERSION':'0.6.0',
        'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon',
        'LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks']})
config_list = put('config-list',isa='XCConfigurationList',buildConfigurations=list(configs.values()),defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
target_config_list = put('target-config-list',isa='XCConfigurationList',buildConfigurations=list(target_configs.values()),defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
target = put('target',isa='PBXNativeTarget',buildConfigurationList=target_config_list,buildPhases=[source_phase,framework_phase,resource_phase],buildRules=[],dependencies=[],name='WinampClassic',productName='WinampClassic',productReference=product,productType='com.apple.product-type.application')
project = put('project',isa='PBXProject',attributes={'LastUpgradeCheck':'1600'},buildConfigurationList=config_list,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base','tr'],mainGroup=group,productRefGroup=products,projectDirPath='',projectRoot='',targets=[target])
def encode(value, level=0):
    if isinstance(value,dict): return '{\n'+''.join('\t'*(level+1)+json.dumps(k)+' = '+encode(v,level+1)+';\n' for k,v in value.items())+'\t'*level+'}'
    if isinstance(value,list): return '('+', '.join(encode(v,level) for v in value)+')'
    return str(value) if isinstance(value,int) else json.dumps(value)
projdir=ROOT/'WinampClassic.xcodeproj'; projdir.mkdir(exist_ok=True)
(projdir/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':project})+'\n',encoding='utf-8')
scheme_dir=projdir/'xcshareddata/xcschemes'; scheme_dir.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="WinampClassic.app" BlueprintName="WinampClassic" ReferencedContainer="container:WinampClassic.xcodeproj"/>'
(scheme_dir/'WinampClassic.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''',encoding='utf-8')
info={'CFBundleDevelopmentRegion':'en','CFBundleDisplayName':'Winamp',
      'CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)',
      'CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL',
      'CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)',
      'LSRequiresIPhoneOS':True,'UILaunchScreen':{},'UIBackgroundModes':['audio'],
      'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait'],
      'UIUserInterfaceStyle':'Dark','ITSAppUsesNonExemptEncryption':False}
(ROOT/'WinampClassic/Info.plist').write_bytes(plistlib.dumps(info))
print(f'Generated project: {len(source_paths)} Swift files, {len(resource_paths)} skin resources.')

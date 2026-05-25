#!/usr/bin/env python3
"""Generate a minimal .xcodeproj for the Clipboard app."""
import os, hashlib, sys

PROJ_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(PROJ_DIR, "Clipboard.xcodeproj")

def uuid(seed):
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

# ── files (relative to Clipboard/ dir) ──
sources = [
    "main.swift",
    "AppDelegate.swift",
    "Models/ContentType.swift",
    "Models/ClipboardItem+CoreDataClass.swift",
    "Models/ClipboardItem+CoreDataProperties.swift",
    "Services/PersistenceController.swift",
    "Services/ClipboardMonitor.swift",
    "Services/RetentionManager.swift",
    "Services/AutoStartManager.swift",
    "ViewModels/ClipboardViewModel.swift",
    "Views/SearchBarView.swift",
    "Views/ClipboardCardView.swift",
    "Views/EmptyStateView.swift",
    "Views/FooterView.swift",
    "Views/ContentView.swift",
    "Views/Settings/SettingsView.swift",
    "Helpers/ColorTheme.swift",
    "Helpers/DateFormatter+Relative.swift",
    "Helpers/ImageResizer.swift",
    "Helpers/SystemIcon.swift",
]
resources = [
    "Assets.xcassets",
    "ClipboardDataModel.xcdatamodeld",
    "AppIcon.icns",
    "menubar_icon.png",
]
# files not compiled but bundled
info_plist = "Info.plist"

# ── generate UUIDs ──
proj_uuid = uuid("PBXProject")
target_uuid = uuid("PBXNativeTarget")
main_group_uuid = uuid("PBXGroup-main")
clipboard_group_uuid = uuid("PBXGroup-Clipboard")
models_group_uuid = uuid("PBXGroup-Models")
services_group_uuid = uuid("PBXGroup-Services")
viewmodels_group_uuid = uuid("PBXGroup-ViewModels")
views_group_uuid = uuid("PBXGroup-Views")
helpers_group_uuid = uuid("PBXGroup-Helpers")
settings_group_uuid = uuid("PBXGroup-Settings")
src_build_phase_uuid = uuid("PBXSourcesBuildPhase")
res_build_phase_uuid = uuid("PBXResourcesBuildPhase")
framework_phase_uuid = uuid("PBXFrameworksBuildPhase")
proj_config_list = uuid("XCConfigList-project")
target_config_list = uuid("XCConfigList-target")
debug_config_uuid = uuid("XCBuildConfig-debug")
release_config_uuid = uuid("XCBuildConfig-release")
target_debug_uuid = uuid("XCBuildConfig-target-debug")
target_release_uuid = uuid("XCBuildConfig-target-release")

file_refs = {}     # path -> uuid
build_files = {}   # path -> uuid

for path in sources:
    file_refs[path] = uuid("FR-"+path)
    build_files[path] = uuid("BF-"+path)
for path in resources:
    file_refs[path] = uuid("FR-"+path)
    build_files[path] = uuid("BF-"+path)

# info plist
info_ref = uuid("FR-Info.plist")

# products
product_ref = uuid("FR-EasyClip.app")

def quote(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

def build_file_entry(ref, path):
    return f'\t\t{build_files[path]} = {{isa = PBXBuildFile; fileRef = {ref}; }};\n'

def file_ref_entry(uid, path, name, source_tree, file_type=None):
    extra = ""
    if file_type:
        extra += f" lastKnownFileType = {file_type};"
    return f'\t\t{uid} = {{isa = PBXFileReference;{extra} path = {quote(name)}; sourceTree = {quote(source_tree)}; }};\n'

def group_children(uid, children_ids, name, source_tree="<group>", path=None):
    kids = ", ".join(children_ids)
    name_str = f' name = {quote(name)};' if name else ''
    path_str = f' path = {quote(path)};' if path else ''
    return f'\t\t{uid} = {{isa = PBXGroup; children = ({kids});{name_str}{path_str} sourceTree = {quote(source_tree)}; }};\n'

os.makedirs(OUT_DIR, exist_ok=True)

with open(os.path.join(OUT_DIR, "project.pbxproj"), "w") as f:
    f.write("// !$*UTF8*$!\n")
    f.write("{\n")
    f.write('\tarchiveVersion = 1;\n')
    f.write('\tclasses = {};\n')
    f.write('\tobjectVersion = 54;\n')
    f.write('\tobjects = {\n\n')

    # ── PBXBuildFile ──
    for path in sources:
        f.write(build_file_entry(file_refs[path], path))
    for path in resources:
        f.write(build_file_entry(file_refs[path], path))
    f.write("\n")

    # ── PBXFileReference ──
    # sources
    for path in sources:
        name = os.path.basename(path)
        if path.endswith(".swift"):
            f.write(file_ref_entry(file_refs[path], path, name, "<group>", "sourcecode.swift"))
        else:
            f.write(file_ref_entry(file_refs[path], path, name, "<group>"))
    # resources
    for path in resources:
        name = os.path.basename(path)
        if path.endswith(".xcdatamodeld"):
            f.write(file_ref_entry(file_refs[path], path, "ClipboardDataModel.xcdatamodeld", "<group>", "wrapper.xcdatamodeld"))
        elif path.endswith(".icns"):
            f.write(file_ref_entry(file_refs[path], path, name, "<group>", "image.icns"))
        elif path.endswith(".png"):
            f.write(file_ref_entry(file_refs[path], path, name, "<group>", "image.png"))
        else:
            f.write(file_ref_entry(file_refs[path], path, name, "<group>", "folder.assetcatalog"))
    # Info.plist
    f.write(file_ref_entry(info_ref, "Info.plist", "Info.plist", "<group>", "text.plist.xml"))
    # Product
    f.write(file_ref_entry(product_ref, "EasyClip.app", "EasyClip.app", "BUILT_PRODUCTS_DIR", "wrapper.application"))
    f.write("\n")

    # ── PBXGroup ──
    # Helpers subgroup
    helper_paths = [p for p in sources if p.startswith("Helpers/")]
    helper_refs = [file_refs[p] for p in helper_paths]
    f.write(group_children(helpers_group_uuid, helper_refs, "Helpers", "<group>", "Helpers"))

    # Settings subgroup
    settings_paths = [p for p in sources if "Settings" in p]
    settings_refs = [file_refs[p] for p in settings_paths]
    f.write(group_children(settings_group_uuid, settings_refs, "Settings", "<group>", "Settings"))

    # Views subgroup
    view_paths = [p for p in sources if p.startswith("Views/") and "Settings" not in p]
    view_refs = [file_refs[p] for p in view_paths] + [settings_group_uuid]
    f.write(group_children(views_group_uuid, view_refs, "Views", "<group>", "Views"))

    # Models subgroup
    model_paths = [p for p in sources if p.startswith("Models/")]
    model_refs = [file_refs[p] for p in model_paths]
    f.write(group_children(models_group_uuid, model_refs, "Models", "<group>", "Models"))

    # Services subgroup
    svc_paths = [p for p in sources if p.startswith("Services/")]
    svc_refs = [file_refs[p] for p in svc_paths]
    f.write(group_children(services_group_uuid, svc_refs, "Services", "<group>", "Services"))

    # ViewModels subgroup
    vm_paths = [p for p in sources if p.startswith("ViewModels/")]
    vm_refs = [file_refs[p] for p in vm_paths]
    f.write(group_children(viewmodels_group_uuid, vm_refs, "ViewModels", "<group>", "ViewModels"))

    # root-level source files (not in subgroups)
    root_paths = [p for p in sources if "/" not in p]
    root_refs = [file_refs[p] for p in root_paths]

    # Clipboard group
    clipboard_children = (
        root_refs
        + [info_ref]
        + [models_group_uuid, services_group_uuid, viewmodels_group_uuid, views_group_uuid, helpers_group_uuid]
        + [file_refs[p] for p in resources]
    )
    f.write(group_children(clipboard_group_uuid, clipboard_children, "Clipboard", "<group>", "Clipboard"))

    # Main group
    f.write(group_children(main_group_uuid, [clipboard_group_uuid, product_ref], ""))
    f.write("\n")

    # ── PBXNativeTarget ──
    f.write(f'\t\t{target_uuid} = {{isa = PBXNativeTarget; '
            f'buildConfigurationList = {target_config_list}; '
            f'buildPhases = ({src_build_phase_uuid}, {res_build_phase_uuid}, {framework_phase_uuid}); '
            f'buildRules = (); '
            f'dependencies = (); '
            f'name = EasyClip; '
            f'productName = EasyClip; '
            f'productReference = {product_ref}; '
            f'productType = "com.apple.product-type.application"; '
            f'}};\n\n')

    # ── PBXProject ──
    attrs = ('LastSwiftUpdateCheck = 1200; '
             'LastUpgradeCheck = 1200; '
             'ORGANIZATIONNAME = EasyClip;')
    f.write(f'\t\t{proj_uuid} = {{isa = PBXProject; '
            f'attributes = {{{attrs}}}; '
            f'buildConfigurationList = {proj_config_list}; '
            f'compatibilityVersion = "Xcode 12.0"; '
            f'developmentRegion = en; '
            f'hasScannedForEncodings = 0; '
            f'knownRegions = (en, Base, "zh-Hans"); '
            f'mainGroup = {main_group_uuid}; '
            f'productRefGroup = {main_group_uuid}; '
            f'projectDirPath = ""; '
            f'projectRoot = ""; '
            f'targets = ({target_uuid}); '
            f'}};\n\n')

    # ── Build Phases ──
    src_bf_refs = ",\n".join([build_files[p] for p in sources])
    f.write(f'\t\t{src_build_phase_uuid} = {{isa = PBXSourcesBuildPhase; files = (\n{src_bf_refs},\n\t\t); }};\n\n')

    res_bf_refs = ",\n".join([build_files[p] for p in resources])
    f.write(f'\t\t{res_build_phase_uuid} = {{isa = PBXResourcesBuildPhase; files = (\n{res_bf_refs},\n\t\t); }};\n\n')

    f.write(f'\t\t{framework_phase_uuid} = {{isa = PBXFrameworksBuildPhase; files = (); }};\n\n')

    # ── Build Configurations ──
    # Project Debug
    f.write(f'\t\t{debug_config_uuid} = {{isa = XCBuildConfiguration; '
            f'buildSettings = {{ '
            f'ALWAYS_SEARCH_USER_PATHS = NO; '
            f'CLANG_ANALYZER_NONNULL = YES; '
            f'CLANG_CXX_LANGUAGE_STANDARD = "gnu++14"; '
            f'CLANG_ENABLE_MODULES = YES; '
            f'CLANG_ENABLE_OBJC_ARC = YES; '
            f'COPY_PHASE_STRIP = NO; '
            f'DEBUG_INFORMATION_FORMAT = dwarf; '
            f'ENABLE_STRICT_OBJC_MSGSEND = YES; '
            f'ENABLE_TESTABILITY = YES; '
            f'GCC_DYNAMIC_NO_PIC = NO; '
            f'GCC_OPTIMIZATION_LEVEL = 0; '
            f'GCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)"); '
            f'ARCHS = "arm64 x86_64"; '
            f'MACOSX_DEPLOYMENT_TARGET = 10.15; '
            f'MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE; '
            f'ONLY_ACTIVE_ARCH = YES; '
            f'SDKROOT = macosx; '
            f'SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; '
            f'SWIFT_OPTIMIZATION_LEVEL = "-Onone"; '
            f'SWIFT_VERSION = 5.0; '
            f'}}; '
            f'name = Debug; }};\n\n')

    # Project Release
    f.write(f'\t\t{release_config_uuid} = {{isa = XCBuildConfiguration; '
            f'buildSettings = {{ '
            f'ALWAYS_SEARCH_USER_PATHS = NO; '
            f'CLANG_ANALYZER_NONNULL = YES; '
            f'CLANG_CXX_LANGUAGE_STANDARD = "gnu++14"; '
            f'CLANG_ENABLE_MODULES = YES; '
            f'CLANG_ENABLE_OBJC_ARC = YES; '
            f'COPY_PHASE_STRIP = NO; '
            f'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; '
            f'ENABLE_NS_ASSERTIONS = NO; '
            f'ENABLE_STRICT_OBJC_MSGSEND = YES; '
            f'GCC_OPTIMIZATION_LEVEL = s; '
            f'ARCHS = "arm64 x86_64"; '
            f'MACOSX_DEPLOYMENT_TARGET = 10.15; '
            f'MTL_ENABLE_DEBUG_INFO = NO; '
            f'SDKROOT = macosx; '
            f'SWIFT_COMPILATION_MODE = wholemodule; '
            f'SWIFT_OPTIMIZATION_LEVEL = "-O"; '
            f'SWIFT_VERSION = 5.0; '
            f'}}; '
            f'name = Release; }};\n\n')

    # Target Debug
    f.write(f'\t\t{target_debug_uuid} = {{isa = XCBuildConfiguration; '
            f'buildSettings = {{ '
            f'ARCHS = "arm64 x86_64"; '
            f'ONLY_ACTIVE_ARCH = NO; '
            f'CODE_SIGN_STYLE = Automatic; '
            f'COMBINE_HIDPI_IMAGES = YES; '
            f'INFOPLIST_FILE = Clipboard/Info.plist; '
            f'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks"); '
            f'PRODUCT_BUNDLE_IDENTIFIER = com.clipboard.history; '
            f'PRODUCT_NAME = EasyClip; '
            f'EXECUTABLE_NAME = EasyClip; '
            f'SWIFT_VERSION = 5.0; '
            f'}}; '
            f'name = Debug; }};\n\n')

    # Target Release
    f.write(f'\t\t{target_release_uuid} = {{isa = XCBuildConfiguration; '
            f'buildSettings = {{ '
            f'ARCHS = "arm64 x86_64"; '
            f'ONLY_ACTIVE_ARCH = NO; '
            f'CODE_SIGN_STYLE = Automatic; '
            f'COMBINE_HIDPI_IMAGES = YES; '
            f'INFOPLIST_FILE = Clipboard/Info.plist; '
            f'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks"); '
            f'PRODUCT_BUNDLE_IDENTIFIER = com.clipboard.history; '
            f'PRODUCT_NAME = EasyClip; '
            f'EXECUTABLE_NAME = EasyClip; '
            f'SWIFT_VERSION = 5.0; '
            f'}}; '
            f'name = Release; }};\n\n')

    # ── Configuration Lists ──
    f.write(f'\t\t{proj_config_list} = {{isa = XCConfigurationList; '
            f'buildConfigurations = ({debug_config_uuid}, {release_config_uuid}); '
            f'defaultConfigurationIsVisible = 0; '
            f'defaultConfigurationName = Release; }};\n\n')

    f.write(f'\t\t{target_config_list} = {{isa = XCConfigurationList; '
            f'buildConfigurations = ({target_debug_uuid}, {target_release_uuid}); '
            f'defaultConfigurationIsVisible = 0; '
            f'defaultConfigurationName = Release; }};\n\n')

    f.write('\t};\n')
    f.write(f'\trootObject = {proj_uuid};\n')
    f.write('}\n')

print("Generated Clipboard.xcodeproj/project.pbxproj")

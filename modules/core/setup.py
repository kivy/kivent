import sys
from os import environ
from os.path import exists, join

import kivy
from Cython.Build import cythonize
from setuptools import Extension, setup

platform = sys.platform

cstdarg = '-std=gnu99'
libraries = ['GL']
extra_compile_args = []
extra_link_args = []
global_include_dirs = []
library_dirs = []

if environ.get('NDKPLATFORM') and environ.get('LIBLINK'):
    platform = 'android'
    libraries = ['GLESv2']
elif environ.get('KIVYIOSROOT'):
    platform = 'ios'
    libraries = ['GLESv2']
    sysroot = environ.get('IOSSDKROOT', environ.get('SDKROOT'))
    global_include_dirs = [sysroot]
    extra_compile_args = ['-isysroot', sysroot]
    extra_link_args = ['-isysroot', sysroot, '-framework', 'OpenGLES']
elif exists('/opt/vc/include/bcm_host.h'):
    platform = 'rpi'
    global_include_dirs = [
        '/opt/vc/include',
        '/opt/vc/include/interface/vcos/pthreads',
        '/opt/vc/include/interface/vmcs_host/linux',
    ]
    library_dirs = ['/opt/vc/lib']
    libraries = ['bcm_host', 'EGL', 'GLESv2']
elif exists('/usr/lib/arm-linux-gnueabihf/libMali.so'):
    platform = 'mali'
    global_include_dirs = ['/usr/include']
    library_dirs = ['/usr/lib/arm-linux-gnueabihf']
    libraries = ['GLESv2']
elif platform == 'win32':
    cstdarg = '-std=gnu99'
    libraries = ['opengl32', 'glu32', 'glew32']
elif platform.startswith('freebsd'):
    localbase = environ.get('LOCALBASE', '/usr/local')
    global_include_dirs = [join(localbase, 'include')]
    extra_link_args = ['-L', join(localbase, 'lib')]
elif platform.startswith('openbsd'):
    global_include_dirs = ['/usr/X11R6/include']
    extra_link_args = ['-L', '/usr/X11R6/lib']
elif platform == 'darwin':
    extra_compile_args = []
    extra_link_args = ['-framework', 'OpenGL', '-framework', 'ApplicationServices']
    libraries = []

do_clear_existing = False

prefixes = {
    'core': 'kivent_core.',
    'memory_handlers': 'kivent_core.memory_handlers.',
    'rendering': 'kivent_core.rendering.',
    'managers': 'kivent_core.managers.',
    'uix': 'kivent_core.uix.',
    'systems': 'kivent_core.systems.',
}

file_prefixes = {
    'core': 'kivent_core/',
    'memory_handlers': 'kivent_core/memory_handlers/',
    'rendering': 'kivent_core/rendering/',
    'managers': 'kivent_core/managers/',
    'uix': 'kivent_core/uix/',
    'systems': 'kivent_core/systems/',
}

modules = {
    'core': ['entity', 'gameworld'],
    'memory_handlers': [
        'block',
        'membuffer',
        'indexing',
        'pool',
        'utils',
        'zone',
        'tests',
        'zonedblock',
    ],
    'rendering': [
        'gl_debug',
        'vertex_format',
        'fixedvbo',
        'cmesh',
        'batching',
        'vertex_format',
        'frame_objects',
        'vertex_formats',
        'model',
        'svg_loader',
        'animation',
    ],
    'managers': [
        'resource_managers',
        'system_manager',
        'entity_manager',
        'sound_manager',
        'game_manager',
        'animation_manager',
    ],
    'uix': ['cwidget', 'gamescreens'],
    'systems': [
        'gamesystem',
        'staticmemgamesystem',
        'position_systems',
        'gameview',
        'scale_systems',
        'rotate_systems',
        'color_systems',
        'gamemap',
        'renderers',
        'lifespan',
        'animation_sys',
    ],
}

core_modules = {}

for name in modules:
    file_prefix = file_prefixes[name]
    prefix = prefixes[name]
    module_files = modules[name]
    for module_name in module_files:
        core_modules[prefix + module_name] = [file_prefix + module_name + '.pyx']


def build_ext(ext_name, files):
    return Extension(
        ext_name,
        files,
        global_include_dirs + kivy.get_includes(),
        extra_compile_args=[cstdarg, '-ffast-math'] + extra_compile_args,
        libraries=libraries,
        extra_link_args=extra_link_args,
        library_dirs=library_dirs,
    )


extensions = []
cymunk_extensions = []
cmdclass = {}


def build_extensions_for_modules_cython(ext_list, modules):
    ext_a = ext_list.append
    for module_name in modules:
        ext = build_ext(module_name, modules[module_name])
        if environ.get('READTHEDOCS', None) == 'True':
            ext.pyrex_directives = {'embedsignature': True}
        ext_a(ext)
    return cythonize(ext_list, compiler_directives={'language_level': '3'})


def build_extensions_for_modules(ext_list, modules):
    ext_a = ext_list.append
    for module_name in modules:
        ext = build_ext(module_name, modules[module_name])
        if environ.get('READTHEDOCS', None) == 'True':
            ext.pyrex_directives = {'embedsignature': True}
        ext_a(ext)
    return ext_list

core_extensions = build_extensions_for_modules_cython(extensions, core_modules)

setup(
    name='KivEnt Core',
    version='3.0.0',
    ext_modules=core_extensions,
    cmdclass=cmdclass,
    packages=[
        'kivent_core',
        'kivent_core.memory_handlers',
        'kivent_core.rendering',
        'kivent_core.managers',
        'kivent_core.systems',
        'kivent_core.uix',
    ],
    package_dir={'kivent_core': 'kivent_core'},
    package_data={
        'kivent_core': [
            '*.pxd',
            'memory_handlers/*.pxd',
            'rendering/*.pxd',
            'managers/*.pxd',
            'systems/*.pxd',
            'uix/*.pxd',
        ]
    },
)

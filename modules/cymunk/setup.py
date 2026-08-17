from os import environ, remove
from os.path import exists, isfile, join

if environ.get('KIVENT_USE_SETUPTOOLS'):
    from setuptools import Extension, setup

    print('Using setuptools')
else:
    from distutils.core import setup
    from distutils.extension import Extension

    print('Using distutils')

try:
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext

    have_cython = True
except ImportError:
    have_cython = False
import sys

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

do_clear_existing = True

import cymunk

cymunk_modules = {
    'kivent_cymunk.physics': [
        'kivent_cymunk/physics.pyx',
    ],
    'kivent_cymunk.interaction': [
        'kivent_cymunk/interaction.pyx',
    ],
}

cymunk_modules_c = {
    'kivent_cymunk.physics': [
        'kivent_cymunk/physics.c',
    ],
    'kivent_cymunk.interaction': [
        'kivent_cymunk/interaction.c',
    ],
}

check_for_removal = [
    'kivent_cymunk/physics.c',
    'kivent_cymunk/interaction.c',
]


def build_ext(ext_name, files):
    return Extension(
        ext_name,
        files,
        global_include_dirs + cymunk.get_includes(),
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


if have_cython:
    if do_clear_existing:
        for file_name in check_for_removal:
            if isfile(file_name):
                remove(file_name)
    cymunk_extensions = build_extensions_for_modules_cython(
        cymunk_extensions, cymunk_modules
    )
else:
    cymunk_extensions = build_extensions_for_modules(
        cymunk_extensions, cymunk_modules_c
    )

setup(
    name='KivEnt Cymunk',
    version='2.0.0',
    description="""A game engine for the Kivy Framework.
        https://github.com/Kovak/KivEnt for more info.""",
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    ext_modules=cymunk_extensions,
    cmdclass=cmdclass,
    packages=['kivent_cymunk'],
    package_dir={'kivent_cymunk': 'kivent_cymunk'},
    package_data={'kivent_cymunk': ['*.pxd']},
)

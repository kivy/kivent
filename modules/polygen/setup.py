from os import environ, remove
from os.path import dirname, join, isfile
from distutils.core import setup
from distutils.extension import Extension
try:
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext
    have_cython = True
except ImportError:
    have_cython = False
import sys

platform = sys.platform
if platform == 'win32':
    cstdarg = '-std=gnu99'
    libraries = ['opengl32', 'glu32','glew32']
else:
    cstdarg = '-std=c99'
    libraries = []

do_clear_existing = True



polygen_modules = {
    'kivent_polygen.renderers': ['kivent_polygen/renderers.pyx',],
    'kivent_polygen.vertex_formats': ['kivent_polygen/vertex_formats.pyx',],
}

polygen_modules_c = {
    'kivent_polygen.renderers': ['kivent_polygen/renderers.c',],
    'kivent_polygen.vertex_formats': ['kivent_polygen/vertex_formats.c',],
}

check_for_removal = [
    'kivent_polygen/vertex_formats.c',
    'kivent_polygen/renderers.c',

    ]

def build_ext(ext_name, files, include_dirs=[]):
    return Extension(ext_name, files, include_dirs,
        extra_compile_args=[cstdarg, '-ffast-math',],
        libraries=libraries)

extensions = []
polygen_extensions = []
cmdclass = {}

def build_extensions_for_modules_cython(ext_list, modules):
    ext_a = ext_list.append
    for module_name in modules:
        ext = build_ext(module_name, modules[module_name])
        if environ.get('READTHEDOCS', None) == 'True':
            ext.pyrex_directives = {'embedsignature': True}
        ext_a(ext)
    return cythonize(ext_list)

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
    polygen_extensions = build_extensions_for_modules_cython(
        polygen_extensions, polygen_modules)
else:
    polygen_extensions = build_extensions_for_modules(polygen_extensions, 
        polygen_modules_c)



setup(
    name='KivEnt Polygen',
    description='''A game engine for the Kivy Framework. 
        https://github.com/Kovak/KivEnt for more info.''',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    ext_modules=polygen_extensions,
    cmdclass=cmdclass,
    packages=[
        'kivent_polygen',
        ],
    package_dir={'kivent_polygen': 'kivent_polygen'})

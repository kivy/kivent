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
else:
    cstdarg = '-std=c99'

do_clear_existing = True



velocity_modules = {
    'velocity_module.velocity': ['velocity_module/velocity.pyx',],
    }

velocity_modules_c = {
    'velocity_module.velocity': ['velocity_module/velocity.c',],
    }

check_for_removal = ['velocity_module/velocity.c',]

def build_ext(ext_name, files, include_dirs=[]):
    return Extension(ext_name, files, include_dirs,
        extra_compile_args=[cstdarg, '-ffast-math',])

extensions = []
velocity_extensions = []
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
    velocity_extensions = build_extensions_for_modules_cython(
        velocity_extensions, velocity_modules)
else:
    velocity_extensions = build_extensions_for_modules(velocity_extensions, 
        velocity_modules_c)


setup(
    name='KivEnt Velocity Module',
    description='''A game engine for the Kivy Framework. 
        https://github.com/Kovak/KivEnt for more info.''',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    ext_modules=velocity_extensions,
    cmdclass=cmdclass,
    packages=[
        'velocity_module',
        ],
    package_dir={'velocity_module': 'velocity_module'})
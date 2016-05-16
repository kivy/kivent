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
import cymunk
print(cymunk.get_includes())

noise_modules = {
    'kivent_projectiles.projectiles': ['kivent_projectiles/projectiles.pyx'], 
    'kivent_projectiles.weapons': ['kivent_projectiles/weapons.pyx'], 
    'kivent_projectiles.combatstats': ['kivent_projectiles/combatstats.pyx'],
    'kivent_projectiles.weapon_ai': ['kivent_projectiles/weapon_ai.pyx'],
}

noise_modules_c = {
    'kivent_projectiles.weapons': ['kivent_projectiles/weapons.c'],
    'kivent_projectiles.projectiles': ['kivent_projectiles/projectiles.c'],
    'kivent_projectiles.combatstats': ['kivent_projectiles/combatstats.c'],
    'kivent_projectiles.weapon_ai': ['kivent_projectiles/weapon_ai.c'],
}

check_for_removal = [
    'kivent_projectiles/weapons.c',
    'kivent_projectiles/projectiles.c',
    'kivent_projectiles/combatstats.c',
    'kivent_projectiles/weapon_ai.c',
    ]



def build_ext(ext_name, files, include_dirs=cymunk.get_includes()):
    return Extension(
        ext_name, files, include_dirs,
        extra_compile_args=[cstdarg, '-ffast-math',],

        )

extensions = []
noise_extensions = []
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
    noise_extensions = build_extensions_for_modules_cython(
        noise_extensions, noise_modules)
else:
    noise_extensions = build_extensions_for_modules(noise_extensions, 
        noise_modules_c)

setup(
    name='KivEnt noise',
    description='''A game engine for the Kivy Framework. 
        https://github.com/Kovak/KivEnt for more info.''',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    ext_modules=noise_extensions,
    cmdclass=cmdclass,
    packages=[
        'kivent_projectiles',
        ],
    package_dir={'kivent_projectiles': 'kivent_projectiles'})
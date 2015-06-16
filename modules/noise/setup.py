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

include_dir = join(dirname(__file__), 'kivent_noise', 'include')

noise_modules = {
    'kivent_noise.noise': ['kivent_noise/noise.pyx', 
    'kivent_noise/src/simplexnoise.cpp'],
}

noise_modules_c = {
    'kivent_noise.noise': ['kivent_noise/noise.c', 
    'kivent_noise/src/simplexnoise.cpp'],
}

check_for_removal = [
    'kivent_noise/noise.c',
    ]



def build_ext(ext_name, files, 
	include_dirs=[include_dir]):
    return Extension(ext_name, files, include_dirs,
        extra_compile_args=[cstdarg, '-ffast-math',],
        language="c++")

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
        'kivent_noise',
        ],
    package_dir={'kivent_noise': 'kivent_noise'})

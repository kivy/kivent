from os import environ, remove
from os.path import dirname, join, isfile
from distutils.core import setup
from distutils.extension import Extension
try:
    from Cython.Distutils import build_ext
    have_cython = True
except ImportError:
    have_cython = False


if have_cython:
    if isfile('kivent/__init__.c'):
        remove('kivent/__init__.c')
    kivent_files = [
    'kivent/__init__.pyx',
        ]
    cmdclass = {'build_ext': build_ext}
else:
    kivent_files = [
	'kivent/__init__.c',
	]
    cmdclass = {}

ext = Extension('kivent',
    kivent_files, include_dirs=[],
    extra_compile_args=['-std=c99', '-ffast-math'])

if environ.get('READTHEDOCS', None) == 'True':
    ext.pyrex_directives = {'embedsignature': True}

setup(
    name='KivEnt',
    description='''A game engine for the Kivy Framework. 
        https://github.com/Kovak/KivEnt for more info.''',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    cmdclass=cmdclass,
    ext_modules=[ext])

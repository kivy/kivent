from os import environ
from os.path import dirname, join
from distutils.core import setup
from distutils.extension import Extension
try:
    from Cython.Distutils import build_ext
    have_cython = True
except ImportError:
    have_cython = False

if have_cython:
    kivyparticle_files = [
    'kivyparticle/__init__.pyx',
        ]
    cmdclass = {'build_ext': build_ext}
else:
    kivyparticle_files = [
	'kivyparticle/__init__.c',
	]
    cmdclass = {}

ext = Extension('kivyparticle',
    kivyparticle_files, include_dirs=[],
    extra_compile_args=['-std=c99', '-ffast-math'])

if environ.get('READTHEDOCS', None) == 'True':
    ext.pyrex_directives = {'embedsignature': True}

setup(
    name='kivyparticle_modules',
    description='particle system designed to work with kivy rendering',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    cmdclass=cmdclass,
    ext_modules=[ext])

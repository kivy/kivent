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
    kivent_cython_files = [
    'kivent_cython/__init__.pyx',
        ]
    cmdclass = {'build_ext': build_ext}
else:
    kivent_cython_files = [
	'kivent_cython/__init__.c',
	]
    cmdclass = {}

ext = Extension('kivent_cython',
    kivent_cython_files, include_dirs=[],
    extra_compile_args=['-std=c99', '-ffast-math'])

if environ.get('READTHEDOCS', None) == 'True':
    ext.pyrex_directives = {'embedsignature': True}

setup(
    name='kivent_cython_modules',
    description='cythonized widgets',
    author='Jacob Kovac',
    author_email='kovac1066@gmail.com',
    cmdclass=cmdclass,
    ext_modules=[ext])

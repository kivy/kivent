import sys
from os import environ

import kivy
from Cython.Build import cythonize
from setuptools import Extension, setup

platform = sys.platform
if platform == "win32":
    cstdarg = "-std=gnu99"
    libraries = ["opengl32", "glu32", "glew32"]
else:
    cstdarg = "-std=c99"
    libraries = []


do_clear_existing = True


particles_modules = {
    "kivent_maps.map_data": [
        "kivent_maps/map_data.pyx",
    ],
    "kivent_maps.map_system": [
        "kivent_maps/map_system.pyx",
    ],
    "kivent_maps.map_manager": [
        "kivent_maps/map_manager.pyx",
    ],
}


def build_ext(ext_name, files):
    return Extension(
        ext_name,
        files,
        kivy.get_includes(),
        extra_compile_args=[cstdarg, "-ffast-math"],
        libraries=libraries,
    )


extensions = []
particles_extensions = []


def build_extensions_for_modules_cython(ext_list, modules):
    ext_a = ext_list.append
    for module_name in modules:
        ext = build_ext(module_name, modules[module_name])
        if environ.get("READTHEDOCS", None) == "True":
            ext.pyrex_directives = {"embedsignature": True}
        ext_a(ext)
    return cythonize(ext_list, compiler_directives={"language_level": "3"})


def build_extensions_for_modules(ext_list, modules):
    ext_a = ext_list.append
    for module_name in modules:
        ext = build_ext(module_name, modules[module_name])
        if environ.get("READTHEDOCS", None) == "True":
            ext.pyrex_directives = {"embedsignature": True}
        ext_a(ext)
    return ext_list


particles_extensions = build_extensions_for_modules_cython(
    particles_extensions, particles_modules
)


setup(
    name="KivEnt maps",
    version="3.0.0",
    ext_modules=particles_extensions,
    packages=["kivent_maps"],
    package_dir={"kivent_maps": "kivent_maps"},
    package_data={"kivent_maps": ["*.pxd"]},
)

import sys
from os import environ
from os.path import exists, join

import kivy
from Cython.Build import cythonize
from setuptools import Extension, setup

platform = sys.platform
cstdarg = "-std=gnu99"
libraries = ["GL"]
extra_compile_args = []
extra_link_args = []
global_include_dirs = []
library_dirs = []

if environ.get("NDKPLATFORM") and environ.get("LIBLINK"):
    platform = "android"
    libraries = ["GLESv2"]
elif environ.get("KIVYIOSROOT"):
    platform = "ios"
    libraries = ["GLESv2"]
    sysroot = environ.get("IOSSDKROOT", environ.get("SDKROOT"))
    global_include_dirs = [sysroot]
    extra_compile_args = ["-isysroot", sysroot]
    extra_link_args = ["-isysroot", sysroot, "-framework", "OpenGLES"]
elif exists("/opt/vc/include/bcm_host.h"):
    platform = "rpi"
    global_include_dirs = [
        "/opt/vc/include",
        "/opt/vc/include/interface/vcos/pthreads",
        "/opt/vc/include/interface/vmcs_host/linux",
    ]
    library_dirs = ["/opt/vc/lib"]
    libraries = ["bcm_host", "EGL", "GLESv2"]
elif exists("/usr/lib/arm-linux-gnueabihf/libMali.so"):
    platform = "mali"
    global_include_dirs = ["/usr/include"]
    library_dirs = ["/usr/lib/arm-linux-gnueabihf"]
    libraries = ["GLESv2"]
elif platform == "win32":
    cstdarg = "-std=gnu99"
    libraries = ["opengl32", "glu32", "glew32"]
elif platform.startswith("freebsd"):
    localbase = environ.get("LOCALBASE", "/usr/local")
    global_include_dirs = [join(localbase, "include")]
    extra_link_args = ["-L", join(localbase, "lib")]
elif platform.startswith("openbsd"):
    global_include_dirs = ["/usr/X11R6/include"]
    extra_link_args = ["-L", "/usr/X11R6/lib"]
elif platform == "darwin":
    extra_compile_args = []
    extra_link_args = ["-framework", "OpenGL", "-framework", "ApplicationServices"]
    libraries = []

do_clear_existing = True

particles_modules = {
    "kivent_particles.particle": ["kivent_particles/particle.pyx"],
    "kivent_particles.emitter": [
        "kivent_particles/emitter.pyx",
    ],
    "kivent_particles.particle_formats": [
        "kivent_particles/particle_formats.pyx",
    ],
    "kivent_particles.particle_renderers": [
        "kivent_particles/particle_renderers.pyx",
    ],
}


def build_ext(ext_name, files):
    return Extension(
        ext_name,
        files,
        global_include_dirs + kivy.get_includes(),
        extra_compile_args=[cstdarg, "-ffast-math"] + extra_compile_args,
        libraries=libraries,
        extra_link_args=extra_link_args,
        library_dirs=library_dirs,
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
    name="KivEnt particles",
    version="2.0.0",
    ext_modules=particles_extensions,
    packages=[
        "kivent_particles",
    ],
    package_dir={"kivent_particles": "kivent_particles"},
    package_data={"kivent_particles": ["*.pxd"]},
)

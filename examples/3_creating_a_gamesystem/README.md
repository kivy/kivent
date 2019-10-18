# Creating a GameSystem

This example shows how to create a KivEnt gamesystem.

To run the main_with_cython.py example, first cythonize the velocity module:

```
$ cythonize -a -i ./velocity_module/velocity.pyx
```

This will create shared object files alongside the cython source, which python
can import directly. Then run the example as usual:

```
$ python ./main_with_cython.py
```


# casadi-matlab-bindings
Repo to build the CasADi MATLAB bindings as a standalone project, against an already compiled CasADi library.

**If you are just interested in using CasADi in MATLAB, please follow the official instructions at https://web.casadi.org/get/.**

This repo is only useful if for any need to compile the MATLAB extension against a CasADi library that is already in your system, for example
if you are also using CasADi or its dependendencies in other software that is loaded by MATLAB, and you want to avoid ABI incompatibilities.

## Usage

How to use this repo

1. Install CasADi in your system, and make sure that it can be find by CMake.

2. Clone the repository

~~~
git clone https://github.com/ami-iit/casadi-matlab-bindings.git
~~~

3. Build it

~~~
cd casadi-matlab-bindings
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=<install-prefix> ..
cmake --build . --config Release
cmake --install . --config Release
~~~

4. Use it

Add the `<install-prefix>/mex` directory to the MATLAB path.

## License

Materials in this repository are distributed under the following license:

> All software is licensed under the MIT License. See [LICENSE](./LICENSE) file for details.

## FAQ

### How the version is chosen?

The version of this project is chosen in accordance of the original project, plus a fourth version that describes if several version of this repo are released, for example the version `x.y.z.t` is the one corresponding to the `x.y.z` version of casadi, while `t` is the number that can be
increased if changes are done to the `casadi-matlab-bindings` project.
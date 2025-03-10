![ZIG](https://ziglang.org/zig-logo.svg)

Zig is an open-source programming language designed for **robustness**,
**optimality**, and **maintainability**.

## Resources

 * [Introduction](https://ziglang.org/#Introduction)
 * [Download & Documentation](https://ziglang.org/download)
 * [Community](https://github.com/ziglang/zig/wiki/Community)
 * [Contributing](https://github.com/ziglang/zig/blob/master/CONTRIBUTING.md)
 * [Frequently Asked Questions](https://github.com/ziglang/zig/wiki/FAQ)

## Building from Source

[![Build Status](https://dev.azure.com/ziglang/zig/_apis/build/status/ziglang.zig?branchName=master)](https://dev.azure.com/ziglang/zig/_build/latest?definitionId=1&branchName=master)

Note that you can
[download a binary of master branch](https://ziglang.org/download/#release-master).

### Stage 1: Build Zig from C++ Source Code

#### Dependencies

##### POSIX

 * cmake >= 2.8.5
 * gcc >= 5.0.0 or clang >= 3.6.0
 * LLVM, Clang, LLD development libraries == 8.x, compiled with the same gcc or clang version above
   - Use the system package manager, or [build from source](https://github.com/ziglang/zig/wiki/How-to-build-LLVM,-libclang,-and-liblld-from-source#posix).

##### Windows

 * cmake >= 2.8.5
 * Microsoft Visual Studio 2017 (version 15.8)
 * LLVM, Clang, LLD development libraries == 8.x, compiled with the same MSVC version above
   - Use the [pre-built binaries](https://github.com/ziglang/zig/wiki/How-to-build-LLVM,-libclang,-and-liblld-from-source#pre-built-binaries) or [build from source](https://github.com/ziglang/zig/wiki/How-to-build-LLVM,-libclang,-and-liblld-from-source#windows).

#### Instructions

##### POSIX

```
mkdir build
cd build
cmake ..
make install
```

##### MacOS

```
brew install cmake llvm@8
brew outdated llvm@8 || brew upgrade llvm@8
mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=/usr/local/Cellar/llvm/8.0.0_1
make install
```

##### Windows

See https://github.com/ziglang/zig/wiki/Building-Zig-on-Windows

### Stage 2: Build Self-Hosted Zig from Zig Source Code

*Note: Stage 2 compiler is not complete. Beta users of Zig should use the
Stage 1 compiler for now.*

Dependencies are the same as Stage 1, except now you can use stage 1 to compile
Zig code.

```
bin/zig build --build-file ../build.zig --prefix $(pwd)/stage2 install
```

This produces `./stage2/bin/zig` which can be used for testing and development.
Once it is feature complete, it will be used to build stage 3 - the final compiler
binary.

### Stage 3: Rebuild Self-Hosted Zig Using the Self-Hosted Compiler

*Note: Stage 2 compiler is not yet able to build Stage 3. Building Stage 3 is
not yet supported.*

Once the self-hosted compiler can build itself, this will be the actual
compiler binary that we will install to the system. Until then, users should
use stage 1.

#### Debug / Development Build

```
./stage2/bin/zig build --build-file ../build.zig --prefix $(pwd)/stage3 install
```

#### Release / Install Build

```
./stage2/bin/zig build --build-file ../build.zig install -Drelease-fast
```

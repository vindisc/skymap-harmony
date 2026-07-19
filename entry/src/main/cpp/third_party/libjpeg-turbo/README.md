# libjpeg-turbo 3.0.4 for HarmonyOS arm64

This directory contains the public libjpeg headers and a position-independent
`arm64-v8a` static library compiled from the official libjpeg-turbo 3.0.4
release source.

- Source: `https://github.com/libjpeg-turbo/libjpeg-turbo/releases/tag/3.0.4`
- Source archive SHA-256: `99130559e7d62e8d695f2c0eaeef912c5828d5b84a0537dcb24c9678c9d5b76b`
- Static library SHA-256: `821b8d13df892ca578e7fab4c51446fbd3965667debe923f19e1f5f56d54e837`
- Toolchain: HarmonyOS 6.1.1(24) clang 15.0.4
- ABI: `arm64-v8a`
- STL: `c++_shared`
- SIMD: disabled for the Phase 1 portability PoC
- TurboJPEG API: disabled; only the libjpeg API static library is included

The upstream CMake build explicitly rejects `add_subdirectory()` integration.
The static library is therefore built as a standalone upstream project and
imported by the application CMake project without modifying upstream sources.

Build configuration:

```text
-DOHOS_ARCH=arm64-v8a
-DOHOS_STL=c++_shared
-DENABLE_SHARED=OFF
-DENABLE_STATIC=ON
-DWITH_TURBOJPEG=OFF
-DWITH_SIMD=OFF
-DWITH_JAVA=OFF
-DCMAKE_POSITION_INDEPENDENT_CODE=ON
-DCMAKE_BUILD_TYPE=Release
```

Licensing is retained in `LICENSE.md` and `README.ijg`. A copy of `LICENSE.md`
is also packaged in the HAP at
`rawfile/licenses/libjpeg-turbo-LICENSE.md`. This software is based in part on
the work of the Independent JPEG Group.

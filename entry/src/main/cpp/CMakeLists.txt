cmake_minimum_required(VERSION 3.5.0)
project(jpeg_encoder)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT OHOS_ARCH STREQUAL "arm64-v8a")
  message(FATAL_ERROR "jpeg_encoder PoC currently supports only OHOS_ARCH=arm64-v8a")
endif()

set(LIBJPEG_TURBO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/third_party/libjpeg-turbo)

add_library(jpeg_turbo_prebuilt STATIC IMPORTED)
set_target_properties(jpeg_turbo_prebuilt PROPERTIES
  IMPORTED_LOCATION ${LIBJPEG_TURBO_ROOT}/lib/${OHOS_ARCH}/libjpeg.a
  INTERFACE_INCLUDE_DIRECTORIES ${LIBJPEG_TURBO_ROOT}/include
)

add_library(jpeg_encoder SHARED
  napi_bridge.cpp
  jpeg_scanline_encoder.cpp
)

target_include_directories(jpeg_encoder PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_options(jpeg_encoder PRIVATE
  -Wall
  -Wextra
)

target_link_libraries(jpeg_encoder PUBLIC
  jpeg_turbo_prebuilt
  libace_napi.z.so
)

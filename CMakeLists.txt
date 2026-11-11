# =============================================================================
# Wacky Wheels - static recompilation host (64-bit, clang-cl)
#
#   py -3 run_lift.py        # -> src/recomp/gen/ (from game/WW.EXE)
#   build.cmd                # -> build/wackywheels.exe
# =============================================================================
cmake_minimum_required(VERSION 3.20)
project(wackywheels C)

set(PCRECOMP ${CMAKE_SOURCE_DIR}/../pcrecomp CACHE PATH "pcrecomp checkout")
if(NOT EXISTS ${PCRECOMP}/runtime/dos32/dos32.c)
  message(FATAL_ERROR "pcrecomp at ${PCRECOMP} has no runtime/dos32; set -DPCRECOMP=")
endif()
file(GLOB GEN ${CMAKE_SOURCE_DIR}/src/recomp/gen/recomp_*.c)
if(NOT GEN)
  message(FATAL_ERROR "src/recomp/gen is empty: run `py -3 run_lift.py` first")
endif()

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
add_executable(wackywheels ${GEN} src/recomp/gen/image_data.c
  ${PCRECOMP}/runtime/dos32/dos32.c src/runtime/main.c)
target_include_directories(wackywheels PRIVATE src/recomp/gen
  ${PCRECOMP}/runtime/dos32 ${PCRECOMP}/runtime/recomp32)
target_compile_definitions(wackywheels PRIVATE _CRT_SECURE_NO_WARNINGS RECOMP_YIELD_EVERY=256u RECOMP_DOS32_VGA)
set_source_files_properties(${GEN} src/recomp/gen/image_data.c PROPERTIES
  COMPILE_OPTIONS "/w;-fno-strict-aliasing;-fwrapv;/O1")
target_link_libraries(wackywheels PRIVATE winmm user32 gdi32)

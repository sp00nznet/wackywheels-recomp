#!/bin/sh
# Linux and macOS: not yet. The host (src/runtime/main.c) is a Win32 window on
# pcrecomp's dos32, and nobody has built it with clang-cl/lld or mingw or run
# it under Wine. Setup.cmd on Windows is the only tested route (ROADMAP.md).
echo "Wacky Wheels recomp: there is no Linux or macOS build yet."
echo "Use Setup.cmd on Windows; ROADMAP.md tracks the port."
exit 1

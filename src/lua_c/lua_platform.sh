#!/bin/sh
# Prints the Lua 5.1 Makefile platform target for the build host.
#
# The target is chosen from the operating system, not from OCaml's
# %{system}: that value describes the native code backend and can be
# "elf", "linux_elf", "linux_eabihf"... on Linux (ppc64le, s390x, i686,
# arm32), names that Lua's Makefile does not know.

case "$(uname -s)" in
  Linux) echo linux ;;
  Darwin) echo macosx ;;
  FreeBSD) echo freebsd ;;
  OpenBSD) echo openbsd ;;
  NetBSD | DragonFly) echo bsd ;;
  SunOS) echo solaris ;;
  *) echo posix ;;
esac

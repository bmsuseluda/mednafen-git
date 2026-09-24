AUTOMAKE_OPTIONS = subdir-objects
DEFS = -DLOCALEDIR=\"$(localedir)\" @DEFS@  @SDL_CFLAGS@
DEFAULT_INCLUDES = -I$(top_builddir)/include -I$(top_srcdir)/include -I$(top_builddir)/intl

noinst_LIBRARIES	=	libmdfnsdl.a

libmdfnsdl_a_SOURCES = main.cpp args.cpp help.cpp ers.cpp sound.cpp netplay.cpp

libmdfnsdl_a_SOURCES += input.cpp mouse.cpp keyboard.cpp
libmdfnsdl_a_SOURCES += Joystick.cpp Joystick_SDL.cpp

libmdfnsdl_a_SOURCES += TextEntry.cpp console.cpp cheat.cpp fps.cpp video-state.cpp remote.cpp rmdui.cpp

libmdfnsdl_a_SOURCES += opengl.cpp shader.cpp nongl.cpp nnx.cpp video.cpp

if WANT_FANCY_SCALERS
libmdfnsdl_a_SOURCES += hqxx-common.cpp hq2x.cpp hq3x.cpp hq4x.cpp scale2x.c scale3x.c scalebit.c 2xSaI.cpp
endif

if WANT_DEBUGGER
libmdfnsdl_a_SOURCES += debugger.cpp gfxdebugger.cpp memdebugger.cpp logdebugger.cpp prompt.cpp
endif

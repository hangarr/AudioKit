# Makefile to build a position independent library for Soundpipe
# The fft, kissfft, and inih libs had their own Makefiles,
# we pull those into a config.def.mk file

.PHONY: all clean install

default: all

# Build for Soundpipe in AudioKit 5

VERSION = 5.0

# Soundpipe source directory and the system target directory

INTERMEDIATES_PREFIX ?= .
PREFIX ?= /usr/local

# artifacts

LIBSOUNDPIPESO = $(INTERMEDIATES_PREFIX)/libsoundpipe.so
LIBSOUNDPIPE = $(INTERMEDIATES_PREFIX)/libsoundpipe.a
SOUNDPIPEO = $(INTERMEDIATES_PREFIX)/soundpipe.o

# source modules and source library directories

MODDIR = $(INTERMEDIATES_PREFIX)/modules
LIBDIR = $(INTERMEDIATES_PREFIX)/lib
INCDIR = $(INTERMEDIATES_PREFIX)/include

ifndef CONFIG
CONFIG = $(INTERMEDIATES_PREFIX)/config.mk
endif

# paths to standalone C source modules and the objects built from them

CPATHS += $(addprefix modules/, $(addsuffix .c, $(MODULES)))
MPATHS += $(addprefix $(MODDIR)/, $(addsuffix .o, $(MODULES)))

include $(CONFIG)

# optionally build library for C double data type rather than C float data type

ifeq ($(USE_DOUBLE), 1)
CFLAGS+=-DUSE_DOUBLE
SPFLOAT=double
else
SPFLOAT=float
endif

# C compiler flag must include -fPIC option to generate shared object library

CFLAGS += -DSP_VERSION=$(VERSION) -O3 -DSPFLOAT=${SPFLOAT} -std=c99
CFLAGS += -Iinclude -I/usr/local/include -fPIC

# this shouldn’t do anything but create any needed folders if needed

$(INTERMEDIATES_PREFIX) \
$(INTERMEDIATES_PREFIX)/modules \
$(PREFIX)/include \
$(PREFIX)/lib:
	mkdir -p $@

$(LIBSOUNDPIPESO): $(LIBSOUNDPIPE)
	$(CC) -shared -o $@ $(MPATHS) $(LPATHS)

$(LIBSOUNDPIPE): $(MPATHS) $(LPATHS) | $(INTERMEDIATES_PREFIX)
	$(AR) rcs $@ $(MPATHS) $(LPATHS)

$(SOUNDPIPEO): $(MPATHS) $(LPATHS) | $(INTERMEDIATES_PREFIX)
	$(CC) $(CFLAGS) -c -combine $(CPATHS) -o $@


# this should cause the Makefiles in the lib/ folder to be invoked

$(INTERMEDIATES_PREFIX)/config.mk: config.def.mk | $(INTERMEDIATES_PREFIX)
	cp $< $@

$(MODDIR)/%.o: $(MODDIR)/%.c $(INCDIR)/soundpipe.h | $(MODDIR)
	$(CC) -Wall $(CFLAGS) -c -static $< -o $@

# Build the single test program

TESTDIR = $(INTERMEDIATES_PREFIX)/test
$(TESTDIR)/%.o: $(TESTDIR)/%.c $(TESTDIR)/%.h $(INCDIR)/soundpipe.h | $(TESTDIR)
	$(CC) -Wall $(CFLAGS) -Itest -c $< -o $@

$(TESTDIR)/test: $(TESTDIR)/test.o $(TESTDIR)/md5.o | $(TESTDIR)
	$(CC) $(TESTDIR)/test.o $(TESTDIR)/md5.o -o $@

# Build the full configuration file and the Soundpipe library

all: $(INTERMEDIATES_PREFIX)/config.mk \
	$(LIBSOUNDPIPESO)
#	$(LIBSOUNDPIPESO) \
#	$(TESTDIR)/test


install: \
	$(LIBSOUNDPIPESO) | \
		$(PREFIX)/include \
		$(PREFIX)/lib
	install $(INCDIR)/soundpipe.h $(PREFIX)/include/
	install $(LIBSOUNDPIPESO) $(PREFIX)/lib/

clean:
	rm -rf $(INTERMEDIATES_PREFIX)/libsoundpipe.so
	rm -rf $(INTERMEDIATES_PREFIX)/libsoundpipe.a
	rm -rf $(LPATHS)
	rm -rf $(MPATHS)
	rm -rf $(TESTDIR)/*.o
	rm -rf $(TESTDIR)/test




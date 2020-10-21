# ==== Modified for Soundpipe 5.0 ====
# Modules that don't require external libraries go here
MODULES= \
base \
ftbl \
tevent \
adsr \
allpass \
atone \
autowah \
bal \
bar \
biquad \
biscale \
blsaw \
blsquare \
bltriangle \
fold \
bitcrush \
butbp \
butbr \
buthp \
butlp \
clip \
clock \
comb \
compressor \
count \
conv \
crossfade \
dcblock \
delay \
dist \
dmetro \
drip \
dtrig \
dust \
eqfil \
expon \
fof \
fog \
fofilt \
foo \
fosc \
gbuzz \
hilbert \
in \
incr \
jcrev \
jitter \
line \
lpf18 \
maygate \
metro \
mincer \
mode \
moogladder \
noise \
nsmp \
osc \
oscmorph \
pan2 \
panst \
pareq \
paulstretch \
pdhalf \
peaklim \
phaser \
phasor \
pinknoise \
pitchamdf \
pluck \
port \
posc3 \
progress \
prop \
pshift \
ptrack \
randh \
randi \
randmt \
random \
reverse \
reson \
revsc \
rms \
rpt \
saturator \
samphold \
scale \
scrambler \
sdelay \
slice \
smoothdelay \
streson \
switch \
tabread \
tadsr \
tblrec \
tbvcf \
tdiv \
tenv \
tenv2 \
tenvx \
tgate \
thresh \
timer \
tin \
tone \
trand \
tseg \
tseq \
vdelay \
vocoder \
waveset \
wpkorg35 \
zitarev

# —-vv—- added for Soundpipe 5.0 —-vv—-
# Note:  fftwrapper and padsynth added manually below

MODULES += \
brown \
clamp \
diode \
oscmorph2d \
rspline \
sndwarp \
talkbox \
voc \
wavin \
wavout

# ——^^—- added for Soundpipe 5.0 —-^^-—

# —-vv—- added for Soundpipe 5.0 —-vv—-

LPATHS += $(LIBDIR)/dr_wav/dr_wav.o

$(LIBDIR)/dr_wav/dr_wav.o: $(LIBDIR)/dr_wav/dr_wav.c | $(LIBDIR)/dr_wav
	$(CC) $< -c $(CFLAGS) -o $@

# ——^^—- added for Soundpipe 5.0 —-^^-—

# Sound file management (Remove for Soundpipe 5.0)
#ifndef NO_LIBSNDFILE
#	MODULES += diskin
#else
#	CFLAGS += -DNO_LIBSNDFILE
#endif

# ——vv—- Added for Soundpipe 5.0 —-vv-—

CFLAGS += -DNO_LIBSNDFILE

# ——^^—- Added for Soundpipe 5.0 —-^^-—

# ini parser needed for nsmp module (Replace for Soundpipe 5.0)
#include lib/inih/Makefile

# ——vv—- Contents of inih Makefile for Soundpipe 5.0 —-vv-—

LPATHS += $(LIBDIR)/inih/ini.o
CFLAGS += -Ilib/inih/

$(LIBDIR)/inih/ini.o: lib/inih/ini.c | $(LIBDIR)/inih
	$(CC) $(CFLAGS) $< -c -o $@

# ——^^—- Contents of inih Makefile for Soundpipe 5.0 —-^^-—

# Header files needed for modules generated with FAUST
# Somehow this is the CUI.h file
#CFLAGS += -Ilib/faust

# ——vv—- Include for Soundpipe 5.0 —-vv-—
# This is the CUI.h file now found in the MODULES folder

CFLAGS += -Imodules

# ——^^—- Include for Soundpipe 5.0 —-^^-—

# fft library (Replace for Soundpipe 5.0)
#include lib/fft/Makefile

# ——vv—- Contents of fft Makefile for Soundpipe 5.0 —-vv-—

LPATHS += $(LIBDIR)/fft/fft.o

$(LIBDIR)/fft/fft.o: $(LIBDIR)/fft/fft.c | $(LIBDIR)/fft
	$(CC) $< -c $(CFLAGS) -o $@

# ——^^—- Contents of fft Makefile for Soundpipe 5.0 —-^^-—

# JACK module
#
#MODULES += jack
#CFLAGS += -ljack

# RPi Module
#
#MODULES += rpi
#CFLAGS += -lasound

#include lib/kissfft/Makefile (Replace for Soundpipe 5.0)

# ——vv—- Contents of kissfft Makefile for Soundpipe 5.0 —-vv-—

LPATHS += $(LIBDIR)/kissfft/kiss_fft.o $(LIBDIR)/kissfft/kiss_fftr.o
CFLAGS += -Ilib/kissfft/ -Dkiss_fft_scalar=$(SPFLOAT)


$(LIBDIR)/kissfft/kiss_fft.o: lib/kissfft/kiss_fft.c | $(LIBDIR)/kissfft
	$(CC) $< -c $(CFLAGS) -o $@

$(LIBDIR)/kissfft/kiss_fftr.o: lib/kissfft/kiss_fftr.c | $(LIBDIR)/kissfft
	$(CC) $< -c $(CFLAGS) -o $@

# ——^^—- Contents of kissfft Makefile for Soundpipe 5.0 —-^^-—

MODULES += fftwrapper
MODULES += padsynth

# Uncomment to use FFTW3 instead of kissfft.
# CFLAGS += -lfftw3 -DUSE_FFTW3

# Soundpipe audio (Delete for Soundpipe 5.0)
#include lib/spa/Makefile
#CFLAGS += -DUSE_SPA

CFLAGS += -fPIC -g

# Uncomment this to use double precision
#USE_DOUBLE=1
COMPONENT=TestMTAAppC

APPDIR = $(TOSROOT)/../Projects/tOR/MTA
UTILDIR = $(TOSROOT)/../Programming/TinyOS/Utils
CFLAGS += -I$(APPDIR) \
	-I$(APPDIR)/Interfaces \
	-I$(APPDIR)/4bitle_old \
	-I$(UTILDIR)
CFLAGS += -DCC2420_DEF_RFPOWER=3	#neteye 3, motelab 23, Indriya 11

CFLAGS += -DTOSH_DATA_LENGTH=114
CFLAGS += -DCC2420_DEF_CHANNEL=26
#PFLAGS += -DTIMESYNC_RATE=3
#enable snooping
CFLAGS+=-DCC2420_NO_ADDRESS_RECOGNITION

#BUILD_EXTRA_DEPS	+= IndriyaSerial.class
#CLEAN_EXTRA			= *.class .java

#IndriyaSerial.class: $(wildcard *.java) IndriyaSerialMsg.java
#	javac -source 1.4 -target 1.4 *.java

#IndriyaSerialMsg.java:	TestMTA.h
#	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=IndriyaSerialMsg TestMTA.h indriya_serial -o $@

TestMTAMsg.py: TestMTA.h
mig python -python-classname=$(@:.py=) $< indriya_serial -o $@

include $(MAKERULES)

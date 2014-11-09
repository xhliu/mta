#include "TestMTA.h"

configuration TestMTAAppC {}
implementation {
  components TestMTAC as App, MainC, LedsC, ActiveMessageC;
  components CollectionC as Collector;
  components new CollectionSenderC(0xee);
  components new TimerMilliC();

    components  UartLogC;
    App.UartLog -> UartLogC;

  App.Boot -> MainC;
  App.RadioControl -> ActiveMessageC;
  App.RoutingControl -> Collector;
  App.Leds -> LedsC;
  App.Timer -> TimerMilliC;
  App.Send -> CollectionSenderC;
  App.RootControl -> Collector;
  App.Receive -> Collector.Receive[0xee];
  App.Intercept -> Collector.Intercept[0xee];
  //MTE error
  //App.RoutingTable -> Collector;

	components DummyGlobalTimerC;
    App.GlobalTimer -> DummyGlobalTimerC;

    components RandomC;
    App.Random -> RandomC;
#ifndef TOSSIM    
    components TimeSyncMessageC;
    App.TimeSyncReceive -> TimeSyncMessageC.Receive[AM_TYPE_SYNC];
    App.TimeSyncPacket -> TimeSyncMessageC.TimeSyncPacketMilli;
    App.Packet -> TimeSyncMessageC;
#endif
    components LocalTimeMilliC;
    App.LocalTime -> LocalTimeMilliC;
    
	//event traffic
	components SerialActiveMessageC as UartSender;
	components new SerialAMReceiverC(SERIAL_AM_TYPE) as UartReceiver;
	App.UartReceive -> UartReceiver.Receive;
	App.UartControl -> UartSender;
}


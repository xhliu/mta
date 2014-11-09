#include "Commander.h"

configuration CommanderC {}
implementation {
  components MainC, CommanderP as App;    // UartLogC;
  components TimeSyncMessageC;
  components LocalTimeMilliC;
  components new TimerMilliC();
//  components UartLogC;
  
  App.Boot -> MainC.Boot;
  
  App.AMSend -> TimeSyncMessageC.TimeSyncAMSendMilli[AM_TYPE_SYNC];
  App.AMControl -> TimeSyncMessageC;
  
  App.LocalTime -> LocalTimeMilliC;
  
  App.MilliTimer -> TimerMilliC;
  
//  App.UartLog -> UartLogC;
}



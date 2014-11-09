module DummyGlobalTimerC {
	provides {
		interface GlobalTimer;
	}
}

implementation{

    
    //snapshot of the global & local timer
    //command void GlobalTimer.sync(uint32_t local_time_, uint32_t global_time_) {
    command void GlobalTimer.sync(uint16_t sync_seqno, uint32_t local_time, uint32_t last_global_time) {
        return ;
    }


    //get local global time
    command error_t GlobalTimer.getGlobalTime(uint32_t *_time) {
        return 0;
    }
    

        //convert the local time to the corresponding global time
    command error_t GlobalTimer.local2Global(uint32_t *local_time) {
        return 0;
    }

}

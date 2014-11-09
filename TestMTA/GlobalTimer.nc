interface GlobalTimer {
    //sync local global time w/ root
    //command void setGlobalTimer(uint32_t GlobalTimer);
    //snapshot of the global & local timer
    command void sync(uint16_t sync_seqno, uint32_t local_time, uint32_t last_global_time);
    
    //get local global time
    command error_t getGlobalTime(uint32_t *_time);
    
    //convert the local time to the corresponding global time
    command error_t local2Global(uint32_t *);
}

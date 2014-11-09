interface DataPanel {
    command uint8_t queueSize(uint8_t *);
    command void getTxPktTime(uint32_t *, uint32_t *);
}

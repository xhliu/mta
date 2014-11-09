#ifndef COLLECTION_H
#define COLLECTION_H

enum {
    AM_COLLECTION_DATA = 20,
    AM_COLLECTION_CONTROL = 21,
    AM_COLLECTION_DEBUG = 22,
};

typedef uint8_t collection_id_t;
typedef nx_uint8_t nx_collection_id_t;

#endif

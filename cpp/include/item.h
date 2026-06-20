#pragma once

#include <stdint.h>
#include <string.h>

// Fixed-size lengths must stay in sync with the Dart FFI counterpart in
// lib/services/inventory_ffi_service.dart.
#define ITEM_ID_LEN          64
#define ITEM_BARCODE_LEN     64
#define ITEM_NAME_LEN       256
#define ITEM_CATEGORY_LEN   128
#define ITEM_DESC_LEN       512

// Sort-field codes (keep in sync with SortField enum in Dart).
typedef enum {
    SORT_NAME       = 0,
    SORT_CATEGORY   = 1,
    SORT_QUANTITY   = 2,
    SORT_PRICE      = 3,
    SORT_DATE_ADDED = 4,
    SORT_BARCODE    = 5
} SortField;

// Match-type codes (keep in sync with MatchType enum in Dart).
typedef enum {
    MATCH_EXACT_BARCODE    = 0,
    MATCH_CATEGORY         = 1,
    MATCH_NAME_CONTAINS    = 2,
    MATCH_NAME_STARTS_WITH = 3
} MatchType;

// POD struct shared between C++ and Dart via FFI.
// #pragma pack(push,1) ensures no compiler-inserted padding so the Dart
// Struct layout matches exactly.
#pragma pack(push, 1)
typedef struct {
    char    id[ITEM_ID_LEN];
    char    barcode[ITEM_BARCODE_LEN];
    char    name[ITEM_NAME_LEN];
    char    category[ITEM_CATEGORY_LEN];
    char    description[ITEM_DESC_LEN];
    double  price;           // 8 bytes
    int64_t date_added;      // Unix ms timestamp, 8 bytes
    int32_t quantity;        // 4 bytes
    int32_t _pad;            // keep total size a multiple of 8
} CItem;
#pragma pack(pop)

// A single auto-add rule for a custom list.
#pragma pack(push, 1)
typedef struct {
    char    list_id[ITEM_ID_LEN];
    char    value[ITEM_NAME_LEN];   // pattern to match against
    int32_t match_type;             // one of MatchType
    int32_t _pad;
} CRule;
#pragma pack(pop)

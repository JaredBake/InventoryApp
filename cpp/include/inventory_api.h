#pragma once

#include "item.h"

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#  define INVENTORY_EXPORT __declspec(dllexport)
#else
#  define INVENTORY_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

// ---------------------------------------------------------------------------
// Sorting
// ---------------------------------------------------------------------------

// Sort `items` array of `count` elements in-place.
// sort_field : one of SortField enum values
// ascending  : 1 = ascending, 0 = descending
INVENTORY_EXPORT void inventory_sort_items(
    CItem*  items,
    int32_t count,
    int32_t sort_field,
    int32_t ascending
);

// ---------------------------------------------------------------------------
// Filtering
// ---------------------------------------------------------------------------

// Fill `out_indices` (pre-allocated by caller, capacity = count) with the
// indices of items that match `query` (substring, case-insensitive) AND
// `category` (exact, case-insensitive; ignored when empty string).
// Returns the number of matching items written to out_indices.
INVENTORY_EXPORT int32_t inventory_filter_items(
    const CItem* items,
    int32_t      count,
    const char*  query,
    const char*  category,
    int32_t*     out_indices
);

// ---------------------------------------------------------------------------
// Custom-list rule matching
// ---------------------------------------------------------------------------

// Check item against each rule in the `rules` array.
// out_list_ids : caller-allocated buffer of `rule_count * ITEM_ID_LEN` bytes.
//                Each matching list_id is written as a null-terminated string
//                in its own ITEM_ID_LEN-byte slot.
// Returns the number of matched lists.
INVENTORY_EXPORT int32_t inventory_match_lists(
    const CItem* item,
    const CRule* rules,
    int32_t      rule_count,
    char*        out_list_ids
);

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

INVENTORY_EXPORT const char* inventory_version(void);

#ifdef __cplusplus
}  // extern "C"
#endif

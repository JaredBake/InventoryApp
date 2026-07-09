#include "inventory_api.h"

#include <algorithm>
#include <cctype>
#include <cstring>
#include <string>

// ── helpers ─────────────────────────────────────────────────────────────────

static std::string to_lower(const char* s) {
    std::string out(s);
    std::transform(out.begin(), out.end(), out.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return out;
}

static void copy_truncated(char* dest, size_t dest_len, const char* src) {
    if (!dest || dest_len == 0) return;
    if (!src) {
        dest[0] = '\0';
        return;
    }

#if defined(_MSC_VER)
    strncpy_s(dest, dest_len, src, _TRUNCATE);
#else
    std::strncpy(dest, src, dest_len - 1);
    dest[dest_len - 1] = '\0';
#endif
}

static bool contains_ci(const char* haystack, const char* needle) {
    return to_lower(haystack).find(to_lower(needle)) != std::string::npos;
}

static bool starts_with_ci(const char* str, const char* prefix) {
    std::string s = to_lower(str);
    std::string p = to_lower(prefix);
    return s.rfind(p, 0) == 0;
}

static bool equal_ci(const char* a, const char* b) {
    return to_lower(a) == to_lower(b);
}

// ── sorting ──────────────────────────────────────────────────────────────────

void inventory_sort_items(CItem* items, int32_t count,
                          int32_t sort_field, int32_t ascending) {
    if (!items || count <= 1) return;

    auto cmp = [sort_field, ascending](const CItem& a, const CItem& b) -> bool {
        bool less_than = false;
        switch (sort_field) {
            case SORT_NAME:
                less_than = to_lower(a.name) < to_lower(b.name);
                break;
            case SORT_CATEGORY:
                less_than = to_lower(a.category) < to_lower(b.category);
                break;
            case SORT_QUANTITY:
                less_than = a.quantity < b.quantity;
                break;
            case SORT_PRICE:
                less_than = a.price < b.price;
                break;
            case SORT_DATE_ADDED:
                less_than = a.date_added < b.date_added;
                break;
            case SORT_BARCODE:
                less_than = to_lower(a.barcode) < to_lower(b.barcode);
                break;
            default:
                less_than = to_lower(a.name) < to_lower(b.name);
                break;
        }
        if (ascending) {
            return less_than;
        }

        switch (sort_field) {
            case SORT_NAME:
                return to_lower(a.name) > to_lower(b.name);
            case SORT_CATEGORY:
                return to_lower(a.category) > to_lower(b.category);
            case SORT_QUANTITY:
                return a.quantity > b.quantity;
            case SORT_PRICE:
                return a.price > b.price;
            case SORT_DATE_ADDED:
                return a.date_added > b.date_added;
            case SORT_BARCODE:
                return to_lower(a.barcode) > to_lower(b.barcode);
            default:
                return to_lower(a.name) > to_lower(b.name);
        }
    };

    std::sort(items, items + count, cmp);
}

// ── filtering ────────────────────────────────────────────────────────────────

int32_t inventory_filter_items(const CItem* items, int32_t count,
                                const char*  query,    const char* category,
                                int32_t*     out_indices) {
    if (!items || !out_indices) return 0;

    bool has_query    = query    && query[0]    != '\0';
    bool has_category = category && category[0] != '\0';

    int32_t n = 0;
    for (int32_t i = 0; i < count; ++i) {
        const CItem& item = items[i];
        bool matches = true;

        if (has_query) {
            // query matches name, barcode, or description
            matches = contains_ci(item.name, query)
                   || contains_ci(item.barcode, query)
                   || contains_ci(item.description, query);
        }
        if (matches && has_category) {
            matches = equal_ci(item.category, category);
        }
        if (matches) {
            out_indices[n++] = i;
        }
    }
    return n;
}

// ── custom-list matching ──────────────────────────────────────────────────────

int32_t inventory_match_lists(const CItem* item,  const CRule* rules,
                               int32_t rule_count, char* out_list_ids) {
    if (!item || !rules || !out_list_ids || rule_count <= 0) return 0;

    int32_t matched = 0;
    for (int32_t i = 0; i < rule_count; ++i) {
        const CRule& rule = rules[i];
        bool hit = false;
        switch (rule.match_type) {
            case MATCH_EXACT_BARCODE:
                hit = equal_ci(item->barcode, rule.value);
                break;
            case MATCH_CATEGORY:
                hit = equal_ci(item->category, rule.value);
                break;
            case MATCH_NAME_CONTAINS:
                hit = contains_ci(item->name, rule.value);
                break;
            case MATCH_NAME_STARTS_WITH:
                hit = starts_with_ci(item->name, rule.value);
                break;
            default:
                break;
        }
        if (hit) {
            char* slot = out_list_ids + matched * ITEM_ID_LEN;
            copy_truncated(slot, ITEM_ID_LEN, rule.list_id);
            ++matched;
        }
    }
    return matched;
}

// ── misc ─────────────────────────────────────────────────────────────────────

const char* inventory_version(void) {
    return "1.0.0";
}

// inventory_tests.cpp – standalone C++ tests for the inventory_api.
// Build and run with:
//   cd cpp && cmake -DBUILD_TESTS=ON -B build && cmake --build build
//   ./build/inventory_tests

#include <cassert>
#include <cstring>
#include <cstdio>

#include "inventory_api.h"

// ── helpers ──────────────────────────────────────────────────────────────────

static CItem make_item(const char* id, const char* barcode,
                        const char* name, const char* category,
                        int32_t qty, double price,
                        int64_t date_added = 0) {
    CItem item{};
    strncpy(item.id,          id,       ITEM_ID_LEN - 1);
    strncpy(item.barcode,     barcode,  ITEM_BARCODE_LEN - 1);
    strncpy(item.name,        name,     ITEM_NAME_LEN - 1);
    strncpy(item.category,    category, ITEM_CATEGORY_LEN - 1);
    item.quantity   = qty;
    item.price      = price;
    item.date_added = date_added;
    return item;
}

static CRule make_rule(const char* list_id, MatchType type,
                        const char* value) {
    CRule rule{};
    strncpy(rule.list_id, list_id, ITEM_ID_LEN - 1);
    strncpy(rule.value,   value,   ITEM_NAME_LEN - 1);
    rule.match_type = static_cast<int32_t>(type);
    return rule;
}

#define PASS(name) std::printf("  PASS  %s\n", name)
#define FAIL(name) std::printf("  FAIL  %s\n", name); return false

// ── test functions ────────────────────────────────────────────────────────────

static bool test_sort_by_name() {
    CItem items[3] = {
        make_item("3", "111", "Zucchini", "Veg",  1, 1.0),
        make_item("1", "222", "Apple",    "Fruit",2, 0.5),
        make_item("2", "333", "Banana",   "Fruit",3, 0.8),
    };
    inventory_sort_items(items, 3, SORT_NAME, 1);
    if (strcmp(items[0].name, "Apple")   != 0) { FAIL("sort_name asc[0]"); }
    if (strcmp(items[1].name, "Banana")  != 0) { FAIL("sort_name asc[1]"); }
    if (strcmp(items[2].name, "Zucchini")!= 0) { FAIL("sort_name asc[2]"); }
    PASS("sort_by_name ascending");

    inventory_sort_items(items, 3, SORT_NAME, 0);
    if (strcmp(items[0].name, "Zucchini")!= 0) { FAIL("sort_name desc[0]"); }
    PASS("sort_by_name descending");
    return true;
}

static bool test_sort_by_quantity() {
    CItem items[3] = {
        make_item("a", "1", "A", "", 10, 0.0),
        make_item("b", "2", "B", "",  2, 0.0),
        make_item("c", "3", "C", "",  5, 0.0),
    };
    inventory_sort_items(items, 3, SORT_QUANTITY, 1);
    if (items[0].quantity != 2)  { FAIL("sort_qty asc[0]"); }
    if (items[1].quantity != 5)  { FAIL("sort_qty asc[1]"); }
    if (items[2].quantity != 10) { FAIL("sort_qty asc[2]"); }
    PASS("sort_by_quantity ascending");
    return true;
}

static bool test_sort_by_price() {
    CItem items[3] = {
        make_item("a", "1", "A", "", 0, 9.99),
        make_item("b", "2", "B", "", 0, 1.50),
        make_item("c", "3", "C", "", 0, 4.25),
    };
    inventory_sort_items(items, 3, SORT_PRICE, 0);  // descending
    if (items[0].price != 9.99) { FAIL("sort_price desc[0]"); }
    if (items[1].price != 4.25) { FAIL("sort_price desc[1]"); }
    if (items[2].price != 1.50) { FAIL("sort_price desc[2]"); }
    PASS("sort_by_price descending");
    return true;
}

static bool test_filter_by_query() {
    CItem items[4] = {
        make_item("1", "111", "Whole Milk",   "Dairy", 1, 1.0),
        make_item("2", "222", "Skim Milk",    "Dairy", 2, 0.9),
        make_item("3", "333", "Orange Juice", "Drink", 3, 2.0),
        make_item("4", "444", "Apple Juice",  "Drink", 4, 1.8),
    };
    int32_t out[4]{};
    int32_t n = inventory_filter_items(items, 4, "milk", "", out);
    if (n != 2) { FAIL("filter_query count"); }
    PASS("filter_by_query");
    return true;
}

static bool test_filter_by_category() {
    CItem items[4] = {
        make_item("1", "111", "Cheddar",    "Dairy", 1, 1.0),
        make_item("2", "222", "Brie",       "Dairy", 2, 4.0),
        make_item("3", "333", "Sourdough",  "Bread", 3, 3.5),
        make_item("4", "444", "Whole Wheat","Bread", 4, 2.5),
    };
    int32_t out[4]{};
    int32_t n = inventory_filter_items(items, 4, "", "dairy", out);
    if (n != 2) { FAIL("filter_category count"); }
    if (out[0] != 0 && out[0] != 1) { FAIL("filter_category indices"); }
    PASS("filter_by_category");
    return true;
}

static bool test_filter_combined() {
    CItem items[4] = {
        make_item("1", "111", "Skim Milk",    "Dairy", 1, 1.0),
        make_item("2", "222", "Whole Milk",   "Dairy", 2, 1.2),
        make_item("3", "333", "Almond Milk",  "Alt",   3, 2.5),
        make_item("4", "444", "Apple Juice",  "Drink", 4, 1.8),
    };
    int32_t out[4]{};
    // query="milk" AND category="dairy" → items 0 and 1
    int32_t n = inventory_filter_items(items, 4, "milk", "dairy", out);
    if (n != 2) { FAIL("filter_combined count"); }
    PASS("filter_combined");
    return true;
}

static bool test_match_exact_barcode() {
    CItem item = make_item("1", "012345678901", "Test Item", "Cat", 1, 1.0);
    CRule rules[2] = {
        make_rule("list-A", MATCH_EXACT_BARCODE, "012345678901"),
        make_rule("list-B", MATCH_EXACT_BARCODE, "999999999999"),
    };
    char out[2 * ITEM_ID_LEN]{};
    int32_t n = inventory_match_lists(&item, rules, 2, out);
    if (n != 1) { FAIL("match_exact_barcode count"); }
    if (strcmp(out, "list-A") != 0) { FAIL("match_exact_barcode id"); }
    PASS("match_exact_barcode");
    return true;
}

static bool test_match_category() {
    CItem item = make_item("1", "bc", "Cheddar", "Dairy", 2, 3.0);
    CRule rules[2] = {
        make_rule("dairy-list", MATCH_CATEGORY, "dairy"),
        make_rule("bread-list", MATCH_CATEGORY, "bread"),
    };
    char out[2 * ITEM_ID_LEN]{};
    int32_t n = inventory_match_lists(&item, rules, 2, out);
    if (n != 1) { FAIL("match_category count"); }
    if (strcmp(out, "dairy-list") != 0) { FAIL("match_category id"); }
    PASS("match_category (case-insensitive)");
    return true;
}

static bool test_match_name_contains() {
    CItem item = make_item("1", "bc", "Organic Whole Milk", "Dairy", 1, 2.0);
    CRule rules[3] = {
        make_rule("milk-list",    MATCH_NAME_CONTAINS,    "milk"),
        make_rule("organic-list", MATCH_NAME_STARTS_WITH, "organic"),
        make_rule("juice-list",   MATCH_NAME_CONTAINS,    "juice"),
    };
    char out[3 * ITEM_ID_LEN]{};
    int32_t n = inventory_match_lists(&item, rules, 3, out);
    if (n != 2) { FAIL("match_name count"); }
    PASS("match_name_contains and starts_with");
    return true;
}

static bool test_no_match() {
    CItem item = make_item("1", "bc", "Widget", "Misc", 1, 5.0);
    CRule rules[1] = { make_rule("dairy-list", MATCH_CATEGORY, "dairy") };
    char out[ITEM_ID_LEN]{};
    int32_t n = inventory_match_lists(&item, rules, 1, out);
    if (n != 0) { FAIL("no_match"); }
    PASS("no_match");
    return true;
}

static bool test_version() {
    const char* v = inventory_version();
    if (v == nullptr || v[0] == '\0') { FAIL("version non-empty"); }
    PASS("version");
    return true;
}

// ── runner ────────────────────────────────────────────────────────────────────

int main() {
    std::printf("Running inventory C++ unit tests\n");
    std::printf("----------------------------------\n");

    bool all_pass = true;
    all_pass &= test_sort_by_name();
    all_pass &= test_sort_by_quantity();
    all_pass &= test_sort_by_price();
    all_pass &= test_filter_by_query();
    all_pass &= test_filter_by_category();
    all_pass &= test_filter_combined();
    all_pass &= test_match_exact_barcode();
    all_pass &= test_match_category();
    all_pass &= test_match_name_contains();
    all_pass &= test_no_match();
    all_pass &= test_version();

    std::printf("----------------------------------\n");
    std::printf(all_pass ? "All tests PASSED\n" : "Some tests FAILED\n");
    return all_pass ? 0 : 1;
}

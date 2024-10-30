#include "utils.h"
#include "db/db.h"
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#define BUFFER_SIZE_2 (4096 * 2)

typedef struct sentInfo {
    char response[BUFFER_SIZE_2];
    size_t current_len;
    bool is_first_row;
} sent_info_t;

static void append_to_response(sent_info_t* response, const char* str) {
    strcat_s(response->response, BUFFER_SIZE_2, str);
    response->current_len = strlen(response->response);
}

static void append_json_field(sent_info_t* response, const char* name, const char* value, bool add_comma) {
    if (add_comma) {
        append_to_response(response, ",");
    }
    append_to_response(response, "\"");
    append_to_response(response, name);
    append_to_response(response, "\":\"");
    append_to_response(response, value ? value : "null");
    append_to_response(response, "\"");
}

static int handle_row(sqlite3_stmt* stmt, sent_info_t* response) {
    int col_count = sqlite3_column_count(stmt);
    
    if (!response->is_first_row) {
        append_to_response(response, ",");
    }
    response->is_first_row = false;
    
    append_to_response(response, "{");
    
    for (int i = 0; i < col_count; i++) {
        const char* col_name = sqlite3_column_name(stmt, i);
        const char* col_value = (const char*)sqlite3_column_text(stmt, i);
        append_json_field(response, col_name, col_value, i > 0);
    }
    
    append_to_response(response, "}");
    return 0;
}

static int count_params(const char* query) {
    int count = 0;
    bool in_string = false;
    char string_char = 0;
    
    while (*query) {
        if (*query == '\'' || *query == '"') {
            if (!in_string) {
                in_string = true;
                string_char = *query;
            } else if (string_char == *query) {
                in_string = false;
            }
        } else if (*query == '?' && !in_string) {
            count++;
        }
        query++;
    }
    return count;
}

void respond_with_query(socket_t client_fd, sqlite3* db, const char* query, ...) {
    sqlite3_stmt* stmt = NULL;
    int result;
    
    // Prepare the statement
    result = sqlite3_prepare_v2(db, query, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        char response[BUFFER_SIZE_2];
        snprintf(response, sizeof(response), 
                "{\"error\": \"Failed to prepare statement: %s\"}", 
                sqlite3_errmsg(db));
        send_response(client_fd, "500 Internal Server Error", "application/json", response);
        return;
    }
    
    // Count parameters and bind them
    int param_count = sqlite3_bind_parameter_count(stmt);
    
    if (param_count > 0) {
        va_list args;
        va_start(args, query);
        
        for (int i = 1; i <= param_count; i++) {
            const char* param = va_arg(args, const char*);
            if (param) {
                result = sqlite3_bind_text(stmt, i, param, -1, SQLITE_STATIC);
                if (result != SQLITE_OK) {
                    char response[BUFFER_SIZE_2];
                    snprintf(response, sizeof(response), 
                            "{\"error\": \"Failed to bind parameter %d: %s\"}", 
                            i, sqlite3_errmsg(db));
                    send_response(client_fd, "500 Internal Server Error", "application/json", response);
                    sqlite3_finalize(stmt);
                    va_end(args);
                    return;
                }
            }
        }
        
        va_end(args);
    }
    
    // Initialize response structure
    sent_info_t response_info = {0};
    response_info.response[0] = '[';
    response_info.response[1] = '\0';
    response_info.current_len = 1;
    response_info.is_first_row = true;
    
    // Execute the statement and process results
    bool has_rows = false;
    while ((result = sqlite3_step(stmt)) == SQLITE_ROW) {
        has_rows = true;
        handle_row(stmt, &response_info);
    }
    
    // Check for errors during execution
    if (result != SQLITE_DONE) {
        char response[BUFFER_SIZE_2];
        snprintf(response, sizeof(response), 
                "{\"error\": \"Error executing statement: %s\"}", 
                sqlite3_errmsg(db));
        send_response(client_fd, "500 Internal Server Error", "application/json", response);
        sqlite3_finalize(stmt);
        return;
    }
    
    // Finalize the statement
    sqlite3_finalize(stmt);
    
    // Close the JSON array
    append_to_response(&response_info, "]");
    
    // Handle empty result set
    if (!has_rows) {
        send_response(client_fd, "200 OK", "application/json", "[]");
        return;
    }
    
    // Send the response
    send_response(client_fd, "200 OK", "application/json", response_info.response);
}
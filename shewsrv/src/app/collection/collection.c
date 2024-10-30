#include "collection.h"

#include <stdio.h>
#include <string/string.h>
#include <utils/utils.h>

int init_collection_table(sqlite3* db) {
    char* error_message = NULL;
    const char* query = "CREATE TABLE IF NOT EXISTS collection ("
                        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                        "name TEXT NOT NULL,"
                        "description TEXT"
                        ");";
    int result = sqlite3_exec(db, query, NULL, 0, &error_message);
    if (result != SQLITE_OK) {
        fprintf(stderr, "Failed to create collection table: %s\n", error_message);
        sqlite3_free(error_message);
        return -1;
    }

    // Insert some dummy data
    query = "INSERT INTO collection (name, description) VALUES ('Collection 1', 'This is the first collection');"
            "INSERT INTO collection (name, description) VALUES ('Collection 2', 'This is the second collection');"
            "INSERT INTO collection (name, description) VALUES ('Collection 3', 'This is the third collection');";
    result = sqlite3_exec(db, query, NULL, 0, &error_message);
    if (result != SQLITE_OK) {
        fprintf(stderr, "Failed to insert data into collection table: %s\n", error_message);
        sqlite3_free(error_message);
        return -1;
    }
    return 0;
}

// GET /api/v0/collection
// GET /api/v0/collection/{id}
void handle_collection(socket_t client_fd, const char* method, const char* path, sqlite3* db) {
    if (strcmp(method, "GET") != 0) {
        const char *body = "{\"error\": \"Method Not Allowed\"}";
        send_response(client_fd, "405 Method Not Allowed", "application/json", body);
        return;
    }

    if (strcmp(path, "/api/v0/collection") == 0) {
        respond_with_query(client_fd, db, "SELECT * FROM collection");
    } else {
        const char* id = NULL;
        if (strncmp(path, str_cc_len("/api/v0/collection/")) == 0) {
            id = path + strlen("/api/v0/collection/");
            respond_with_query(client_fd, db, "SELECT * FROM collection WHERE id = %s", id);
        } else {
            const char *body = "{\"error\": \"Not Found\"}";
            send_response(client_fd, "404 Not Found", "application/json", body);
            return;
        }

        
    }
}
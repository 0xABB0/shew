#ifndef SHEWSRV_COLLECTION_COLLECTION_H
#define SHEWSRV_COLLECTION_COLLECTION_H

#include <server/server.h>

#include <sqlite3.h>

int init_collection_table(sqlite3* db);
void handle_collection(socket_t client_fd, const char* method, const char* path, sqlite3* db);

#endif //SHEWSRV_COLLECTION_COLLECTION_H

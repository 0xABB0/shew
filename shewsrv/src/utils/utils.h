#ifndef SHEWSRV_UTILS_UTILS
#define SHEWSRV_UTILS_UTILS

#include <db/db.h>
#include <server/server.h>

#define BUFFER_SIZE 4096

void respond_with_query(socket_t client_fd, sqlite3* db, const char* query, ...);

#endif //SHEWSRV_UTILS_UTILS
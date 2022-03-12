#include "logger.h"
#include <assert.h>
#include <stdarg.h>
#include <stdlib.h>
#include <time.h>
#if defined(_WIN32) || defined(_WIN64)
 #include <winsock2.h>
#else
 #include <pthread.h>
 #include <sys/time.h>
 #include <sys/syscall.h>
 #include <unistd.h>
#endif /* defined(_WIN32) || defined(_WIN64) */

enum {
    /* Logger type */
    kConsoleLogger = 1 << 0,
    kFileLogger = 1 << 1,

    kMaxFileNameLen = 255, /* without null character */
    kDefaultMaxFileSize = 1048576L, /* 1 MB */
};

/* Console logger */
static struct {
    FILE* output;
    unsigned long long flushedTime;
} s_clog;

/* File logger */
static struct {
    FILE* output;
    char filename[kMaxFileNameLen + 1];
    long maxFileSize;
    unsigned char maxBackupFiles;
    long currentFileSize;
    unsigned long long flushedTime;
} s_flog;

static volatile int s_logger;
static volatile LogLevel s_logLevel = LogLevel_INFO;
static volatile long s_flushInterval = 0; /* msec, 0 is auto flush off */
static volatile int s_initialized = 0; /* false */
#if defined(_WIN32) || defined(_WIN64)
static CRITICAL_SECTION s_mutex;
#else
static pthread_mutex_t s_mutex;
#endif /* defined(_WIN32) || defined(_WIN64) */

static void init(void)
{
    if (s_initialized) {
        return;
    }
#if defined(_WIN32) || defined(_WIN64)
    InitializeCriticalSection(&s_mutex);
#else
    pthread_mutex_init(&s_mutex, NULL);
#endif /* defined(_WIN32) || defined(_WIN64) */
    s_initialized = 1; /* true */
}

static void lock(void)
{
#if defined(_WIN32) || defined(_WIN64)
    EnterCriticalSection(&s_mutex);
#else
    pthread_mutex_lock(&s_mutex);
#endif /* defined(_WIN32) || defined(_WIN64) */
}

static void unlock(void)
{
#if defined(_WIN32) || defined(_WIN64)
    LeaveCriticalSection(&s_mutex);
#else
    pthread_mutex_unlock(&s_mutex);
#endif /* defined(_WIN32) || defined(_WIN64) */
}

#if defined(_WIN32) || defined(_WIN64)
static int gettimeofday(struct timeval* tv, void* tz)
{
    const UINT64 epochFileTime = 116444736000000000ULL;
    FILETIME ft;
    ULARGE_INTEGER li;
    UINT64 t;

    if (tv == NULL) {
        return -1;
    }
    GetSystemTimeAsFileTime(&ft);
    li.LowPart = ft.dwLowDateTime;
    li.HighPart = ft.dwHighDateTime;
    t = (li.QuadPart - epochFileTime) / 10;
    tv->tv_sec = (long) (t / 1000000);
    tv->tv_usec = t % 1000000;
    return 0;
}

static struct tm* localtime_r(const time_t* timep, struct tm* result)
{
    localtime_s(result, timep);
    return result;
}
#endif /* defined(_WIN32) || defined(_WIN64) */

static long getCurrentThreadID(void)
{
#if defined(_WIN32) || defined(_WIN64)
    return GetCurrentThreadId();
#elif __linux__
    return syscall(SYS_gettid);
#elif defined(__APPLE__) && defined(__MACH__)
    uint64_t tid64;
    pthread_threadid_np(NULL, &tid64);
    return (pid_t)tid64;
#else
    return (long) pthread_self();
#endif /* defined(_WIN32) || defined(_WIN64) */
}

int logger_initConsoleLogger(FILE* output)
{
    output = (output != NULL) ? output : stdout;
    if (output != stdout && output != stderr) {
        assert(0 && "output must be stdout or stderr");
        return 0;
    }

    init();
    lock();
    s_clog.output = output;
    s_logger |= kConsoleLogger;
    unlock();
    return 1;
}

static long getFileSize(const char* filename)
{
    FILE* fp;
    long size;

    if ((fp = fopen(filename, "rb")) == NULL) {
        return 0;
    }
    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fclose(fp);
    return size;
}

int logger_initFileLogger(const char* filename, long maxFileSize, unsigned char maxBackupFiles)
{
    int ok = 0; /* false */

    if (filename == NULL) {
        assert(0 && "filename must not be NULL");
        return 0;
    }
    if (strlen(filename) > kMaxFileNameLen) {
        assert(0 && "filename exceeds the maximum number of characters");
        return 0;
    }

    init();
    lock();
    if (s_flog.output != NULL) { /* reinit */
        fclose(s_flog.output);
    }
    s_flog.output = fopen(filename, "a");
    if (s_flog.output == NULL) {
        fprintf(stderr, "ERROR: logger: Failed to open file: `%s`\n", filename);
        goto cleanup;
    }
    s_flog.currentFileSize = getFileSize(filename);
    strncpy(s_flog.filename, filename, sizeof(s_flog.filename));
    s_flog.maxFileSize = (maxFileSize > 0) ? maxFileSize : kDefaultMaxFileSize;
    s_flog.maxBackupFiles = maxBackupFiles;
    s_logger |= kFileLogger;
    ok = 1; /* true */
cleanup:
    unlock();
    return ok;
}

void logger_setLevel(LogLevel level)
{
    s_logLevel = level;
}

LogLevel logger_getLevel(void)
{
    return s_logLevel;
}

int logger_isEnabled(LogLevel level)
{
    return s_logLevel <= level;
}

void logger_autoFlush(long interval)
{
    s_flushInterval = interval > 0 ? interval : 0;
}

static int hasFlag(int flags, int flag)
{
    return (flags & flag) == flag;
}

void logger_flush()
{
    if (s_logger == 0 || !s_initialized) {
        assert(0 && "logger is not initialized");
        return;
    }

    if (hasFlag(s_logger, kConsoleLogger)) {
        fflush(s_clog.output);
    }
    if (hasFlag(s_logger, kFileLogger)) {
        fflush(s_flog.output);
    }
}

int logger_clear() {
    // Flush all existing data
    logger_flush();
    fclose(s_flog.output);
    int success = remove(s_flog.filename);
    s_flog.output = fopen(s_flog.filename, "a");
    return success;

}

static char *getLevelDesc(LogLevel level)
{
    switch (level) {
        case LogLevel_TRACE: return "TRACE";
        case LogLevel_DEBUG: return "DEBUG";
        case LogLevel_INFO:  return "INFO";
        case LogLevel_WARN:  return "WARNING";
        case LogLevel_ERROR: return "ERROR";
        case LogLevel_FATAL: return "FATAL";
        default: return " ";
    }
}

static void getTimestamp(const struct timeval* time, char* timestamp, size_t size)
{
    time_t sec = time->tv_sec; /* a necessary variable to avoid a runtime error on Windows */
    struct tm calendar;

    assert(size >= 25);

    localtime_r(&sec, &calendar);
    strftime(timestamp, size, "%y-%m-%d %H:%M:%S", &calendar);
    sprintf(&timestamp[17], ".%06ld", (long) time->tv_usec);
}

static void getBackupFileName(const char* basename, unsigned char index,
        char* backupname, size_t size)
{
    char indexname[5];

    assert(size >= strlen(basename) + sizeof(indexname));

    strncpy(backupname, basename, size);
    if (index > 0) {
        sprintf(indexname, ".%d", index);
        strncat(backupname, indexname, strlen(indexname));
    }
}

static int isFileExist(const char* filename)
{
    FILE* fp;

    if ((fp = fopen(filename, "r")) == NULL) {
        return 0;
    } else {
        fclose(fp);
        return 1;
    }
}

static int rotateLogFiles(void)
{
    int i;
    /* backup filename: <filename>.xxx (xxx: 1-255) */
    char src[kMaxFileNameLen + 5], dst[kMaxFileNameLen + 5]; /* with null character */

    if (s_flog.currentFileSize < s_flog.maxFileSize) {
        return s_flog.output != NULL;
    }
    fclose(s_flog.output);
    for (i = (int) s_flog.maxBackupFiles; i > 0; i--) {
        getBackupFileName(s_flog.filename, i - 1, src, sizeof(src));
        getBackupFileName(s_flog.filename, i, dst, sizeof(dst));
        if (isFileExist(dst)) {
            if (remove(dst) != 0) {
                fprintf(stderr, "ERROR: logger: Failed to remove file: `%s`\n", dst);
            }
        }
        if (isFileExist(src)) {
            if (rename(src, dst) != 0) {
                fprintf(stderr, "ERROR: logger: Failed to rename file: `%s` -> `%s`\n", src, dst);
            }
        }
    }
    s_flog.output = fopen(s_flog.filename, "a");
    if (s_flog.output == NULL) {
        fprintf(stderr, "ERROR: logger: Failed to open file: `%s`\n", s_flog.filename);
        return 0;
    }
    s_flog.currentFileSize = getFileSize(s_flog.filename);
    return 1;
}

static long vflog(FILE* fp, char *levelc, const char* timestamp, long threadID,
        const char* fmt, va_list arg, unsigned long long currentTime, unsigned long long* flushedTime)
{
    int size;
    long totalsize = 0;

    if ((size = fprintf(fp, "[%s][%s][%ld]: ", timestamp, levelc, threadID)) > 0) {
        totalsize += size;
    }
    if ((size = vfprintf(fp, fmt, arg)) > 0) {
        totalsize += size;
    }
    if ((size = fprintf(fp, "\n")) > 0) {
        totalsize += size;
    }
    if (s_flushInterval > 0) {
        if (currentTime - *flushedTime > s_flushInterval) {
            fflush(fp);
            *flushedTime = currentTime;
        }
    }
    return totalsize;
}

void logger_log(LogLevel level, const char* fmt, ...)
{
    struct timeval now;
    unsigned long long currentTime; /* milliseconds */
    char *levelc;
    char timestamp[32];
    long threadID;
    va_list carg, farg;

    if (s_logger == 0 || !s_initialized) {
        assert(0 && "logger is not initialized");
        return;
    }

    if (!logger_isEnabled(level)) {
        return;
    }
    gettimeofday(&now, NULL);
    currentTime = now.tv_sec * 1000 + now.tv_usec / 1000;
    levelc = getLevelDesc(level);
    getTimestamp(&now, timestamp, sizeof(timestamp));
    threadID = getCurrentThreadID();
    lock();
    if (hasFlag(s_logger, kConsoleLogger)) {
        va_start(carg, fmt);
        vflog(s_clog.output, levelc, timestamp, threadID, fmt, carg, currentTime, &s_clog.flushedTime);
        va_end(carg);
    }
    if (hasFlag(s_logger, kFileLogger)) {
        if (rotateLogFiles()) {
            va_start(farg, fmt);
            s_flog.currentFileSize += vflog(s_flog.output, levelc, timestamp, threadID,
                    fmt, farg, currentTime, &s_flog.flushedTime);
            va_end(farg);
        }
    }
    unlock();
}


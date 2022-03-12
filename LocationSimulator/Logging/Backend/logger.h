#ifndef LOGGER_H
#define LOGGER_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdio.h>
#include <string.h>

#if defined(_WIN32) || defined(_WIN64)
 #define __FILENAME__ (strrchr(__FILE__, '\\') ? strrchr(__FILE__, '\\') + 1 : __FILE__)
#else
 #define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#endif /* defined(_WIN32) || defined(_WIN64) */

#define LOG_TRACE(fmt, ...) logger_log(LogLevel_TRACE, fmt, ##__VA_ARGS__)
#define LOG_DEBUG(fmt, ...) logger_log(LogLevel_DEBUG, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...)  logger_log(LogLevel_INFO , fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...)  logger_log(LogLevel_WARN , fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) logger_log(LogLevel_ERROR, fmt, ##__VA_ARGS__)
#define LOG_FATAL(fmt, ...) logger_log(LogLevel_FATAL, fmt, ##__VA_ARGS__)

typedef enum {
    LogLevel_TRACE,
    LogLevel_DEBUG,
    LogLevel_INFO,
    LogLevel_WARN,
    LogLevel_ERROR,
    LogLevel_FATAL,
} LogLevel;

/**
 * Initialize the logger as a console logger.
 * If the file pointer is NULL, stdout will be used.
 *
 * @param[in] output A file pointer. Make sure to set stdout or stderr.
 * @return Non-zero value upon success or 0 on error
 */
int logger_initConsoleLogger(FILE* output);

/**
 * Initialize the logger as a file logger.
 * If the filename is NULL, return without doing anything.
 *
 * @param[in] filename The name of the output file
 * @param[in] maxFileSize The maximum number of bytes to write to any one file
 * @param[in] maxBackupFiles The maximum number of files for backup
 * @return Non-zero value upon success or 0 on error
 */
int logger_initFileLogger(const char* filename, long maxFileSize, unsigned char maxBackupFiles);

/**
 * Set the log level.
 * Message levels lower than this value will be discarded.
 * The default log level is INFO.
 *
 * @param[in] level A log level
 */
void logger_setLevel(LogLevel level);

/**
 * Get the log level that has been set.
 * The default log level is INFO.
 *
 * @return The log level
 */
LogLevel logger_getLevel(void);

/**
 * Check if a message of the level would actually be logged.
 *
 * @return Non-zero value if the log level is enabled
 */
int logger_isEnabled(LogLevel level);

/**
 * Flush automatically.
 * Auto flush is off in default.
 *
 * @param[in] interval A fulsh interval in milliseconds. Switch off if 0 or a negative integer.
 */
void logger_autoFlush(long interval);

/**
 * Flush buffered log messages.
 */
void logger_flush(void);

/**
 * Log a message.
 * Make sure to call one of the following initialize functions before starting logging.
 * - logger_initConsoleLogger()
 * - logger_initFileLogger()
 *
 * @param[in] level A log level
 * @param[in] fmt A format string
 * @param[in] ... Additional arguments
 */
void logger_log(LogLevel level, const char* fmt, ...);

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */

#endif /* LOGGER_H */

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#define DEFAULT_INTERVAL_SECONDS 2

static volatile sig_atomic_t g_running = 1;
static FILE *g_log_file = NULL;

static void handle_signal(int sig) {
    (void)sig;
    g_running = 0;
}

static void log_line(const char *fmt, ...) {
    if (!g_log_file) {
        return;
    }

    time_t now = time(NULL);
    struct tm local_tm;
    localtime_r(&now, &local_tm);

    char ts[32];
    strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", &local_tm);

    fprintf(g_log_file, "[%s] ", ts);

    va_list args;
    va_start(args, fmt);
    vfprintf(g_log_file, fmt, args);
    va_end(args);

    fputc('\n', g_log_file);
    fflush(g_log_file);
}

static bool has_inc_suffix(const char *name) {
    size_t len = strlen(name);
    return (len > 4 && strcmp(name + len - 4, ".inc") == 0);
}

static bool path_is_regular_file(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return false;
    }
    return S_ISREG(st.st_mode);
}

static const char *detect_image_extension(const char *path) {
    static uint8_t buf[32];

    FILE *f = fopen(path, "rb");
    if (!f) {
        return NULL;
    }

    size_t n = fread(buf, 1, sizeof(buf), f);
    fclose(f);

    if (n >= 8 &&
        buf[0] == 0x89 && buf[1] == 0x50 && buf[2] == 0x4E && buf[3] == 0x47 &&
        buf[4] == 0x0D && buf[5] == 0x0A && buf[6] == 0x1A && buf[7] == 0x0A) {
        return ".png";
    }

    if (n >= 3 && buf[0] == 0xFF && buf[1] == 0xD8 && buf[2] == 0xFF) {
        return ".jpg";
    }

    if (n >= 6 && ((memcmp(buf, "GIF87a", 6) == 0) || (memcmp(buf, "GIF89a", 6) == 0))) {
        return ".gif";
    }

    if (n >= 12 && memcmp(buf, "RIFF", 4) == 0 && memcmp(buf + 8, "WEBP", 4) == 0) {
        return ".webp";
    }

    if (n >= 2 && buf[0] == 'B' && buf[1] == 'M') {
        return ".bmp";
    }

    if (n >= 4 && ((buf[0] == 'I' && buf[1] == 'I' && buf[2] == 42 && buf[3] == 0) ||
                   (buf[0] == 'M' && buf[1] == 'M' && buf[2] == 0 && buf[3] == 42))) {
        return ".tiff";
    }

    if (n >= 12 && memcmp(buf + 4, "ftyp", 4) == 0) {
        if (memcmp(buf + 8, "heic", 4) == 0 || memcmp(buf + 8, "heix", 4) == 0 ||
            memcmp(buf + 8, "hevc", 4) == 0 || memcmp(buf + 8, "hevx", 4) == 0 ||
            memcmp(buf + 8, "mif1", 4) == 0 || memcmp(buf + 8, "msf1", 4) == 0) {
            return ".heic";
        }

        if (memcmp(buf + 8, "heif", 4) == 0) {
            return ".heif";
        }
    }

    return NULL;
}

static void strip_inc_suffix(const char *name, char *out, size_t out_size) {
    size_t len = strlen(name);
    if (len < 4) {
        snprintf(out, out_size, "%s", name);
        return;
    }
    size_t base_len = len - 4;
    if (base_len >= out_size) {
        base_len = out_size - 1;
    }
    memcpy(out, name, base_len);
    out[base_len] = '\0';
}

static bool file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static int build_target_path(const char *dir, const char *base_name, const char *ext,
                             char *target, size_t target_size) {
    int written = snprintf(target, target_size, "%s/%s%s", dir, base_name, ext);
    if (written < 0 || (size_t)written >= target_size) {
        return -1;
    }

    if (!file_exists(target)) {
        return 0;
    }

    for (int i = 1; i <= 10000; i++) {
        written = snprintf(target, target_size, "%s/%s-%d%s", dir, base_name, i, ext);
        if (written < 0 || (size_t)written >= target_size) {
            return -1;
        }
        if (!file_exists(target)) {
            return 0;
        }
    }

    return -1;
}

static void process_file(const char *watch_dir, const char *name) {
    char source[PATH_MAX];
    if (snprintf(source, sizeof(source), "%s/%s", watch_dir, name) >= (int)sizeof(source)) {
        log_line("Skipping too-long path: %s/%s", watch_dir, name);
        return;
    }

    if (!path_is_regular_file(source)) {
        return;
    }

    const char *ext = detect_image_extension(source);
    if (!ext) {
        log_line("Skipping non-image .inc file: %s", source);
        return;
    }

    char base_name[PATH_MAX];
    strip_inc_suffix(name, base_name, sizeof(base_name));

    size_t base_len = strlen(base_name);
    size_t ext_len = strlen(ext);
    if (base_len > ext_len && strcmp(base_name + base_len - ext_len, ext) == 0) {
        base_name[base_len - ext_len] = '\0';
    }

    char target[PATH_MAX];
    if (build_target_path(watch_dir, base_name, ext, target, sizeof(target)) != 0) {
        log_line("Unable to build target path for %s", source);
        return;
    }

    if (rename(source, target) != 0) {
        log_line("Rename failed: %s -> %s (errno=%d)", source, target, errno);
        return;
    }

    log_line("Renamed: %s -> %s", source, target);
}

static void scan_once(const char *watch_dir) {
    DIR *dir = opendir(watch_dir);
    if (!dir) {
        log_line("Failed to open watch dir %s (errno=%d)", watch_dir, errno);
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        if (!has_inc_suffix(entry->d_name)) {
            continue;
        }

        process_file(watch_dir, entry->d_name);
    }

    closedir(dir);
}

int main(int argc, char **argv) {
    if (argc < 3 || argc > 4) {
        fprintf(stderr, "Usage: %s <watch_dir> <log_file> [interval_seconds]\n", argv[0]);
        return 1;
    }

    const char *watch_dir = argv[1];
    const char *log_path = argv[2];
    int interval_seconds = DEFAULT_INTERVAL_SECONDS;

    if (argc == 4) {
        interval_seconds = atoi(argv[3]);
        if (interval_seconds <= 0) {
            interval_seconds = DEFAULT_INTERVAL_SECONDS;
        }
    }

    g_log_file = fopen(log_path, "a");
    if (!g_log_file) {
        fprintf(stderr, "Could not open log file: %s\n", log_path);
        return 1;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    log_line("inc-renamer started. watch_dir=%s interval=%d", watch_dir, interval_seconds);

    while (g_running) {
        scan_once(watch_dir);
        sleep((unsigned int)interval_seconds);
    }

    log_line("inc-renamer stopped");
    fclose(g_log_file);
    return 0;
}

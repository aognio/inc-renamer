#include <array>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cstdio>
#include <csignal>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>

namespace fs = std::filesystem;
static std::atomic<bool> g_running{true};

static void handle_signal(int) {
    g_running.store(false);
}

static void log_line(std::ofstream &log, const std::string &message) {
    const std::time_t now = std::time(nullptr);
    char ts[32];
    std::strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
    log << "[" << ts << "] " << message << "\n";
    log.flush();
}

static bool has_inc_suffix(const std::string &name) {
    return name.size() > 4 && name.substr(name.size() - 4) == ".inc";
}

static std::string detect_image_extension(const fs::path &path) {
    std::array<uint8_t, 32> buf{};
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        return "";
    }
    in.read(reinterpret_cast<char *>(buf.data()), static_cast<std::streamsize>(buf.size()));
    const size_t n = static_cast<size_t>(in.gcount());

    if (n >= 8 && buf[0] == 0x89 && buf[1] == 0x50 && buf[2] == 0x4E && buf[3] == 0x47 &&
        buf[4] == 0x0D && buf[5] == 0x0A && buf[6] == 0x1A && buf[7] == 0x0A) {
        return ".png";
    }
    if (n >= 3 && buf[0] == 0xFF && buf[1] == 0xD8 && buf[2] == 0xFF) {
        return ".jpg";
    }
    if (n >= 6 && std::memcmp(buf.data(), "GIF87a", 6) == 0) {
        return ".gif";
    }
    if (n >= 6 && std::memcmp(buf.data(), "GIF89a", 6) == 0) {
        return ".gif";
    }
    if (n >= 12 && std::memcmp(buf.data(), "RIFF", 4) == 0 && std::memcmp(buf.data() + 8, "WEBP", 4) == 0) {
        return ".webp";
    }
    if (n >= 2 && buf[0] == 'B' && buf[1] == 'M') {
        return ".bmp";
    }
    if (n >= 4 && ((buf[0] == 'I' && buf[1] == 'I' && buf[2] == 42 && buf[3] == 0) ||
                   (buf[0] == 'M' && buf[1] == 'M' && buf[2] == 0 && buf[3] == 42))) {
        return ".tiff";
    }
    if (n >= 12 && std::memcmp(buf.data() + 4, "ftyp", 4) == 0) {
        if (std::memcmp(buf.data() + 8, "heic", 4) == 0 || std::memcmp(buf.data() + 8, "heix", 4) == 0 ||
            std::memcmp(buf.data() + 8, "hevc", 4) == 0 || std::memcmp(buf.data() + 8, "hevx", 4) == 0 ||
            std::memcmp(buf.data() + 8, "mif1", 4) == 0 || std::memcmp(buf.data() + 8, "msf1", 4) == 0) {
            return ".heic";
        }
        if (std::memcmp(buf.data() + 8, "heif", 4) == 0) {
            return ".heif";
        }
    }

    return "";
}

static fs::path build_target_path(const fs::path &dir, std::string base_name, const std::string &ext) {
    if (base_name.size() > ext.size() && base_name.substr(base_name.size() - ext.size()) == ext) {
        base_name.resize(base_name.size() - ext.size());
    }

    fs::path target = dir / (base_name + ext);
    if (!fs::exists(target)) {
        return target;
    }

    for (int i = 1; i <= 10000; ++i) {
        target = dir / (base_name + "-" + std::to_string(i) + ext);
        if (!fs::exists(target)) {
            return target;
        }
    }

    return {};
}

int main(int argc, char **argv) {
    if (argc < 3 || argc > 4) {
        std::cerr << "Usage: " << argv[0] << " <watch_dir> <log_file> [interval_seconds]\n";
        return 1;
    }

    const fs::path watch_dir = argv[1];
    const fs::path log_path = argv[2];
    int interval = 2;
    if (argc == 4) {
        interval = std::max(1, std::atoi(argv[3]));
    }

    if (!fs::exists(watch_dir) || !fs::is_directory(watch_dir)) {
        std::cerr << "Watch directory is invalid: " << watch_dir << "\n";
        return 1;
    }

    std::signal(SIGINT, handle_signal);
    std::signal(SIGTERM, handle_signal);

    std::ofstream log(log_path, std::ios::app);
    if (!log) {
        std::cerr << "Could not open log file: " << log_path << "\n";
        return 1;
    }

    log_line(log, "inc-renamer started. watch_dir=" + watch_dir.string());

    while (g_running.load()) {
        std::error_code dir_ec;
        for (const auto &entry : fs::directory_iterator(watch_dir, dir_ec)) {
            if (dir_ec) {
                log_line(log, "Directory iteration error: " + dir_ec.message());
                break;
            }
            if (!entry.is_regular_file()) {
                continue;
            }

            const std::string name = entry.path().filename().string();
            if (!has_inc_suffix(name)) {
                continue;
            }

            const std::string ext = detect_image_extension(entry.path());
            if (ext.empty()) {
                log_line(log, "Skipping non-image .inc file: " + entry.path().string());
                continue;
            }

            std::string base = name.substr(0, name.size() - 4);
            fs::path target = build_target_path(watch_dir, base, ext);
            if (target.empty()) {
                log_line(log, "Unable to build target path for: " + entry.path().string());
                continue;
            }

            std::error_code ec;
            fs::rename(entry.path(), target, ec);
            if (ec) {
                log_line(log, "Rename failed: " + entry.path().string() + " -> " + target.string() +
                              " (" + ec.message() + ")");
                continue;
            }

            log_line(log, "Renamed: " + entry.path().string() + " -> " + target.string());
        }

        std::this_thread::sleep_for(std::chrono::seconds(interval));
    }

    log_line(log, "inc-renamer stopped");
    return 0;
}

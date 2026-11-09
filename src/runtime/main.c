/*
 * Wacky Wheels recomp - host.
 *
 * WW.EXE's lifted code runs on pcrecomp's DOS/4GW host (runtime/dos32), which
 * answers DOS, DPMI, the BIOS, the VGA, the timer and the keyboard. This file
 * is the window around it: the frame dos32 composes, the keyboard into it, and
 * the switches test runs use.
 *
 *   wackywheels [--game DIR] [--headless] [--seconds S] [--shot S FILE]...
 *               [--keys "S:key,S:key,..."] [--log]
 *
 * --keys presses a key at S seconds of guest time: enter space esc up down
 * left right ctrl alt shift tab y n f1..f10, 1..9, a..z.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dos32.h"

extern const uint32_t recomp_image_base, recomp_image_size, recomp_image_stack, recomp_entry_va;
extern const uint8_t recomp_image[];

static dos32_config cfg;
static int headless;
static double seconds;
static volatile LONG exit_code;

/* ---- test runs ------------------------------------------------------------ */

typedef struct { double at; char what[MAX_PATH]; } due_t;
static due_t shots[16], keys[64];
static int nshots, nkeys, ishot, ikey, held_key;
static double release_at;
static uint32_t frame[1280 * 1024];

static int key_code(const char* k) {
    static const struct { const char* n; int sc; } t[] = {
        {"enter",0x1C},{"space",0x39},{"esc",0x01},{"up",0xE048},{"down",0xE050},
        {"left",0xE04B},{"right",0xE04D},{"ctrl",0x1D},{"alt",0x38},{"shift",0x2A},
        {"tab",0x0F},{"y",0x15},{"n",0x31},{"f1",0x3B},{"f2",0x3C},{"f3",0x3D},{"f4",0x3E},
        {"f5",0x3F},{"f6",0x40},{"f7",0x41},{"f8",0x42},{"f9",0x43},{"f10",0x44}};
    for (unsigned i = 0; i < sizeof t / sizeof t[0]; i++) if (!_stricmp(k, t[i].n)) return t[i].sc;
    if (k[0] >= '1' && k[0] <= '9' && !k[1]) return 0x02 + (k[0] - '1');
    if (k[0] && !k[1]) {
        static const char row[] = "qwertyuiop\0\0\0\0asdfghjkl\0\0\0\0\0zxcvbnm";
        const char* p = memchr(row, k[0] | 0x20, sizeof row);
        if (p) return 0x10 + (int)(p - row);
    }
    return 0;
}

static void write_bmp(const char* path) {
    int w, h;
    if (!dos32_frame(frame, 1280, 1024, &w, &h)) { printf("[shot] no graphics mode yet (mode %02X)\n", dos32_video_mode()); return; }
    FILE* f = fopen(path, "wb");
    if (!f) return;
    uint32_t stride = ((uint32_t)w * 3 + 3) & ~3u, size = stride * h;
    BITMAPINFOHEADER bh = { sizeof bh, w, h, 1, 24, BI_RGB };
    BITMAPFILEHEADER fh = { 0x4D42, sizeof fh + sizeof bh + size, 0, 0, sizeof fh + sizeof bh };
    fwrite(&fh, sizeof fh, 1, f);
    fwrite(&bh, sizeof bh, 1, f);
    uint8_t* row = calloc(1, stride);
    for (int y = h - 1; y >= 0; y--) {
        for (int x = 0; x < w; x++) {
            uint32_t p = frame[y * w + x];
            row[x * 3] = (uint8_t)p; row[x * 3 + 1] = (uint8_t)(p >> 8); row[x * 3 + 2] = (uint8_t)(p >> 16);
        }
        fwrite(row, stride, 1, f);
    }
    free(row);
    fclose(f);
    printf("[shot] %dx%d mode %02X -> %s\n", w, h, dos32_video_mode(), path);
}

/* At every retrace: what is due. */
static LARGE_INTEGER qpf, qp0;
static double now_s(void) {
    LARGE_INTEGER t;
    QueryPerformanceCounter(&t);
    return (double)(t.QuadPart - qp0.QuadPart) / qpf.QuadPart;
}

static void on_retrace(void) {
    double t = now_s();
    while (ishot < nshots && t >= shots[ishot].at) write_bmp(shots[ishot++].what);
    if (held_key && t >= release_at) { dos32_key(held_key, 0); held_key = 0; }
    while (!held_key && ikey < nkeys && t >= keys[ikey].at) {
        int sc = key_code(keys[ikey].what);
        printf("[keys] %.1fs %s\n", t, keys[ikey].what);
        ikey++;
        if (sc) { dos32_key(sc, 1); held_key = sc; release_at = t + 0.15; }
    }
    if (seconds > 0 && t >= seconds) { printf("[ww] %.0f s: done\n", seconds); dos32_quit = 1; }
}

static int parse_due(const char* s, due_t* d, int n, int max) {
    while (s && *s && n < max) {
        char* end;
        d[n].at = strtod(s, &end);
        if (*end != ':') break;
        s = end + 1;
        int k = 0;
        while (*s && *s != ',' && k < MAX_PATH - 1) d[n].what[k++] = *s++;
        d[n].what[k] = 0;
        n++;
        if (*s == ',') s++;
    }
    return n;
}

/* ---- the window ------------------------------------------------------------- */

static LRESULT CALLBACK wndproc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
    case WM_TIMER: InvalidateRect(h, NULL, FALSE); return 0;
    case WM_PAINT: {
        static uint32_t buf[1280 * 1024];
        PAINTSTRUCT ps;
        HDC dc = BeginPaint(h, &ps);
        int fw, fh;
        RECT r;
        GetClientRect(h, &r);
        if (dos32_frame(buf, 1280, 1024, &fw, &fh)) {
            BITMAPINFO bi = { { sizeof(BITMAPINFOHEADER), fw, -fh, 1, 32, BI_RGB } };
            StretchDIBits(dc, 0, 0, r.right, r.bottom, 0, 0, fw, fh, buf, &bi, DIB_RGB_COLORS, SRCCOPY);
        } else {
            FillRect(dc, &r, GetStockObject(BLACK_BRUSH));
        }
        EndPaint(h, &ps);
        return 0;
    }
    case WM_KEYDOWN: case WM_SYSKEYDOWN: case WM_KEYUP: case WM_SYSKEYUP:
        if ((m == WM_KEYDOWN || m == WM_SYSKEYDOWN) && (l & 0x40000000)) return 0;
        dos32_key((int)((l >> 16) & 0xFF) | ((l & 0x01000000) ? 0xE000 : 0), m == WM_KEYDOWN || m == WM_SYSKEYDOWN);
        return 0;
    case WM_SYSCHAR: return 0;
    case WM_CLOSE: dos32_quit = 1; return 0;
    }
    return DefWindowProcA(h, m, w, l);
}

static DWORD WINAPI game_thread(LPVOID p) {
    (void)p;
    exit_code = dos32_run(&cfg);
    printf("[ww] WW.EXE exited (%ld)\n", exit_code);
    return 0;
}

int main(int argc, char** argv) {
    const char* game = "game";
    setvbuf(stdout, NULL, _IONBF, 0);
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--headless")) headless = 1;
        else if (!strcmp(argv[i], "--log")) cfg.log = 1;
        else if (!strcmp(argv[i], "--game") && i + 1 < argc) game = argv[++i];
        else if (!strcmp(argv[i], "--seconds") && i + 1 < argc) seconds = atof(argv[++i]);
        else if (!strcmp(argv[i], "--shot") && i + 2 < argc && nshots < 16) {
            shots[nshots].at = atof(argv[++i]);
            GetFullPathNameA(argv[++i], MAX_PATH, shots[nshots++].what, NULL);
        } else if (!strcmp(argv[i], "--keys") && i + 1 < argc) nkeys = parse_due(argv[++i], keys, nkeys, 64);
        else { printf("usage: wackywheels [--game DIR] [--headless] [--seconds S] [--shot S FILE] [--keys \"S:key,...\"] [--log]\n"); return 1; }
    }
    static char root[MAX_PATH];
    GetFullPathNameA(game, MAX_PATH, root, NULL);
    cfg.root = root;
    cfg.cwd = "\\";
    cfg.progname = "C:\\WW.EXE";
    cfg.args = "";
    cfg.image = recomp_image;
    cfg.image_base = recomp_image_base;
    cfg.image_size = recomp_image_size;
    cfg.entry = recomp_entry_va;
    cfg.stack = recomp_image_stack;
    QueryPerformanceFrequency(&qpf);
    QueryPerformanceCounter(&qp0);
    dos32_on_retrace = on_retrace;
    printf("Wacky Wheels recomp: %s as C:\\\n", root);

    HANDLE t = CreateThread(NULL, 256u << 20, game_thread, NULL, STACK_SIZE_PARAM_IS_A_RESERVATION, NULL);
    if (headless) { WaitForSingleObject(t, INFINITE); return (int)exit_code; }
    WNDCLASSA wc = { 0 };
    wc.lpfnWndProc = wndproc;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.lpszClassName = "WackyWheelsRecomp";
    RegisterClassA(&wc);
    RECT r = { 0, 0, 960, 600 };
    AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
    HWND h = CreateWindowA(wc.lpszClassName, "Wacky Wheels", WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                           CW_USEDEFAULT, CW_USEDEFAULT, r.right - r.left, r.bottom - r.top,
                           NULL, NULL, wc.hInstance, NULL);
    SetTimer(h, 1, 14, NULL);
    MSG msg;
    while (WaitForSingleObject(t, 0) == WAIT_TIMEOUT) {
        while (PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE)) { TranslateMessage(&msg); DispatchMessageA(&msg); }
        MsgWaitForMultipleObjects(1, &t, FALSE, 20, QS_ALLINPUT);
    }
    return (int)exit_code;
}

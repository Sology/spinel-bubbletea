/* bubbletea for Spinel: the part of the gem's C extension (ext/bubbletea/*.c)
   that cannot be a plain ffi_func binding of the Go archive's exports.

   The Go side hands back strings it allocated (C.CString), which the caller
   frees: each is copied into a buffer this file owns, released, and the buffer
   returned for the call site to copy into a Ruby String (`:str` / `:binstr`).
   terminal_size's two out-parameters travel packed in one Integer. Everything
   else (program and renderer handles, the terminal switches, rendering) binds
   straight to the Go functions in bubbletea.rb. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "spinel/runtime.h"

/* The Go archive's exports used here, as cgo declares them in the
   libbubbletea.h it writes beside the archive (not included: it is produced by
   the [[build]] step, after this file may already be compiled). */
extern void tea_free(char *pointer);
extern char *tea_upstream_version(void);
extern char *tea_get_key_name(int keyType);
extern int tea_terminal_get_size(unsigned long long programID, int *widthOut, int *heightOut);
extern int tea_input_read_raw(unsigned long long programID, char *buffer, int bufferSize, int timeoutMs);
extern char *tea_parse_input_with_consumed(char *data, int dataLength, int *consumed);

static SP_TLS char *sp_tea_buf;
static SP_TLS size_t sp_tea_cap;

/* n bytes of s, NUL-terminated, in this thread's buffer */
static const char *sp_tea_keep(const char *s, size_t n) {
  if (n + 1 > sp_tea_cap) {
    size_t cap = sp_tea_cap ? sp_tea_cap : 256;
    while (cap < n + 1) cap *= 2;
    char *b = (char *)realloc(sp_tea_buf, cap);
    if (!b) { sp_ffi_bin_len = 0; return ""; }
    sp_tea_buf = b;
    sp_tea_cap = cap;
  }
  if (n) memcpy(sp_tea_buf, s, n);
  sp_tea_buf[n] = 0;
  sp_ffi_bin_len = (int)n;
  return sp_tea_buf;
}

/* Bubbletea.upstream_version (extension.c): the Go string, freed with tea_free */
const char *sp_tea_upstream_version(void) {
  char *v = tea_upstream_version();
  const char *r = sp_tea_keep(v ? v : "", v ? strlen(v) : 0);
  tea_free(v);
  return r;
}

/* Bubbletea.get_key_name (extension.c): freed with free(), as the extension does */
const char *sp_tea_get_key_name(int64_t key_type) {
  char *n = tea_get_key_name((int)key_type);
  const char *r = sp_tea_keep(n ? n : "", n ? strlen(n) : 0);
  free(n);
  return r;
}

/* Program#terminal_size (program.c): width << 32 | height, or -1 when the size
   cannot be read (the extension's nil) */
int64_t sp_tea_terminal_size(int64_t program) {
  int w = 0, h = 0;
  if (tea_terminal_get_size((unsigned long long)program, &w, &h) != 0) return -1;
  return ((int64_t)(uint32_t)w << 32) | (int64_t)(uint32_t)h;
}

/* Program#read_raw_input (program.c): up to 256 bytes, or none on a timeout or
   an error (the extension's nil; a read never answers zero bytes otherwise) */
const char *sp_tea_read_raw_input(int64_t program, int64_t timeout_ms) {
  char buffer[256];
  int n = tea_input_read_raw((unsigned long long)program, buffer, (int)sizeof buffer, (int)timeout_ms);
  return sp_tea_keep(buffer, n > 0 ? (size_t)n : 0);
}

/* Program#poll_event (program.c): a read, then the Go parser's JSON for the
   first event in it, or "" for none (the extension's nil). Like the
   extension, bytes after the first event in one read are not kept. */
const char *sp_tea_poll_event(int64_t program, int64_t timeout_ms) {
  char buffer[256];
  int n = tea_input_read_raw((unsigned long long)program, buffer, (int)sizeof buffer, (int)timeout_ms);
  if (n <= 0) return sp_tea_keep("", 0);
  int consumed = 0;
  char *json = tea_parse_input_with_consumed(buffer, n, &consumed);
  const char *r = sp_tea_keep(json ? json : "", json ? strlen(json) : 0);
  tea_free(json);
  return r;
}

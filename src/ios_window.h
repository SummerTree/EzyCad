#pragma once

#if defined(__APPLE__) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void ios_init(void);
void ios_terminate(void);

bool ios_create_window(int width, int height);
void ios_destroy_window(void);
void* ios_get_view(void);
void* ios_get_context(void);
void ios_make_context_current(void);
void ios_clear_context(void);
void ios_swap_buffers(void);
void ios_poll_events(void);
bool ios_window_should_close(void);
void ios_set_window_should_close(bool value);
void ios_get_viewport(int* width, int* height);
float ios_get_content_scale(void);

typedef void (*IosTouchCallback)(int id, float x, float y, int phase);
typedef void (*IosKeyCallback)(uint32_t key, bool pressed);
typedef void (*IosResizeCallback)(int width, int height);

void ios_set_touch_callback(IosTouchCallback callback);
void ios_set_key_callback(IosKeyCallback callback);
void ios_set_resize_callback(IosResizeCallback callback);

bool ios_has_pending_input(void);
bool ios_get_touch(int id, float* x, float* y, int* phase);
bool ios_get_key_state(uint32_t key);
void ios_ignore_next_touch(void);

#ifdef __cplusplus
}
#endif

#else
#error "ios_window.h should only be included for iOS builds"
#endif

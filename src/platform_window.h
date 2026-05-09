#pragma once

#include <functional>
#include <string>

#if defined(__EMSCRIPTEN__)
#include <emscripten/html5.h>
#endif

#if defined(__APPLE__) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
#define EZYCAD_IOS 1
#define EZYCAD_GLFW 0
#elif defined(__EMSCRIPTEN__)
#define EZYCAD_IOS 0
#define EZYCAD_GLFW 0
#define EZYCAD_WASM 1
#else
#define EZYCAD_IOS 0
#define EZYCAD_GLFW 1
#define EZYCAD_WASM 0
#endif

#if EZYCAD_IOS
#include "ios_window.h"
using NativeWindowHandle = void*;
#elif EZYCAD_GLFW
struct GLFWwindow;
using NativeWindowHandle = GLFWwindow*;
#elif EZYCAD_WASM
using NativeWindowHandle = void*;
#endif

struct ScreenCoords
{
  double x, y;

  ScreenCoords() : x(0), y(0) {}
  ScreenCoords(double _x, double _y) : x(_x), y(_y) {}
  explicit ScreenCoords(const glm::dvec2& v) : x(v.x), y(v.y) {}

  glm::dvec2 to_glm() const { return glm::dvec2(x, y); }
  operator glm::dvec2() const { return to_glm(); }
};

struct PlatformWindow
{
#if EZYCAD_IOS
  NativeWindowHandle view;
  NativeWindowHandle context;
#elif EZYCAD_GLFW
  NativeWindowHandle window;
#elif EZYCAD_WASM
  NativeWindowHandle canvas;
#endif

  PlatformWindow() { memset(this, 0, sizeof(*this)); }

  bool create_window(int width, int height, const char* title);
  void destroy_window();
  void make_context_current();
  void clear_context();
  void swap_buffers();
  void poll_events();
  bool should_close() const;
  void set_should_close(bool value);
  void get_viewport(int& width, int& height) const;
  float get_content_scale() const;
};

inline bool PlatformWindow::create_window(int width, int height, const char* title)
{
#if EZYCAD_IOS
  return ios_create_window(width, height);
#elif EZYCAD_GLFW
  window = glfwCreateWindow(width, height, title, nullptr, nullptr);
  return window != nullptr;
#elif EZYCAD_WASM
  return true;
#endif
}

inline void PlatformWindow::destroy_window()
{
#if EZYCAD_IOS
  ios_destroy_window();
#elif EZYCAD_GLFW
  if (window)
  {
    glfwDestroyWindow(window);
    window = nullptr;
  }
#elif EZYCAD_WASM
#endif
}

inline void PlatformWindow::make_context_current()
{
#if EZYCAD_IOS
  ios_make_context_current();
#elif EZYCAD_GLFW
  if (window)
    glfwMakeContextCurrent(window);
#elif EZYCAD_WASM
#endif
}

inline void PlatformWindow::clear_context()
{
#if EZYCAD_IOS
  ios_clear_context();
#elif EZYCAD_GLFW
  glfwMakeContextCurrent(nullptr);
#elif EZYCAD_WASM
#endif
}

inline void PlatformWindow::swap_buffers()
{
#if EZYCAD_IOS
  ios_swap_buffers();
#elif EZYCAD_GLFW
  if (window)
    glfwSwapBuffers(window);
#elif EZYCAD_WASM
  emscripten_webgl_commit_frame();
#endif
}

inline void PlatformWindow::poll_events()
{
#if EZYCAD_IOS
  ios_poll_events();
#elif EZYCAD_GLFW
  glfwPollEvents();
#elif EZYCAD_WASM
#endif
}

inline bool PlatformWindow::should_close() const
{
#if EZYCAD_IOS
  return ios_window_should_close();
#elif EZYCAD_GLFW
  return window ? glfwWindowShouldClose(window) != 0 : true;
#elif EZYCAD_WASM
  return false;
#endif
}

inline void PlatformWindow::set_should_close(bool value)
{
#if EZYCAD_IOS
  ios_set_window_should_close(value);
#elif EZYCAD_GLFW
  if (window)
    glfwSetWindowShouldClose(window, value ? GLFW_TRUE : GLFW_FALSE);
#elif EZYCAD_WASM
#endif
}

inline void PlatformWindow::get_viewport(int& width, int& height) const
{
#if EZYCAD_IOS
  ios_get_viewport(&width, &height);
#elif EZYCAD_GLFW
  if (window)
  {
    glfwGetFramebufferSize(window, &width, &height);
  }
  else
  {
    width = height = 0;
  }
#elif EZYCAD_WASM
  emscripten_get_canvas_element_size("#canvas", &width, &height);
#endif
}

inline float PlatformWindow::get_content_scale() const
{
#if EZYCAD_IOS
  return ios_get_content_scale();
#elif EZYCAD_GLFW
  return ImGui_ImplGlfw_GetContentScaleForMonitor(glfwGetPrimaryMonitor());
#elif EZYCAD_WASM
  return emscripten_get_device_pixel_ratio();
#endif
}

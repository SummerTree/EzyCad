#if defined(__APPLE__) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#define GL_SILENCE_DEPRECATION
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@class EzyCadGLKView;

static EzyCadGLKView* g_glk_view = nil;
static EAGLContext* g_context = nil;
static bool g_window_should_close = false;

static IosTouchCallback g_touch_callback = NULL;
static IosKeyCallback g_key_callback = NULL;
static IosResizeCallback g_resize_callback = NULL;

static bool g_has_pending_touch = false;
static int g_pending_touch_id = 0;
static float g_pending_touch_x = 0;
static float g_pending_touch_y = 0;
static int g_pending_touch_phase = 0;

#define MAX_TOUCHES 10
static bool g_touch_active[MAX_TOUCHES] = {false};
static float g_touch_x[MAX_TOUCHES] = {0};
static float g_touch_y[MAX_TOUCHES] = {0};
static int g_touch_phase[MAX_TOUCHES] = {0};

static bool g_ignore_next_touch = false;

void ios_init(void) {
    g_glk_view = nil;
    g_context = nil;
    g_window_should_close = false;
    g_has_pending_touch = false;
    for (int i = 0; i < MAX_TOUCHES; i++) {
        g_touch_active[i] = false;
    }
}

void ios_terminate(void) {
    if (g_context != nil) {
        [EAGLContext setCurrentContext:g_context];
        g_context = nil;
    }
    g_glk_view = nil;
}

bool ios_create_window(int width, int height) {
    if (g_glk_view != nil) {
        return true;
    }

    CGRect screen_bounds = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];

    g_glk_view = [[EzyCadGLKView alloc] initWithFrame:CGRectMake(0, 0, screen_bounds.size.width, screen_bounds.size.height)
                                            pixelFormat:kEAGLColorFormatRGBA8
                                           depthFormat:GL_DEPTH24_STENCIL8_OES
                                    preserveBackbuffer:NO
                                            sharegroup:nil
                                         multiSampling:NO
                                       numberOfSamples:0];

    if (g_glk_view == nil) {
        return false;
    }

    g_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (g_context == nil) {
        return false;
    }

    [g_glk_view setContext:g_context];
    [g_glk_view setEnableSetNeedsDisplay:YES];
    [g_glk_view setMultipleTouchEnabled:YES];

    [g_glk_view.window makeKeyAndVisible];

    return true;
}

void ios_destroy_window(void) {
    g_glk_view = nil;
    g_context = nil;
}

void* ios_get_view(void) {
    return (__bridge void*)g_glk_view;
}

void* ios_get_context(void) {
    return (__bridge void*)g_context;
}

void ios_make_context_current(void) {
    [EAGLContext setCurrentContext:g_context];
}

void ios_clear_context(void) {
    [EAGLContext setCurrentContext:nil];
}

void ios_swap_buffers(void) {
    [g_glk_view flushBuffer];
}

void ios_poll_events(void) {
}

bool ios_window_should_close(void) {
    return g_window_should_close;
}

void ios_set_window_should_close(bool value) {
    g_window_should_close = value;
}

void ios_get_viewport(int* width, int* height) {
    if (g_glk_view != nil) {
        CGRect bounds = [g_glk_view bounds];
        if (width) *width = (int)CGRectGetWidth(bounds);
        if (height) *height = (int)CGRectGetHeight(bounds);
    } else {
        if (width) *width = 0;
        if (height) *height = 0;
    }
}

float ios_get_content_scale(void) {
    if (g_glk_view != nil) {
        return [g_glk_view contentScaleFactor];
    }
    return [[UIScreen mainScreen] scale];
}

void ios_set_touch_callback(IosTouchCallback callback) {
    g_touch_callback = callback;
}

void ios_set_key_callback(IosKeyCallback callback) {
    g_key_callback = callback;
}

void ios_set_resize_callback(IosResizeCallback callback) {
    g_resize_callback = callback;
}

bool ios_has_pending_input(void) {
    return g_has_pending_touch;
}

bool ios_get_touch(int id, float* x, float* y, int* phase) {
    if (id >= 0 && id < MAX_TOUCHES && g_touch_active[id]) {
        if (x) *x = g_touch_x[id];
        if (y) *y = g_touch_y[id];
        if (phase) *phase = g_touch_phase[id];
        return true;
    }
    return false;
}

bool ios_get_key_state(uint32_t key) {
    return false;
}

void ios_ignore_next_touch(void) {
    g_ignore_next_touch = true;
}

void ios_handle_touch(int touch_id, float x, float y, int phase) {
    if (touch_id >= 0 && touch_id < MAX_TOUCHES) {
        g_touch_active[touch_id] = true;
        g_touch_x[touch_id] = x;
        g_touch_y[touch_id] = y;
        g_touch_phase[touch_id] = phase;

        g_has_pending_touch = true;
        g_pending_touch_id = touch_id;
        g_pending_touch_x = x;
        g_pending_touch_y = y;
        g_pending_touch_phase = phase;

        if (g_touch_callback) {
            g_touch_callback(touch_id, x, y, phase);
        }
    }
}

@interface EzyCadGLKView : GLKView
{
    CADisplayLink* _displayLink;
    BOOL _animating;
}
- (void)startAnimation;
- (void)stopAnimation;
@end

@implementation EzyCadGLKView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
                 pixelFormat:(NSString*)format
                depthFormat:(GLenum)depthFormat
         preserveBackbuffer:(BOOL)preserveBackbuffer
                 sharegroup:(EAGLSharegroup*)sharegroup
              multiSampling:(BOOL)multiSampling
            numberOfSamples:(NSInteger)samples
{
    self = [super initWithFrame:frame
                   pixelFormat:format
                  depthFormat:depthFormat
           preserveBackbuffer:preserveBackbuffer
                   sharegroup:sharegroup
                multiSampling:multiSampling
              numberOfSamples:samples];
    if (self) {
        _animating = NO;
        _displayLink = nil;
    }
    return self;
}

- (void)dealloc {
    [self stopAnimation];
}

- (void)startAnimation {
    if (!_animating) {
        _animating = YES;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAnimation {
    if (_animating) {
        _animating = NO;
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)drawFrame {
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self];
        CGFloat scale = self.contentScaleFactor;
        ios_handle_touch((int)[[touches allObjects] indexOfObject:touch],
                        location.x * scale,
                        location.y * scale,
                        0);
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self];
        CGFloat scale = self.contentScaleFactor;
        ios_handle_touch((int)[[touches allObjects] indexOfObject:touch],
                        location.x * scale,
                        location.y * scale,
                        1);
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self];
        CGFloat scale = self.contentScaleFactor;
        ios_handle_touch((int)[[touches allObjects] indexOfObject:touch],
                        location.x * scale,
                        location.y * scale,
                        2);
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self touchesEnded:touches withEvent:event];
}

@end

#endif

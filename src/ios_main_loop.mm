#if defined(__APPLE__) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#define GL_SILENCE_DEPRECATION
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include "gui.h"
#include "platform_window.h"
#include "imgui.h"
#include "imgui_impl_opengl3.h"
#include "ui_font.h"

#include <functional>
#include <memory>

@class EzyCadGLKViewController;

static EzyCadGLKViewController* g_view_controller = nil;
static GUI* g_gui = nullptr;
static ImFont* g_console_font = nullptr;

static std::function<void(int key, int scancode, int action, int mods)> keyCallback;
static std::function<void(double xpos, double ypos)> cursorPosCallback;
static std::function<void(int button, int action, int mods)> mouseButtonCallback;
static std::function<void(int width, int height)> windowSizeCallback;
static std::function<void(double xoffset, double yoffset)> scrollCallback;

@interface EzyCadGLKViewController : GLKViewController <GLKViewDelegate>
@end

@implementation EzyCadGLKViewController

+ (void)setViewController:(EzyCadGLKViewController*)controller {
    g_view_controller = controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.preferredFramesPerSecond = 60;
    self.paused = NO;
    self.enableSetNeedsDisplay = NO;

    if (self.context && [self.context isKindOfClass:[EAGLContext class]]) {
        [EAGLContext setCurrentContext:(EAGLContext*)self.context];

        const char* glsl_version = "#version 100";

        ImGui_ImplOpenGL3_Init(glsl_version);

        ImGuiIO& io = ImGui::GetIO();
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;

        ImGui::StyleColorsDark();

        ImGuiStyle& style = ImGui::GetStyle();
        CGFloat scale = self.view.contentScaleFactor;
        style.ScaleAllSizes(scale);
        style.FontGlobalScale = scale;

        NSString* droidPath = [[NSBundle mainBundle] pathForResource:@"DroidSans" ofType:@"ttf"];
        if (droidPath) {
            ImFont* font = io.Fonts->AddFontFromFileTTF([droidPath UTF8String], k_imgui_base_font_size_px);
            (void)font;
        }

        NSString* cousinePath = [[NSBundle mainBundle] pathForResource:@"Cousine-Regular" ofType:@"ttf"];
        if (cousinePath) {
            g_console_font = io.Fonts->AddFontFromFileTTF([cousinePath UTF8String], k_imgui_base_font_size_px);
        }

        g_gui = new GUI();
        g_gui->init(nullptr, g_console_font);

        [self.view setNeedsDisplay];
    }
}

- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    if (!g_gui) return;

    [EAGLContext setCurrentContext:(EAGLContext*)self.context];

    int fb_width = (int)(CGRectGetWidth(rect) * view.contentScaleFactor);
    int fb_height = (int)(CGRectGetHeight(rect) * view.contentScaleFactor);

    glViewport(0, 0, fb_width, fb_height);

    ImGui_ImplOpenGL3_NewFrame();
    ImGui::NewFrame();

    g_gui->render_gui();

    ImGui::Render();

    ImVec4 clear_color = g_gui->get_clear_color();
    glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w,
                 clear_color.z * clear_color.w, clear_color.w);
    glClear(GL_COLOR_BUFFER_BIT);

    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    g_gui->render_occt();

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

- (void)update {
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    if (g_gui && touches.count > 0) {
        UITouch* touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        CGFloat scale = self.view.contentScaleFactor;

        g_gui->on_mouse_pos(ScreenCoords(location.x * scale, location.y * scale));
        g_gui->on_mouse_button(0, 1, 0);
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    if (g_gui && touches.count > 0) {
        UITouch* touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        CGFloat scale = self.view.contentScaleFactor;

        g_gui->on_mouse_pos(ScreenCoords(location.x * scale, location.y * scale));
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    if (g_gui && touches.count > 0) {
        UITouch* touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        CGFloat scale = self.view.contentScaleFactor;

        g_gui->on_mouse_pos(ScreenCoords(location.x * scale, location.y * scale));
        g_gui->on_mouse_button(0, 0, 0);
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view setNeedsDisplay];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

@interface EzyCadAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow* window;
@end

@implementation EzyCadAppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    CGRect screen_bounds = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];

    self.window = [[UIWindow alloc] initWithFrame:screen_bounds];

    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    GLKView* glk_view = [[GLKView alloc] initWithFrame:screen_bounds
                                           pixelFormat:kEAGLColorFormatRGBA8
                                           depthFormat:GL_DEPTH24_STENCIL8_OES
                                    preserveBackbuffer:NO
                                            sharegroup:nil
                                         multiSampling:NO
                                       numberOfSamples:0];
    glk_view.context = context;
    glk_view.delegate = [EzyCadGLKViewController new];
    glk_view.contentScaleFactor = scale;
    glk_view.multipleTouchEnabled = YES;
    [glk_view bindDrawable];

    [EzyCadGLKViewController setViewController:(EzyCadGLKViewController*)glk_view.delegate];

    self.window.rootViewController = (UIViewController*)glk_view.delegate;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application {
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
}

- (void)applicationWillTerminate:(UIApplication*)application {
    if (g_gui) {
        g_gui->save_occt_view_settings();
        ImGui_ImplOpenGL3_Shutdown();
        ImGui::DestroyContext();
        delete g_gui;
        g_gui = nullptr;
    }
}

@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([EzyCadAppDelegate class]));
    }
}

#endif

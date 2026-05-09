#if defined(__APPLE__) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#include "gui.h"
#include "platform_window.h"
#include <functional>
#include <string>

@class EzyCadAppDelegate;

static GUI* s_gui = nullptr;
static ImFont* s_console_font = nullptr;

extern "C" {

void ezycad_ios_main(void* view, void* context);

}

@interface EzyCadGLKViewController : GLKViewController
@end

@implementation EzyCadGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.context isKindOfClass:[EAGLContext class]]) {
        ezycad_ios_main((__bridge void*)self.view, (__bridge void*)self.context);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    // Rendering handled by main loop
}

@end

// Application lifecycle
int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([EzyCadAppDelegate class]));
    }
}

@implementation EzyCadAppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
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
}

@end

#endif

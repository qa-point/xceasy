#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

// Forward declaration of Swift class
@interface XCEasyTestObserver : NSObject
@end

/// This function is called automatically before main() is executed.
/// It creates and registers the XCEasyTestObserver instance.
__attribute__((constructor))
static void XCEasyTestObserverBootstrap(void) {
    // Create observer instance - this triggers its init method
    // which registers it with XCTestObservationCenter
    (void)[[XCEasyTestObserver alloc] init];
}

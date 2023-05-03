//
//  ExceptionSafety.m
//  
//
//  Created by Brandon Sneed on 1/30/23.
//

#import <Foundation/Foundation.h>
#import "include/ExceptionSafety.h"

static SAUncaughtExceptionHandler swiftExceptionHandler = nil;
static NSUncaughtExceptionHandler *originalExceptionhandler = nil;

NSException * _Nullable SACatchException(void(NS_NOESCAPE^ _Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

void __SAUncaughtExceptionHandler(NSException *exception) {
    NSLog(@"Uncaught Exception: %@", exception);
    if (swiftExceptionHandler) {
        swiftExceptionHandler(exception);
    }
    if (originalExceptionhandler) {
        originalExceptionhandler(exception);
    }
}

void SASetUncaughtExceptionHandler(SAUncaughtExceptionHandler handler) {
    originalExceptionhandler = NSGetUncaughtExceptionHandler();
    swiftExceptionHandler = handler;
    NSSetUncaughtExceptionHandler(&__SAUncaughtExceptionHandler);
}

void SAClearUncaughtExceptionHandler() {
    if (swiftExceptionHandler) {
        NSSetUncaughtExceptionHandler(originalExceptionhandler);
        originalExceptionhandler = nil;
        swiftExceptionHandler = nil;
    }
}



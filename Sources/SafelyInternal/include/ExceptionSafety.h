//
//  ExceptionSafety.h
//  
//
//  Created by Brandon Sneed on 1/30/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^_Nonnull SAUncaughtExceptionHandler)(NSException *);

NSException * _Nullable SACatchException(void(NS_NOESCAPE ^_Nonnull tryBlock)(void));
void SASetUncaughtExceptionHandler(SAUncaughtExceptionHandler);
void SAClearUncaughtExceptionHandler();

NS_ASSUME_NONNULL_END

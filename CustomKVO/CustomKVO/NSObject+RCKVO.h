//
//  NSObject+RCKVO.h
//  CustomKVO
//
//  Created by 孙承秀 on 2018/5/23.
//  Copyright © 2018年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^RCObserverBlock)(id observerObject , id key , id oldValue , id newValue);
@interface NSObject (RCKVO)
- (void)rc_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(RCObserverBlock)block;
@end

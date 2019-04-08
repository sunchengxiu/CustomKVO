//
//  NSObject+RCKVO.m
//  CustomKVO
//
//  Created by 孙承秀 on 2018/5/23.
//  Copyright © 2018年 孙承秀. All rights reserved.
//

#import "NSObject+RCKVO.h"
#import <objc/message.h>

@interface RCObserverInfo:NSObject
/**
 observer
 */
@property(nonatomic , weak)NSObject *observer;
/**
 key
 */
@property(nonatomic , strong)NSString *key;
/**
 block
 */
@property(nonatomic , strong)RCObserverBlock block;
@end

@implementation RCObserverInfo
- (instancetype)initWithObserver:(NSObject *)obserser forKey:(NSString *)key block:(RCObserverBlock)block{
    if (self = [super init]) {
        _observer = obserser;
        _key = key;
        _block = block;
    }
    return self;
}
@end

NSString *const prefixName = @"RCKVONotifiying_";
NSString *const observersKey = @"RCObservers";

#pragma mark -------------- tool ---------------

/**
 设置setter方法名字

 @param setterName 方法名字不带set
 @return 带有set的方法名字
 */
static NSString *getSetterName(NSString *setterName){
    if (setterName.length <= 0) {
        NSLog(@"setter name must is not nil");
        return nil;
    }
    NSString *first = [[setterName substringToIndex:1] uppercaseString];
    NSString *second = [setterName substringFromIndex:1];
    NSString *setterMethodName = [ NSString stringWithFormat:@"set%@%@:",first,second];
    return setterMethodName;
}

static Class kvo_class(id self,SEL _cmd){
    return class_getSuperclass(objc_getClass((__bridge void *)self));
}

/**
 获取原始的key名字

 @param setter set 方法的名字
 @return 原key值
 */
static NSString *Key_name(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"] ) {
        NSLog(@"setter is inviable");
        return nil;
    }
    NSRange keyRange = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:keyRange];
    NSString *first = [[key substringToIndex:1] lowercaseString];
    NSString *oriKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:first];
    return oriKey;
}

/**
 触发原始setter方法，并通过block返回新的监听值
 */
static void KVO_FireSetter(id self,SEL _cmd , id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *key = Key_name(setterName);
    if (!key) {
        NSLog(@"key is nil");
        return;
    }
    struct objc_super supperClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    void (*objc_msgSendFireSuper)(void *,SEL , id) = (void *)objc_msgSendSuper;
    id oldValue = [self valueForKey:key];
    objc_msgSendFireSuper(&supperClass,_cmd,newValue);
    NSMutableArray *observers = objc_getAssociatedObject(self, &observersKey);
    for (RCObserverInfo *info in observers) {
        if ([info.key isEqualToString:key]) {
            if (info.block) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    info.block(self, key, oldValue, newValue);
                });
                break;
            }
        }
    }
    
}
@implementation NSObject (RCKVO)
-(void)rc_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(RCObserverBlock)block{
    NSString *setterName = getSetterName(key);
    SEL setter = NSSelectorFromString(setterName);
    Method setterMethod = class_getInstanceMethod([self class], setter);
    if (setterMethod == nil) {
        NSString *des = [NSString stringWithFormat:@"method %@ is nil",setterMethod];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:des userInfo:nil];
        return;
    }
    RCObserverInfo *info = [[RCObserverInfo alloc] initWithObserver:observer forKey:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, &observersKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, &observersKey, observers,  OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
    Class selfClass = object_getClass(self);
    Class newClass ;
    NSString *selfClassName = NSStringFromClass(selfClass);
    if (![selfClassName hasPrefix:prefixName]) {
        newClass = [self createKVONotifiyingClass:selfClassName];
        object_setClass(self, newClass);
    }
    if (![self hasSelector:setter]) {
        const char* types =  method_getTypeEncoding(setterMethod);
        class_addMethod(newClass, setter, (IMP)KVO_FireSetter, types);
    }
}
- (Class)createKVONotifiyingClass:(NSString *)className{
    NSString *kvoName =[prefixName stringByAppendingString:className];
    Class kvoClass = NSClassFromString(kvoName);
    if (kvoClass) {
        return kvoClass;
    }
    Class oriClass = NSClassFromString(className);
    Method method = class_getInstanceMethod(oriClass, @selector(class));
    
    Class kvoNotifiyingClass = objc_allocateClassPair(oriClass, kvoName.UTF8String, 0);
    const char * type =method_getTypeEncoding(method);
    class_addMethod(kvoNotifiyingClass, @selector(class), (IMP)kvo_class, type);
    objc_registerClassPair(kvoNotifiyingClass);
    return kvoNotifiyingClass;
    
}
- (BOOL)hasSelector:(SEL)selector{
    unsigned int count;
    Class selfClass = objc_getClass((__bridge void *)self);
    Method *methodList = class_copyMethodList(selfClass, &count);
    for (NSInteger i = 0; i < count ; i ++) {
        SEL _sel = method_getName(methodList[i]);
        if (_sel == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}
@end

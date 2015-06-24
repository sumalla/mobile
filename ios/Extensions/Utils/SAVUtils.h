//
//  SAVUtils.h
//  SavantExtensions
//
//  Created by Nathan Trapp on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
@import ObjectiveC.runtime;

#define SAVWeakVar(strongVar, weakVar) __weak __typeof__(strongVar) weakVar = strongVar
#define SAVWeakSelf SAVWeakVar(self, wSelf)

#define SAVStrongVar(weakVar, strongVar) __strong __typeof__(weakVar) strongVar = weakVar
#define SAVStrongSelf SAVStrongVar(self, sSelf)
#define SAVStrongWeakSelf SAVStrongVar(wSelf, sSelf)

#define SAVFunctionForSelector(functionName, object, selector, returnType, ...) \
\
returnType (*functionName)(id, SEL, ##__VA_ARGS__) = (returnType (*)(id, SEL, ##__VA_ARGS__))[object methodForSelector:selector]

#define SAVSynthesizeCategoryProperty(getter, setter, type, association) \
\
- (void)setter:(type)getter \
{ \
objc_setAssociatedObject(self, @selector(getter), getter, association); \
} \
\
- (type)getter \
{ \
return objc_getAssociatedObject(self, @selector(getter)); \
}

#define dispatch_next_runloop(block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);

#define SAVReplaceClassMethodOnClassWithBlock(c, sel, block) SAVReplaceWithBlock(c, c, sel, block, YES);
#define SAVReplaceMethodOnClassWithBlock(c, sel, block) SAVReplaceWithBlock(c, c, sel, block, NO);
#define SAVReplaceMethodWithBlock(obj, sel, block) SAVReplaceWithBlock([obj class], [obj class], sel, block, NO);
#define SAVReplaceClassMethodWithBlock(obj, sel, block) SAVReplaceWithBlock([obj class], object_getClass(obj), sel, block, YES);

#define SAVReplaceMethodWithMethod(c, sel, sel2) SAVExchangeWithMethod(c, sel, sel2, NO);
#define SAVReplaceClassMethodWithMethod(c, sel, sel2) SAVExchangeWithMethod(c, sel, sel2, YES);

NS_INLINE void SAVExchangeWithMethod(Class c, SEL originalSelector, SEL replacementSelector, BOOL classMethod)
{
    Method originalMethod = classMethod ? class_getClassMethod(c, originalSelector) : class_getInstanceMethod(c, originalSelector);
    NSCParameterAssert(originalMethod);

    Method newMethod = classMethod ? class_getClassMethod(c, replacementSelector) : class_getInstanceMethod(c, replacementSelector);
    NSCParameterAssert(newMethod);

    // TODO: change this to use replaceMethod, as it's safer
    method_exchangeImplementations(originalMethod, newMethod);
}

NS_INLINE IMP SAVReplaceWithBlock(Class c, Class metaClass, SEL originalSelector, id block, BOOL classMethod)
{
    NSCParameterAssert(block);

    // get original method
    Method originalMethod = classMethod ? class_getClassMethod(c, originalSelector) : class_getInstanceMethod(c, originalSelector);
    NSCParameterAssert(originalMethod);

    // convert block to IMP and replace method implementation
    IMP newImplementation = imp_implementationWithBlock(block);

    // Try adding the method if not yet in the current class
    if (!class_addMethod(metaClass, originalSelector, newImplementation, method_getTypeEncoding(originalMethod)))
    {
        return method_setImplementation(originalMethod, newImplementation);
    }
    else
    {
        return method_getImplementation(originalMethod);
    }
}

NS_INLINE void dispatch_async_global(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

NS_INLINE void dispatch_async_main(dispatch_block_t block)
{
    dispatch_async(dispatch_get_main_queue(), block);
}

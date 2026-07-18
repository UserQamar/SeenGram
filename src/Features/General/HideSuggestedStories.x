#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

static BOOL sciIsHexUUIDString(NSString *string) {
    if (string.length != 32) {
        return NO;
    }

    static NSCharacterSet *nonHexCharacters;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        nonHexCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    });

    return [string rangeOfCharacterFromSet:nonHexCharacters].location == NSNotFound;
}

static BOOL sciIsSuggestedTrayItem(id object) {

    @try {

        if (![NSStringFromClass([object class]) isEqualToString:@"IGStoryTrayViewModel"]) {
            return NO;
        }

        if ([[object valueForKey:@"isCurrentUserReel"] boolValue]) {
            return NO;
        }

        NSString *diffIdentifier = nil;

        @try {
            if ([object respondsToSelector:@selector(diffIdentifier)]) {
                diffIdentifier = [[object performSelector:@selector(diffIdentifier)] description];
            }
        }
        @catch (__unused NSException *exception) {
        }

        if (!sciIsHexUUIDString(diffIdentifier)) {
            return NO;
        }

        id owner = [object valueForKey:@"reelOwner"];

        if (!owner) {
            return NO;
        }

        Ivar userIvar = class_getInstanceVariable([owner class], "_userReelOwner_user");

        if (!userIvar) {
            return NO;
        }

        id user = object_getIvar(owner, userIvar);

        if (!user) {
            return NO;
        }

        Ivar fieldCacheIvar = NULL;

        for (Class cls = [user class]; cls && !fieldCacheIvar; cls = class_getSuperclass(cls)) {
            fieldCacheIvar = class_getInstanceVariable(cls, "_fieldCache");
        }

        if (!fieldCacheIvar) {
            return NO;
        }

        id fieldCache = object_getIvar(user, fieldCacheIvar);

        if (![fieldCache isKindOfClass:[NSDictionary class]]) {
            return NO;
        }

        id friendshipStatus = [(NSDictionary *)fieldCache objectForKey:@"friendship_status"];

        if (!friendshipStatus) {
            return NO;
        }

        return ![[friendshipStatus valueForKey:@"following"] boolValue];

    }
    @catch (__unused NSException *exception) {
        return NO;
    }
}


static NSArray *(*orig_objectsForListAdapter)(id, SEL, id);

static NSArray *hook_objectsForListAdapter(id self, SEL selector, id adapter) {

    NSArray *objects = orig_objectsForListAdapter(self, selector, adapter);

    if (![SCIUtils getBoolPref:@"hide_suggested_stories"]) {
        return objects;
    }

    NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:objects.count];

    for (id object in objects) {

        if (!sciIsSuggestedTrayItem(object)) {
            [filteredObjects addObject:object];
        }
    }

    return [filteredObjects copy];
}


%ctor {

    Class cls = NSClassFromString(@"IGStoryTrayListAdapterDataSource");

    if (!cls) {
        return;
    }

    SEL selector = NSSelectorFromString(@"objectsForListAdapter:");

    Method method = class_getInstanceMethod(cls, selector);

    if (!method) {
        return;
    }

    MSHookMessageEx(
        cls,
        selector,
        (IMP)hook_objectsForListAdapter,
        (IMP *)&orig_objectsForListAdapter
    );
}
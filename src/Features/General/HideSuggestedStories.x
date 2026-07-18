// Hide suggested stories from the feed tray.
// The adapter hook is shared with profile highlights, so we identify only
// suggested items using diffIdentifier. Suggested items use a 32-char hex UUID,
// real users use numeric PKs, and highlights use "highlight:<pk>".
// Anything ambiguous is kept by default.

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

        nonHexCharacters =
        [[NSCharacterSet characterSetWithCharactersInString:
          @"0123456789abcdefABCDEF"] invertedSet];

    });


    return [string rangeOfCharacterFromSet:nonHexCharacters].location == NSNotFound;
}



static BOOL sciIsSuggestedTrayItem(id object) {

    if (!object) {
        return NO;
    }


    @try {

        if (![[NSStringFromClass([object class])]
              isEqualToString:@"IGStoryTrayViewModel"]) {

            return NO;
        }



        if ([[object valueForKey:@"isCurrentUserReel"] boolValue]) {
            return NO;
        }



        NSString *diffIdentifier = nil;


        @try {

            if ([object respondsToSelector:@selector(diffIdentifier)]) {

                diffIdentifier =
                [[object performSelector:@selector(diffIdentifier)] description];

            }

        }
        @catch (__unused NSException *exception) {

        }



        if (!sciIsHexUUIDString(diffIdentifier)) {
            return NO;
        }



        id reelOwner = [object valueForKey:@"reelOwner"];

        if (!reelOwner) {
            return NO;
        }



        Ivar userOwnerIvar =
        class_getInstanceVariable([reelOwner class],
                                  "_userReelOwner_user");


        if (!userOwnerIvar) {
            return NO;
        }



        id user = object_getIvar(reelOwner, userOwnerIvar);


        if (!user) {
            return NO;
        }



        Ivar fieldCacheIvar = NULL;


        for (Class cls = [user class];
             cls && !fieldCacheIvar;
             cls = class_getSuperclass(cls)) {

            fieldCacheIvar =
            class_getInstanceVariable(cls, "_fieldCache");

        }



        if (!fieldCacheIvar) {
            return NO;
        }



        id fieldCache =
        object_getIvar(user, fieldCacheIvar);



        if (![fieldCache isKindOfClass:[NSDictionary class]]) {
            return NO;
        }



        id friendshipStatus =
        [(NSDictionary *)fieldCache objectForKey:@"friendship_status"];



        if (!friendshipStatus) {
            return NO;
        }



        // Suggested stories are accounts that are not already followed.
        return ![[friendshipStatus valueForKey:@"following"] boolValue];


    }
    @catch (__unused NSException *exception) {

        return NO;

    }
}



static NSArray *(*orig_objectsForListAdapter)(id, SEL, id);


static NSArray *hook_objectsForListAdapter(id self,
                                           SEL selector,
                                           id adapter) {


    NSArray *objects =
    orig_objectsForListAdapter(self,
                               selector,
                               adapter);



    if (!objects ||
        ![SCIUtils getBoolPref:@"hide_suggested_stories"]) {

        return objects;
    }



    BOOL containsSuggested = NO;


    for (id object in objects) {

        if (sciIsSuggestedTrayItem(object)) {

            containsSuggested = YES;
            break;

        }

    }



    if (!containsSuggested) {
        return objects;
    }



    NSMutableArray *filtered =
    [NSMutableArray arrayWithCapacity:objects.count];



    for (id object in objects) {

        if (!sciIsSuggestedTrayItem(object)) {

            [filtered addObject:object];

        }

    }



    return [filtered copy];
}



__attribute__((constructor))
static void sciHideSuggestedStoriesInit(void) {

    Class cls =
    NSClassFromString(@"IGStoryTrayListAdapterDataSource");


    if (!cls) {
        return;
    }



    SEL selector =
    NSSelectorFromString(@"objectsForListAdapter:");



    Method method =
    class_getInstanceMethod(cls, selector);



    if (!method) {
        return;
    }



    MSHookMessageEx(cls,
                    selector,
                    (IMP)hook_objectsForListAdapter,
                    (IMP *)&orig_objectsForListAdapter);
}
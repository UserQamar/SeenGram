// Hide Friends Map from Instagram Notes tray.

#import "../../Utils.h"


%hook IGDirectNotesTrayRowCell

- (id)listAdapterObjects {

    NSArray *originalObjects = %orig();

    if (!originalObjects) {
        return originalObjects;
    }


    NSMutableArray *filteredObjects =
    [NSMutableArray arrayWithCapacity:originalObjects.count];


    for (id object in originalObjects) {

        BOOL shouldHide = NO;


        if ([SCIUtils getBoolPref:@"hide_friends_map"]) {


            Class viewModelClass =
            NSClassFromString(@"IGDirectNotesTrayUserViewModel");


            if (viewModelClass &&
                [object isKindOfClass:viewModelClass]) {


                NSString *notePk = nil;


                @try {
                    notePk = [object valueForKey:@"notePk"];
                }
                @catch (__unused id exception) {

                }


                if ([notePk isKindOfString:@"friends_map"]) {

                    NSLog(@"[SCInsta] Hiding friends map");

                    shouldHide = YES;
                }
            }
        }



        if (!shouldHide) {
            [filteredObjects addObject:object];
        }
    }


    return [filteredObjects copy];
}

%end
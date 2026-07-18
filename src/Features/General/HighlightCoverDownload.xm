// View highlight cover — opens the cover image in the full-screen media viewer.

#import "../../Utils.h"
#import "../../Downloader/Download.h"
#import "../../ActionButton/SCIMediaViewer.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>


// Find the IGStoryTrayCell with an active long-press gesture
static UIView *sciFindLongPressedCell(UIView *root) {

    if (!root) {
        return nil;
    }


    Class cellClass =
    NSClassFromString(@"IGStoryTrayCell");


    if (!cellClass) {
        return nil;
    }


    NSMutableArray *stack =
    [NSMutableArray arrayWithObject:root];


    while (stack.count) {

        UIView *view =
        stack.lastObject;

        [stack removeLastObject];


        if ([view isKindOfClass:cellClass]) {

            for (UIGestureRecognizer *gesture in view.gestureRecognizers) {

                if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]] &&
                    (gesture.state == UIGestureRecognizerStateBegan ||
                     gesture.state == UIGestureRecognizerStateChanged)) {

                    return view;
                }
            }
        }


        for (UIView *subview in view.subviews) {
            [stack addObject:subview];
        }
    }


    return nil;
}



// Find the IGImageView inside a specific cell
static UIImage *sciCoverImageFromCell(UIView *cell) {

    if (!cell) {
        return nil;
    }


    Class imageViewClass =
    NSClassFromString(@"IGImageView");


    if (!imageViewClass) {
        imageViewClass = [UIImageView class];
    }


    NSMutableArray *stack =
    [NSMutableArray arrayWithObject:cell];


    while (stack.count) {

        UIView *view =
        stack.lastObject;

        [stack removeLastObject];


        if ([view isKindOfClass:imageViewClass] &&
            [view isKindOfClass:[UIImageView class]]) {


            UIImage *image =
            [(UIImageView *)view image];


            if (image && image.size.width > 10) {
                return image;
            }
        }


        for (UIView *subview in view.subviews) {
            [stack addObject:subview];
        }
    }


    return nil;
}



static void sciViewCoverImage(UIImage *image) {

    if (!image) {

        [SCIUtils showErrorHUDWithDescription:
         SCILocalized(@"Could not find cover image")];

        return;
    }


    NSData *data =
    UIImageJPEGRepresentation(image, 1.0);


    if (!data) {
        return;
    }


    NSString *filename =
    [NSString stringWithFormat:@"cover_%@.jpg",
     NSUUID.UUID.UUIDString];


    NSString *path =
    [NSTemporaryDirectory()
     stringByAppendingPathComponent:filename];


    if (![data writeToFile:path atomically:YES]) {
        return;
    }


    NSURL *url =
    [NSURL fileURLWithPath:path];


    [SCIMediaViewer showWithVideoURL:nil
                           photoURL:url
                            caption:nil];
}



// Stored reference to the long-pressed cell
static __weak UIView *sciLongPressedHighlightCell = nil;



static void (*orig_present)(id, SEL, UIViewController *, BOOL, void (^)(void));



static void new_present(id self,
                        SEL selector,
                        UIViewController *viewController,
                        BOOL animated,
                        void (^completion)(void)) {


    if ([SCIUtils getBoolPref:@"download_highlight_cover"] &&
        [NSStringFromClass([viewController class]) containsString:@"ActionSheet"] &&
        [NSStringFromClass([self class]) containsString:@"Profile"]) {


        UIViewController *controller =
        (UIViewController *)self;


        UIView *cell =
        sciFindLongPressedCell(controller.view);


        sciLongPressedHighlightCell = cell;



        if (cell) {


            Ivar actionsIvar =
            class_getInstanceVariable([viewController class],
                                      "_actions");


            NSArray *actions = nil;


            if (actionsIvar) {
                actions = object_getIvar(viewController, actionsIvar);
            }



            if (actions &&
                actions.count >= 2 &&
                actions.count <= 6) {


                Class actionClass =
                NSClassFromString(@"IGActionSheetControllerAction");



                if (actionClass) {


                    void (^handler)(void) = ^{

                        UIImage *cover =
                        sciCoverImageFromCell(
                            sciLongPressedHighlightCell
                        );


                        sciViewCoverImage(cover);
                    };



                    SEL initSelector =
                    @selector(initWithTitle:subtitle:style:handler:accessibilityIdentifier:accessibilityLabel:);



                    typedef id (*InitFunction)(
                        id,
                        SEL,
                        id,
                        id,
                        NSInteger,
                        id,
                        id,
                        id
                    );



                    id action =
                    ((InitFunction)objc_msgSend)(
                        [actionClass alloc],
                        initSelector,
                        SCILocalized(@"View cover"),
                        nil,
                        0,
                        handler,
                        nil,
                        nil
                    );



                    if (action) {

                        NSMutableArray *newActions =
                        [actions mutableCopy];


                        [newActions addObject:action];


                        object_setIvar(viewController,
                                       actionsIvar,
                                       [newActions copy]);
                    }
                }
            }
        }
    }



    orig_present(self,
                 selector,
                 viewController,
                 animated,
                 completion);
}



__attribute__((constructor))
static void sciHighlightCoverInit(void) {

    MSHookMessageEx(
        [UIViewController class],
        @selector(presentViewController:animated:completion:),
        (IMP)new_present,
        (IMP *)&orig_present
    );
}
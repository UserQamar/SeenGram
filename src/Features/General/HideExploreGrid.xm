// Explore tab hide toggles.
//   hide_explore_grid       → hides grid + shimmer loader
//   hide_trending_searches  → hides category chip bar + algo button on the right
//
// Grid revealing rules: tapping a chip or focusing the search bar counts as
// engagement and unhides the grid until the user leaves the Explore tab.

#import "../../Utils.h"
#import "../../InstagramHeaders.h"
#import <objc/runtime.h>


static BOOL sciHideGrid(void) {
    return [SCIUtils getBoolPref:@"hide_explore_grid"];
}


static BOOL sciHideSearch(void) {
    return [SCIUtils getBoolPref:@"hide_trending_searches"];
}


static __weak UIViewController *gActiveExploreVC = nil;
static BOOL gSearchFocused = NO;
static BOOL gUserEngaged = NO;


// MARK: - Hide helpers


static void sciSetViewVisuallyHidden(UIView *view, BOOL hidden) {
    if (!view) {
        return;
    }

    view.alpha = hidden ? 0.0 : 1.0;
    view.userInteractionEnabled = !hidden;
}


static void sciSetIvarViewHidden(id host, const char *name, BOOL hidden) {
    if (!host) {
        return;
    }

    Ivar ivar = class_getInstanceVariable([host class], name);

    if (!ivar) {
        return;
    }

    @try {
        UIView *view = object_getIvar(host, ivar);

        if ([view isKindOfClass:[UIView class]]) {
            sciSetViewVisuallyHidden(view, hidden);
        }

    } @catch (__unused id exception) {

    }
}


static void sciApplyExploreHide(id viewController) {

    if (!viewController) {
        return;
    }


    // Chips stay visible while search is focused.
    BOOL hideChips = sciHideSearch() && !gSearchFocused;

    sciSetIvarViewHidden(viewController,
                         "_nidoChipBar",
                         hideChips);



    // Force search title view refresh.
    Ivar searchTitleIvar =
    class_getInstanceVariable([viewController class],
                              "_searchTitleView");


    if (searchTitleIvar) {

        @try {

            UIView *titleView =
            object_getIvar(viewController, searchTitleIvar);


            if ([titleView isKindOfClass:[UIView class]]) {

                [titleView setNeedsLayout];
                [titleView layoutIfNeeded];

            }

        } @catch (__unused id exception) {

        }
    }



    // Grid reveals after interaction.
    BOOL hideGrid =
    sciHideGrid() &&
    !gUserEngaged &&
    !gSearchFocused;


    sciSetIvarViewHidden(viewController,
                         "_shimmeringGridView",
                         hideGrid);



    Ivar gridControllerIvar =
    class_getInstanceVariable([viewController class],
                              "_gridViewController");


    if (!gridControllerIvar) {
        return;
    }


    @try {

        UIViewController *gridController =
        object_getIvar(viewController,
                       gridControllerIvar);


        if (![gridController isKindOfClass:[UIViewController class]] ||
            !gridController.isViewLoaded) {
            return;
        }


        sciSetViewVisuallyHidden(gridController.view,
                                 hideGrid);



        Ivar collectionIvar =
        class_getInstanceVariable([gridController class],
                                  "_collectionView");


        if (collectionIvar) {

            UIView *collection =
            object_getIvar(gridController,
                           collectionIvar);


            if ([collection isKindOfClass:[UIView class]]) {

                sciSetViewVisuallyHidden(collection,
                                         hideGrid);

            }
        }


    } @catch (__unused id exception) {

    }
}



// Determines IG algorithm button from Cancel button.
static BOOL sciIsAlgoButton(UIView *button) {

    if (!button) {
        return NO;
    }


    if (button.bounds.size.width != button.bounds.size.height) {
        return NO;
    }


    for (UIView *subview in button.subviews) {

        if ([subview isKindOfClass:[UILabel class]]) {
            return NO;
        }

    }


    return YES;
}



// MARK: - Hooks


%group HideExploreGroup


%hook IGExploreViewController


- (void)viewDidLayoutSubviews {

    %orig;

    gActiveExploreVC = self;

    sciApplyExploreHide(self);
}



- (void)viewWillAppear:(BOOL)animated {

    %orig(animated);

    gActiveExploreVC = self;

    sciApplyExploreHide(self);
}



- (void)viewDidDisappear:(BOOL)animated {

    %orig(animated);

    gUserEngaged = NO;
    gSearchFocused = NO;
}



- (void)exploreChipBarView:(id)bar didSelectChipAtIndex:(NSInteger)index {

    %orig(bar, index);

    gUserEngaged = YES;

    sciApplyExploreHide(self);

    [self.view setNeedsLayout];
}


%end



%hook IGAnimatablePlaceholderTextField


- (BOOL)becomeFirstResponder {

    BOOL result = %orig;

    gSearchFocused = YES;


    if (gActiveExploreVC) {

        sciApplyExploreHide(gActiveExploreVC);

        [gActiveExploreVC.view setNeedsLayout];

    }


    return result;
}



- (BOOL)resignFirstResponder {

    BOOL result = %orig;

    gSearchFocused = NO;


    if (gActiveExploreVC) {

        sciApplyExploreHide(gActiveExploreVC);

        [gActiveExploreVC.view setNeedsLayout];

    }


    return result;
}


%end




%hook IGExploreSearchTitleView


- (void)layoutSubviews {

    %orig;


    BOOL hide = sciHideSearch();


    Class tapButtonClass =
    NSClassFromString(@"IGTapButton");


    Class dotClass =
    NSClassFromString(@"IGDSDotView");


    Class searchBarClass =
    NSClassFromString(@"IGSearchBar");


    UIView *searchBar = nil;



    for (UIView *subview in self.subviews) {


        if (searchBarClass &&
            [subview isKindOfClass:searchBarClass]) {

            searchBar = subview;

        }


        else if (tapButtonClass &&
                 [subview isKindOfClass:tapButtonClass] &&
                 sciIsAlgoButton(subview)) {

            subview.hidden = hide;

        }


        else if (dotClass &&
                 [subview isKindOfClass:dotClass]) {

            subview.hidden = hide;

        }
    }



    if (searchBar && hide) {

        CGFloat width = self.bounds.size.width;


        if (searchBar.frame.size.width != width) {

            CGRect frame = searchBar.frame;

            frame.size.width = width;

            searchBar.frame = frame;

        }
    }
}


%end


%end // HideExploreGroup



__attribute__((constructor))
static void sciExploreHideInit(void) {

    if ([SCIUtils getBoolPref:@"hide_explore_grid"] ||
        [SCIUtils getBoolPref:@"hide_trending_searches"]) {

        %init(HideExploreGroup);

    }
}
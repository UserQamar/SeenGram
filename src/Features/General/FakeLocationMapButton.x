// Quick fake-location toggle injected into IG's Friends Map (DMs > Maps).

#import "../../Utils.h"
#import "../../SCIChrome.h"
#import "../../Settings/SCIFakeLocationSettingsVC.h"
#import "../../Settings/SCIFakeLocationPickerVC.h"

#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>


static const NSInteger kSciMapBtnTag = 0x5C1F4B;
static const NSInteger kSciMapHitBtnTag = 0x5C1F4C;


static UIViewController *sciTopMost(void) {
    UIWindow *window = nil;

    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }

        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }

        if (window) {
            break;
        }
    }

    UIViewController *controller = window.rootViewController;

    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }

    return controller;
}


static void sciRefreshMapButton(UIView *mapView);
static void sciAddMapButton(UIView *mapView);
static void sciRemoveMapButton(UIView *mapView);
static UIMenu *sciBuildMapMenu(void);


static void sciWalkMapViews(UIView *root, Class mapClass, void (^block)(UIView *)) {
    if (!root) {
        return;
    }

    if (mapClass && [root isKindOfClass:mapClass]) {
        block(root);
    }

    for (UIView *subview in root.subviews) {
        sciWalkMapViews(subview, mapClass, block);
    }
}


static void sciRefreshActiveMapButton(void) {
    Class mapClass = NSClassFromString(@"IGFriendsMapCoreUI.IGFriendsMapView");

    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }

        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            sciWalkMapViews(window, mapClass, ^(UIView *mapView) {

                if (![SCIUtils getBoolPref:@"show_fake_location_map_button"]) {
                    sciRemoveMapButton(mapView);
                }
                else {
                    sciAddMapButton(mapView);
                    sciRefreshMapButton(mapView);
                }

            });
        }
    }
}


static void sciOpenPickerForCurrent(void) {
    UIViewController *top = sciTopMost();

    if (!top) {
        return;
    }

    SCIFakeLocationPickerVC *vc = [SCIFakeLocationPickerVC new];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    vc.initialCoord = CLLocationCoordinate2DMake(
        [[defaults objectForKey:@"fake_location_lat"] doubleValue],
        [[defaults objectForKey:@"fake_location_lon"] doubleValue]
    );

    vc.titleText = SCILocalized(@"Set location");

    vc.onPick = ^(double lat, double lon, NSString *name) {

        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

        [prefs setObject:@(lat) forKey:@"fake_location_lat"];
        [prefs setObject:@(lon) forKey:@"fake_location_lon"];
        [prefs setObject:name ?: @"" forKey:@"fake_location_name"];

        if (![prefs boolForKey:@"fake_location_enabled"]) {
            [prefs setBool:YES forKey:@"fake_location_enabled"];
        }

        sciRefreshActiveMapButton();
    };


    UINavigationController *nav =
    [[UINavigationController alloc] initWithRootViewController:vc];

    nav.modalPresentationStyle = UIModalPresentationPageSheet;

    [top presentViewController:nav animated:YES completion:nil];
}


static void sciOpenPickerForNewPreset(void) {
    UIViewController *top = sciTopMost();

    if (!top) {
        return;
    }

    SCIFakeLocationPickerVC *vc = [SCIFakeLocationPickerVC new];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    vc.initialCoord = CLLocationCoordinate2DMake(
        [[defaults objectForKey:@"fake_location_lat"] doubleValue],
        [[defaults objectForKey:@"fake_location_lon"] doubleValue]
    );

    vc.titleText = SCILocalized(@"Add preset");


    vc.onPick = ^(double lat, double lon, NSString *name) {

        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:SCILocalized(@"Save preset")
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];


        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.placeholder = SCILocalized(@"Name");
            field.text = name;
        }];


        [alert addAction:
         [UIAlertAction actionWithTitle:SCILocalized(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];


        [alert addAction:
         [UIAlertAction actionWithTitle:SCILocalized(@"Save")
                                  style:UIAlertActionStyleDefault
                                handler:^(__unused UIAlertAction *action) {

            NSString *presetName =
            alert.textFields.firstObject.text.length ?
            alert.textFields.firstObject.text :
            name;


            NSUserDefaults *prefs =
            [NSUserDefaults standardUserDefaults];


            NSArray *old =
            [prefs objectForKey:@"fake_location_presets"];


            NSMutableArray *presets =
            [old isKindOfClass:[NSArray class]] ?
            [old mutableCopy] :
            [NSMutableArray array];


            [presets addObject:@{
                @"name": presetName ?: @"",
                @"lat": @(lat),
                @"lon": @(lon)
            }];


            [prefs setObject:presets forKey:@"fake_location_presets"];

            sciRefreshActiveMapButton();

        }]];


        [sciTopMost() presentViewController:alert
                                   animated:YES
                                 completion:nil];
    };


    UINavigationController *nav =
    [[UINavigationController alloc] initWithRootViewController:vc];

    nav.modalPresentationStyle = UIModalPresentationPageSheet;

    [top presentViewController:nav animated:YES completion:nil];
}


static UIMenu *sciBuildMapMenu(void) {

    NSUserDefaults *defaults =
    [NSUserDefaults standardUserDefaults];


    BOOL enabled =
    [defaults boolForKey:@"fake_location_enabled"];


    NSString *name =
    [defaults objectForKey:@"fake_location_name"] ?: @"(unset)";


    UIAction *header =
    [UIAction actionWithTitle:
     [NSString stringWithFormat:SCILocalized(@"Current: %@"), name]
                       image:[UIImage systemImageNamed:@"mappin.and.ellipse"]
                  identifier:nil
                     handler:^(__unused UIAction *action) {}];


    header.attributes = UIMenuElementAttributesDisabled;


    UIAction *toggle =
    [UIAction actionWithTitle:
     (enabled ? SCILocalized(@"Disable") : SCILocalized(@"Enable"))
                       image:[UIImage systemImageNamed:
                              (enabled ? @"location.slash.fill" :
                               @"location.fill")]
                  identifier:nil
                     handler:^(__unused UIAction *action) {

        [defaults setBool:!enabled forKey:@"fake_location_enabled"];

        sciRefreshActiveMapButton();
    }];


    if (enabled) {
        toggle.attributes = UIMenuElementAttributesDestructive;
    }


    UIAction *change =
    [UIAction actionWithTitle:SCILocalized(@"Change location")
                        image:[UIImage systemImageNamed:@"map"]
                   identifier:nil
                      handler:^(__unused UIAction *action) {

        sciOpenPickerForCurrent();

    }];


    UIMenu *headerMenu =
    [UIMenu menuWithTitle:@""
                    image:nil
               identifier:nil
                  options:UIMenuOptionsDisplayInline
                children:@[
                    header,
                    toggle,
                    change
                ]];


    NSMutableArray *presetItems = [NSMutableArray array];


    NSArray *presets =
    [defaults objectForKey:@"fake_location_presets"];


    if ([presets isKindOfClass:[NSArray class]]) {

        for (NSDictionary *preset in presets) {

            if (![preset isKindOfClass:[NSDictionary class]]) {
                continue;
            }


            NSString *presetName =
            preset[@"name"] ?: @"Preset";


            UIAction *action =
            [UIAction actionWithTitle:presetName
                                image:[UIImage systemImageNamed:@"mappin.circle.fill"]
                           identifier:nil
                              handler:^(__unused UIAction *x) {

                [defaults setObject:preset[@"lat"]
                             forKey:@"fake_location_lat"];

                [defaults setObject:preset[@"lon"]
                             forKey:@"fake_location_lon"];

                [defaults setObject:preset[@"name"] ?: @""
                             forKey:@"fake_location_name"];


                if (![defaults boolForKey:@"fake_location_enabled"]) {
                    [defaults setBool:YES
                               forKey:@"fake_location_enabled"];
                }


                sciRefreshActiveMapButton();

            }];


            if ([preset[@"name"] isEqualToString:name]) {
                action.state = UIMenuElementStateOn;
            }


            [presetItems addObject:action];
        }
    }


    [presetItems addObject:
     [UIAction actionWithTitle:SCILocalized(@"Add location")
                         image:[UIImage systemImageNamed:@"plus.circle.fill"]
                    identifier:nil
                       handler:^(__unused UIAction *x) {

        sciOpenPickerForNewPreset();

    }]];


    UIMenu *presetMenu =
    [UIMenu menuWithTitle:SCILocalized(@"Saved locations")
                    image:nil
               identifier:nil
                  options:UIMenuOptionsDisplayInline
                children:presetItems];


    UIAction *settings =
    [UIAction actionWithTitle:SCILocalized(@"Settings…")
                        image:[UIImage systemImageNamed:@"gearshape.fill"]
                   identifier:nil
                      handler:^(__unused UIAction *x) {

        UIViewController *top = sciTopMost();

        if (!top) {
            return;
        }


        SCIFakeLocationSettingsVC *vc =
        [SCIFakeLocationSettingsVC new];


        UINavigationController *nav =
        [[UINavigationController alloc]
         initWithRootViewController:vc];


        nav.modalPresentationStyle =
        UIModalPresentationFormSheet;


        [top presentViewController:nav
                          animated:YES
                        completion:nil];

    }];


    UIMenu *settingsMenu =
    [UIMenu menuWithTitle:@""
                    image:nil
               identifier:nil
                  options:UIMenuOptionsDisplayInline
                children:@[settings]];


    return [UIMenu menuWithTitle:SCILocalized(@"Fake location")
                           image:nil
                      identifier:nil
                         options:0
                       children:@[
                           headerMenu,
                           presetMenu,
                           settingsMenu
                       ]];
}
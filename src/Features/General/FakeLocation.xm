```objc
// Fake location — overrides CLLocationManager so any IG location read returns our coord.

#import "../../Utils.h"
#import <CoreLocation/CoreLocation.h>
#import <objc/message.h>

static BOOL sciFakeLocOn(void) {
    return [SCIUtils getBoolPref:@"fake_location_enabled"];
}

static CLLocation *sciFakeLocation(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    double latitude = [[defaults objectForKey:@"fake_location_lat"] doubleValue];
    double longitude = [[defaults objectForKey:@"fake_location_lon"] doubleValue];

    return [[CLLocation alloc] initWithCoordinate:
            CLLocationCoordinate2DMake(latitude, longitude)
                                           altitude:35
                                 horizontalAccuracy:5
                                   verticalAccuracy:5
                                          timestamp:[NSDate date]];
}

static void sciFeedFake(CLLocationManager *manager) {
    id<CLLocationManagerDelegate> delegate = manager.delegate;

    if (![delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        return;
    }

    CLLocation *location = sciFakeLocation();
    NSArray *locations = @[location];

    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate locationManager:manager didUpdateLocations:locations];
    });
}


%hook CLLocationManager

- (CLLocation *)location {
    if (sciFakeLocOn()) {
        return sciFakeLocation();
    }

    return %orig;
}


- (void)startUpdatingLocation {
    %orig;

    if (sciFakeLocOn()) {
        sciFeedFake(self);
    }
}


- (void)requestLocation {
    if (sciFakeLocOn()) {
        sciFeedFake(self);
        return;
    }

    %orig;
}

%end
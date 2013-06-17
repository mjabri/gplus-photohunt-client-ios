//
//  ActivityView.h
//  PhotoHunt

#import <GoogleOpenSource/GoogleOpenSource.h>
#import "ImageCache.h"
#import <UIKit/UIKit.h>

// View to display an app activity.
@interface ActivityView : UIView

// New initialiser that sets up an activity view
- (id)initWithActivity:(GTLPlusMoment *)activity
              useCache:(ImageCache *)cache;

@property (nonatomic, strong) GTLPlusMoment *activity;

@end

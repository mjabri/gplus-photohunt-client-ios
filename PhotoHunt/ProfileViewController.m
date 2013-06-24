//
//  ProfileViewController.m
//  PhotoHunt

#import "FSHClient.h"
#import "ActivityView.h"
#import "AppDelegate.h"
#import "ProfileObj.h"
#import "FriendsObj.h"
#import "GTLQueryFSH.h"
#import "ImageCache.h"
#import "ProfileViewController.h"

@implementation ProfileViewController

static const NSInteger kProfileImageSize = 110;
static const NSInteger kFriendImageSize = 50;
static const NSInteger kFriendImageMarginSize = 5;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  return [self initWithNibName:nibNameOrNil
                        bundle:nibBundleOrNil
                          user:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
                 user:(ProfileObj *)user {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.user = user;
  }
  return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]
                                               delegate];
    ImageCache *cache = appDelegate.imageCache;
    
    self.trackedViewName = @"viewActivities";
    
    [self setTitle:self.user.googleDisplayName];
    NSString *profileUrl = [cache getResizeUrl:self.user.googlePublicProfilePhotoUrl
                                      forWidth:kProfileImageSize
                                     andHeight:kProfileImageSize];
    [cache setImageView:self.profilePictureView
                 forURL:profileUrl
            withSpinner:self.userSpinner];
    
    [[FSHClient sharedClient] getPath:@"api/friends" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        self.friends = [[FriendsObj alloc] initWithJson:JSON];
        [self.friendsSpinner stopAnimating];
        NSInteger count = 0;
        CGFloat width = kFriendImageMarginSize + kFriendImageSize;
        for (ProfileObj *friend in self.friends.items) {
            // Split friend images across two rows.
            CGFloat y = count % 2 == 0 ? 0 : width;
            y += kFriendImageMarginSize;
            CGFloat x = floor(count / 2) * width;
            UIImageView *profileImage = [[UIImageView alloc]
                                         initWithFrame:CGRectMake(
                                                                  x,
                                                                  y,
                                                                  kFriendImageSize,
                                                                  kFriendImageSize)];
            if (friend.googlePublicProfilePhotoUrl) {
                NSString *friendUrl = [cache getResizeUrl:friend.googlePublicProfilePhotoUrl
                                                 forWidth:kFriendImageSize
                                                andHeight:kFriendImageSize];
                [cache setImageView:profileImage
                             forURL:friendUrl
                        withSpinner:nil];
                [profileImage setContentMode:UIViewContentModeScaleAspectFill];
                [profileImage setClipsToBounds:YES];
                [self.friendView addSubview:profileImage];
                count++;
            }
        }
        CGSize sz = CGSizeMake(floor(count/2) * width, kProfileImageSize);
        [self.friendView setContentSize:sz];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        return;
    }];

  // Load moments.
  self.plusService = [[GTLServicePlus alloc] init];
  self.plusService.retryEnabled = YES;
  [self.plusService setAuthorizer:appDelegate.userManager.currentAuth];

  GTLQueryPlus *query = [GTLQueryPlus
      queryForMomentsListWithUserId:@"me"
                         collection:kGTLPlusCollectionVault];

  [self.plusService executeQuery:query
               completionHandler:^(GTLServiceTicket *ticket,
                                   id object,
                                   NSError *error) {
    if (error) {
      GTMLoggerDebug(@"Status: Error: %@", error);
    } else {
      self.activities = (GTLPlusMomentsFeed *)object;
      [self.activitiesSpinner stopAnimating];
      [self.activitiesView reloadData];
    }
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [self.activities.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]
                                             delegate];
  ImageCache *cache = appDelegate.imageCache;

  NSString *cellIdentifier =[NSString
                                stringWithFormat:@"app-activity-%d",
                                [indexPath row]];
  UITableViewCell *cell = [tableView
                           dequeueReusableCellWithIdentifier:cellIdentifier];

  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:cellIdentifier];
  }

  NSInteger row = [indexPath row];
  GTLPlusMoment *activity = [self.activities.items objectAtIndex:row];
  ActivityView *av = [[ActivityView alloc] initWithActivity:activity
                                                    useCache:cache];
  [cell.contentView addSubview:av];

  return cell;
}

@end

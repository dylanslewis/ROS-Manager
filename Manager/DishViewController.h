//
//  DishViewController.h
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DishViewController : PFQueryTableViewController

- (void)setCurrentCourse:(PFObject *)course;

@property (strong, nonatomic) PFObject *currentCourse;

@end

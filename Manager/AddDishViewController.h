//
//  AddDishViewController.h
//  Manager
//
//  Created by Dylan Lewis on 23/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface AddDishViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    __weak IBOutlet UITableView *dishOptionsTableView;
}

@property (strong, nonatomic) PFObject *courseForDish;

@property (strong, nonatomic) PFObject *currentDish;

@end

//
//  DishTableViewCell.h
//  Manager
//
//  Created by Dylan Lewis on 23/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DishTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dishNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;

@property (weak, nonatomic) IBOutlet UILabel *dishOptionsLabel;

@property (weak, nonatomic) PFObject *dishObject;

@end
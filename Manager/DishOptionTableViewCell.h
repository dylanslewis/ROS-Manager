//
//  DishOptionTableViewCell.h
//  Manager
//
//  Created by Dylan Lewis on 25/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DishOptionTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dishOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *dishPriceLabel;

@property (weak, nonatomic) IBOutlet UIButton *removeDishOptionButton;

@end

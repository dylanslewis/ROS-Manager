//
//  OrderTableViewCell.h
//  Manager
//
//  Created by Dylan Lewis on 07/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *tableNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemsOrderedLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemsDeliveredLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentCourseLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderPriceLabel;


@end

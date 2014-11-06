//
//  OverviewViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "OverviewViewController.h"
#import "OrderTableViewCell.h"
#import "ViewOrderViewController.h"
#import "UIColor+ApplicationColours.h"

@interface OverviewViewController ()

@property (strong, nonatomic) NSArray *ordersArray;
@property (strong, nonatomic) NSMutableDictionary *ordersByWaiter;

@property (strong, nonatomic) PFObject *currentOrder;

@end

@implementation OverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getParseData];
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUserSegue" sender:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Parse

- (void)getParseData {
    // Get order items for this order.
    PFQuery *getOrderItems = [PFQuery queryWithClassName:@"Order"];
    [getOrderItems whereKey:@"state" notEqualTo:@"paid"];
    
    [getOrderItems findObjectsInBackgroundWithBlock:^(NSArray *orders, NSError *error) {
        if (!error) {
            // Create an array of all order items.
            _ordersArray = [[NSArray alloc] initWithArray:orders];
            _ordersByWaiter = [[NSMutableDictionary alloc] init];
            
            // Go through the 'raw' list of orders.
            for (NSDictionary *order in _ordersArray) {
                // Extract the current item's course.
                NSString *waiterName=order[@"waiterName"];
                                
                // If we don't already have this waiter, add it.
                if (![[_ordersByWaiter allKeys] containsObject:waiterName]) {
                    // Create an array containing the current order item object.
                    NSMutableArray *ordersForWaiter = [[NSMutableArray alloc] initWithObjects:order, nil];
                    
                    [_ordersByWaiter setObject:ordersForWaiter forKey:waiterName];
                } else {
                    // If the key (i.e. course) already exists, add this order item to its array.
                    NSMutableArray *ordersForWaiter = [_ordersByWaiter valueForKey:waiterName];
                    [ordersForWaiter addObject:order];
                    
                    [_ordersByWaiter setObject:ordersForWaiter forKey:waiterName];
                }
            }
        }
        
        // Reload the table.
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_ordersByWaiter count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _currentOrder = [self sectionedObjectAtIndexPath:indexPath fromDictionary:_ordersByWaiter];

    [self performSegueWithIdentifier:@"showOrderSegue" sender:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Get the key for this section from the dictionary.
    NSString *key = [[_ordersByWaiter allKeys] objectAtIndex:section];
    
    // Get the order item objects belonging to this key, and store in an array.
    NSArray *ordersForWaiter = [_ordersByWaiter valueForKey:key];
    
    return [ordersForWaiter count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_ordersByWaiter allKeys] objectAtIndex:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ////
    // This could do with a bit of tweaking.
    ////
    
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width, 30)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width, 30)];
    [label setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20]];
    label.textColor = [UIColor waiterGreenColour];
    
    NSString *string = [[_ordersByWaiter allKeys] objectAtIndex:section];
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];
    
    return view;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (OrderTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"orderCell";
    
    // Extract the name of this section by looking in the Dictionary's keys.
    PFObject *order = [self sectionedObjectAtIndexPath:indexPath fromDictionary:_ordersByWaiter];
    
    OrderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    cell.tableNumberLabel.text = order[@"tableNumber"];
    cell.orderPriceLabel.text = [NSString stringWithFormat:@"£%@", order[@"totalPrice"]];
    
    [cell.itemsOrderedLabel setHidden:YES];
    [cell.itemsDeliveredLabel setHidden:YES];
    
    // Get information about the items ordered.
    PFQuery *noOfItemsOrdered = [PFQuery queryWithClassName:@"OrderItem"];
    [noOfItemsOrdered whereKey:@"forOrder" equalTo:order];
    [noOfItemsOrdered countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        [cell.itemsOrderedLabel setHidden:NO];
        [cell.itemsDeliveredLabel setHidden:NO];
        
        cell.itemsOrderedLabel.text = [NSString stringWithFormat:@"%d items ordered", number];
    }];
    
    PFQuery *noOfItemsDelivered = [PFQuery queryWithClassName:@"OrderItem"];
    [noOfItemsDelivered whereKey:@"forOrder" equalTo:order];
    [noOfItemsDelivered whereKey:@"state" containedIn:@[@"ready", @"collected"]];
    [noOfItemsDelivered countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        [cell.itemsOrderedLabel setHidden:NO];
        [cell.itemsDeliveredLabel setHidden:NO];
        
        cell.itemsDeliveredLabel.text = [NSString stringWithFormat:@"%d items delivered", number];
    }];
    
    cell.currentCourseLabel.text = @"Current course: Mains";
    
    return cell;
}

#pragma mark - Other

- (PFObject *)sectionedObjectAtIndexPath:(NSIndexPath *)indexPath fromDictionary:(NSDictionary *)dictionary {
    NSString *keyForSection = [[dictionary allKeys] objectAtIndex:[indexPath section]];
    
    return [[dictionary valueForKey:keyForSection] objectAtIndex:[indexPath row]];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showOrderSegue"]) {
        // Pass the PFObject to the next scene.
        ViewOrderViewController *vc = (ViewOrderViewController *)[segue destinationViewController];        
        [vc setCurrentOrder:_currentOrder];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    } else if ([identifier isEqualToString:@"showOrderSegue"]) {
        return NO;
    }
    return YES;
}


@end

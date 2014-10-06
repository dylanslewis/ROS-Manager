//
//  DishViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "DishViewController.h"
#import "DishTableViewCell.h"
#import "AddDishViewController.h"
#import "EditDishViewController.h"

@interface DishViewController ()

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation DishViewController

#pragma mark - Setup

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The className to query on
        self.parseClassName = @"Dish";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
        self.objectsPerPage = 25;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"name";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Listen for changes to dish objects.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryForTable) name:@"addedDish" object:nil];
    
    // Set the view title as the name of the current course.
    self.title = [_currentCourse objectForKey:@"name"];
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUserSegue" sender:nil];
    }
}

- (void)setCurrentCourse:(PFObject *)course {
    _currentCourse = course;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}


- (PFQuery *)queryForTable {
    // Get all Dish PFObjects whos 'parent' is the current Course.
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"ofCourse" equalTo:_currentCourse];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    // Sort objects by name.
    [query orderByAscending:@"name"];
    
    return query;
}


#pragma mark - Table view

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ////
    // Consider VOIDING meals, rather than deleting them... or have a trash?
    ////
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self loadObjects];
        }];
    }
}

- (DishTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"dishCell";
    
    DishTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    cell.dishNameLabel.text = [object objectForKey:@"name"];
    
    // Work out whether this dish has options.
    if ([[object[@"options"] allKeys] count]>0) {
        // This is when the dish has options.
        
        [cell.dishOptionsLabel setHidden:NO];
        [cell.fromLabel setHidden:NO];
        
        NSDictionary *options = [[NSDictionary alloc] initWithDictionary:object[@"options"]];
        
        // Find the lowest priced option.
        NSNumber *lowestPrice = @-1;
        for (NSString *option in [options allKeys]) {
            NSNumber *currentOptionPrice = [options valueForKey:option];
            
            if ([lowestPrice doubleValue] == -1) {
                lowestPrice = currentOptionPrice;
            } else if ([currentOptionPrice doubleValue] < [lowestPrice doubleValue]) {
                lowestPrice = currentOptionPrice;
            }
        }
        
        // Update labels.
        cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", lowestPrice];;
        cell.dishOptionsLabel.text = [NSString stringWithFormat:@"%lu options", (unsigned long)[[object[@"options"] allKeys] count]];
    } else {
        // This is when the dish has no options.
        
        [cell.dishOptionsLabel setHidden:YES];
        [cell.fromLabel setHidden:YES];
        
        // Update labels.
        cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", [object objectForKey:@"price"]];
    }
    
    return cell;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"addDish"]) {
        // When creating a dish, pass the currentCourse object, so that the new dish is categorised properly.
        AddDishViewController *vc = (AddDishViewController *)[[segue destinationViewController] topViewController];
        [vc setCourseForDish:_currentCourse];
    } else if ([[segue identifier] isEqualToString:@"editDishSegue"]) {
        // When editing a dish, pass the dish object that was selected.
        EditDishViewController *vc = (EditDishViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [vc setCurrentDish:[[self objects] objectAtIndex:[indexPath row]]];
    }
}

@end

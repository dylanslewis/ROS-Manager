//
//  DishViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "DishViewController.h"

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
    
    self.title = [_currentCourse objectForKey:@"name"];
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUser" sender:nil];
    }
}

- (void)setCurrentCourse:(PFObject *)course {
    _currentCourse = course;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)touchAddDishButton:(id)sender {
    [self displayTextInputAlertWithTitle:@"Create new dish" withMessage:@"Enter the name of the dish you would like to create" withPlaceholder:@"dish name"];
}


#pragma mark - Alert view handling

- (void)displayTextInputAlertWithTitle:(NSString *)title withMessage:(NSString *)message withPlaceholder:(NSString *)placeholder {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Create", nil];
    [_alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    UITextField *textField = [_alertView textFieldAtIndex:0];
    textField.placeholder = placeholder;
    
    // Validate inputs: only allow numbers.
    textField.keyboardType = UIKeyboardTypeDefault;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    // Display the alert.
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Create new dish"]) {
        if (buttonIndex==1) {
            // Create the new order with the current time as orderDate.
            NSString *dishName = [_alertView textFieldAtIndex:0].text;
            
            [self createNewDishWithName:dishName];
        }
    }
}


#pragma mark - Parse

- (void)createNewDishWithName:(NSString *)name {
    // Create the post
    PFObject *object = [PFObject objectWithClassName:self.parseClassName];
    object[@"name"] = name;
    
    // Relate this new object to this scene's current object.
    object[@"ofCourse"] = _currentCourse;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [object setACL:acl];
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refresh the table when the object is done saving.
        [self loadObjects];
    }];
}


- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    // Get all PFObjects whos 'parent' is this scene's current object.
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"ofCourse" equalTo:_currentCourse];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
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
    // Consider VOIDING meals, rather than deleting them... or have a trash?
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self loadObjects];
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"dishCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    cell.textLabel.text = [object objectForKey:@"name"];
    
    return cell;
}

@end

//
//  WaiterViewController.m
//  Manager
//
//  Created by Dylan Lewis on 09/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "WaiterViewController.h"

@interface WaiterViewController ()

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation WaiterViewController

#pragma mark - Setup

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The className to query on
        self.parseClassName = @"Waiter";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
        self.objectsPerPage = 25;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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


#pragma mark - Button handling

- (IBAction)touchAddWaiterButton:(id)sender {
    [self displayTwoTextInputAlertWithTitle:@"Create new waiter" withMessage:@"Please enter the name of the waiter you would like to create" withPlaceholderOne:@"first name" withPlaceholderTwo:@"surname"];
}


#pragma mark - Alert view handling

- (void)displayTwoTextInputAlertWithTitle:(NSString *)title withMessage:(NSString *)message withPlaceholderOne:(NSString *)placeholderOne withPlaceholderTwo:(NSString *)placeholderTwo; {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Create", nil];
    [_alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    
    UITextField *textField1 = [_alertView textFieldAtIndex:0];
    textField1.placeholder = placeholderOne;
    UITextField *textField2 = [_alertView textFieldAtIndex:1];
    textField2.placeholder = placeholderTwo;
    
    textField1.keyboardType = UIKeyboardTypeDefault;
    textField1.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField2.keyboardType = UIKeyboardTypeDefault;
    textField2.autocapitalizationType = UITextAutocapitalizationTypeWords;
    [textField2 setSecureTextEntry:NO];
    
    // Display the alert.
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Create new waiter"]) {
        if (buttonIndex==1) {
            // Create the new order with the current time as orderDate.
            NSString *firstName = [_alertView textFieldAtIndex:0].text;
            NSString *surname = [_alertView textFieldAtIndex:1].text;
            
            [self createNewWaiterWithFirstName:firstName withSurname:surname];
        }
    }
}


#pragma mark - Parse

- (void)createNewWaiterWithFirstName:(NSString *)firstName withSurname:(NSString *)surname {
    PFObject *object = [PFObject objectWithClassName:self.parseClassName];
    object[@"firstName"]=firstName;
    object[@"surname"]=surname;
    
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
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByAscending:@"surname"];
    
    return query;
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"waiterCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"firstName"], [object objectForKey:@"surname"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self loadObjects];
        }];
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    }
    return YES;
}


@end

//
//  CourseViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "CourseViewController.h"
#import "DishViewController.h"

@interface CourseViewController ()

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation CourseViewController

#pragma mark - Setup

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The className to query on
        self.parseClassName = @"Course";
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
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    // Get the current user.
    PFUser *user=[PFUser currentUser];
    
    // If there is no user logged in, return to the login screen.
    if (!user) {
        [self performSegueWithIdentifier:@"logoutUser" sender:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button handling

- (IBAction)touchAddCourseButton:(id)sender {
#warning No food type handling currently, i.e. get the user to pick whether this course is for food or drink.
    [self displayTextInputAlertWithTitle:@"Create new course" withMessage:@"Enter the name of the course you would like to create" withPlaceholder:@"course name"];
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
    if ([alertView.title isEqualToString:@"Create new course"]) {
        if (buttonIndex==1) {
            // Create the new order with the current time as orderDate.
            NSString *courseName = [_alertView textFieldAtIndex:0].text;
            
            [self createNewCourseWithName:courseName];
        }
    }
}


#pragma mark - Parse

- (void)createNewCourseWithName:(NSString *)name {
    PFObject *object = [PFObject objectWithClassName:self.parseClassName];
    object[@"name"]=name;
    
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
    
    
    
    [query orderByAscending:@"name"];
    
    return query;
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"courseCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
    cell.textLabel.text = [object objectForKey:@"name"];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"dishesForCourseSegue"]) {
        // Retrieve the PFObject from the cell.
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        PFObject *course=[self objectAtIndexPath:indexPath];
        
        // Pass the PFObject to the next scene.
        [[segue destinationViewController] setCurrentCourse:course];
    }
}

@end

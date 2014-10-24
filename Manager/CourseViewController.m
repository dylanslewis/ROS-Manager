//
//  CourseViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "CourseViewController.h"
#import "DishViewController.h"
#import "CourseTableViewCell.h"
#import "UIColor+ApplicationColours.h"


@interface CourseViewController ()

@property (strong, nonatomic) UIAlertView *alertView;

@property (strong, nonatomic) NSArray *coursesArray;
@property (strong, nonatomic) NSMutableDictionary *coursesByType;

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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Listen for any changes to courses, and update when they occur.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryForTable) name:@"addedCourse" object:nil];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
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

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_coursesByType count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Get the key for this section from the dictionary.
    NSString *key = [[_coursesByType allKeys] objectAtIndex:section];
    
    // Get the order item objects belonging to this key, and store in an array.
    NSArray *coursesForKey = [_coursesByType valueForKey:key];
    
    return [coursesForKey count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_coursesByType allKeys] objectAtIndex:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:14]];
    label.textColor = [UIColor grayColor];
    
    NSString *string = [[_coursesByType allKeys] objectAtIndex:section];
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];
    
    return view;
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section]==0) {
        // This means the object is a Drink, because 'D' comes before 'F' in the alphabet.
        return [self.objects objectAtIndex:[indexPath row]];
    } else {
        // This means the object is Food.
        // Get the number of objects that are 'Drink'.
        NSInteger numberOfDrinkObjects = [[_coursesByType valueForKey:@"Drink"] count];
        
        NSInteger flattenedIndex = numberOfDrinkObjects + [indexPath row];
        
        return [self.objects objectAtIndex:flattenedIndex];
    }
}


#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // Create an array of all order items.
    _coursesArray = [[NSArray alloc] initWithArray:self.objects];
    _coursesByType = [[NSMutableDictionary alloc] init];
    
    // Go through the 'raw' list of order items.
    for (NSDictionary *course in _coursesArray) {
        // Extract course type.
        NSString *courseType=[course valueForKey:@"type"];
        
        // If we don't already have this type, add it.
        if (![[_coursesByType allKeys] containsObject:courseType]) {
            // Create an array containing the current course item object.
            NSMutableArray *courseItem = [[NSMutableArray alloc] initWithObjects:course, nil];
            
            [_coursesByType setObject:courseItem forKey:courseType];
        } else {
            // If the key (i.e. course type) already exists, add course to its array.
            NSMutableArray *courseItems = [_coursesByType valueForKey:courseType];
            [courseItems addObject:course];
            
            [_coursesByType setObject:courseItems forKey:courseType];
        }
    }
        
    [self.tableView reloadData];
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
    
    [query orderByDescending:@"type"];
    
    return query;
}

#pragma mark - Other

- (PFObject *)sectionedObjectAtIndexPath:(NSIndexPath *)indexPath fromDictionary:(NSDictionary *)dictionary {
    NSString *keyForSection = [[dictionary allKeys] objectAtIndex:[indexPath section]];
    
    return [[dictionary valueForKey:keyForSection] objectAtIndex:[indexPath row]];
}

#pragma mark - Table view

- (CourseTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"courseCell";
    
    CourseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    PFObject *course = [self sectionedObjectAtIndexPath:indexPath fromDictionary:_coursesByType];
    
    // Configure the cell
    cell.courseNameLabel.text = [course objectForKey:@"name"];
    
    [cell.numberOfItemsLabel setHidden:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Dish"];
    [query whereKey:@"ofCourse" equalTo:course];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        [cell.numberOfItemsLabel setHidden:NO];
        cell.numberOfItemsLabel.text = [NSString stringWithFormat:@"%d items", number];
    }];
    
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
        NSString *keyForSection = [[_coursesByType allKeys] objectAtIndex:[indexPath section]];
        PFObject *course = [[_coursesByType valueForKey:keyForSection] objectAtIndex:[indexPath row]];
        
        [course deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self queryForTable];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"dishesForCourseSegue"]) {
        // Retrieve the PFObject from the cell.
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        PFObject *course = [self sectionedObjectAtIndexPath:indexPath fromDictionary:_coursesByType];
        
        // Pass the PFObject to the next scene.
        [[segue destinationViewController] setCurrentCourse:course];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // This stops the button automatically logging out the user, without checking confirmation.
    if ([identifier isEqualToString:@"logoutUserSegue"]) {
        return NO;
    }
    return YES;
}

@end

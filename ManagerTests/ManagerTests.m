//
//  ManagerTests.m
//  ManagerTests
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Parse/Parse.h>
#import "LoginViewController.h"
#import "AddCourseViewController.h"
#import "AddDishViewController.h"
#import "WaiterViewController.h"

@interface ManagerTests : XCTestCase

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@property (strong, nonatomic) NSMutableArray *createdObjects;

@property (strong, nonatomic) PFObject *courseForDish;

@end

@implementation ManagerTests

- (void)setUp {
    [super setUp];
    
    _username = @"dylan";
    _password = @"password";
    
    _createdObjects = [[NSMutableArray alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // Delete all created objects.
    for (PFObject *object in _createdObjects) {
        // Delete the object.
        [object deleteInBackground];
        
        // Remove from the array.
        [_createdObjects removeObject:object];
    }
}

#pragma mark - Parse

- (PFQuery *)queryForObjectWithClassName:className withName:name {
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"name" equalTo:name];
    
    return query;
}

#pragma mark - Login

- (void)testLogin {
    LoginViewController *loginController = [[LoginViewController alloc] init];
    [loginController loginUserWithUsername:_username withPassword:_password];
    
    // Test the success of the login.
    PFUser *user = [PFUser currentUser];
    
    if ([user.username isEqualToString:_username]) {
        XCTAssert(YES, @"Login success");
    } else {
        XCTAssert(NO, @"Login fail");
    }
}

#pragma mark - Menu

- (void)testCreateFoodCourse {
    AddCourseViewController *addCourseController = [[AddCourseViewController alloc] init];
    
    NSString *courseName = @"testFoodCourse";
    NSString *type = @"Food";
    
    // Create the new course.
    [addCourseController createNewCourseWithName:courseName withType:type];
    
    // Check if the course has been stored on the database and can be retrieved.
    PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *createdCourse = [objects firstObject];
        
        [_createdObjects addObject:createdCourse];
        
        if ([createdCourse[@"name"] isEqualToString:courseName] && [createdCourse[@"type"] isEqualToString:type]) {
            XCTAssert(YES, @"Food course created successfully");
        } else {
            XCTAssert(NO, @"Food course creation failed");
        }
    }];
}

- (void)testCreateDrinkCourse {
    AddCourseViewController *addCourseController = [[AddCourseViewController alloc] init];
    
    NSString *courseName = @"testDrinkCourse";
    NSString *type = @"Drink";
    
    // Create the new course.
    [addCourseController createNewCourseWithName:courseName withType:type];
    
    // Check if the course has been stored on the database and can be retrieved.
    PFQuery *query = [self queryForObjectWithClassName:@"Course" withName:courseName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *createdCourse = [objects firstObject];
        
        [_createdObjects addObject:createdCourse];
        
        if ([createdCourse[@"name"] isEqualToString:courseName] && [createdCourse[@"type"] isEqualToString:type]) {
            XCTAssert(YES, @"Food course created successfully");
        } else {
            XCTAssert(NO, @"Food course creation failed");
        }
    }];
}

- (void)testCreateItemForCourseWithOptions {
    AddDishViewController *addDishController = [[AddDishViewController alloc] init];
    AddCourseViewController *addCourseController = [[AddCourseViewController alloc] init];
    
    // Initially create the course we'll use for testing the created dish.
    NSString *courseName = @"testFoodCourse";
    NSString *type = @"Food";
    
    // Create the new course.
    [addCourseController createNewCourseWithName:courseName withType:type];
    
    // Specify the dish details.
    NSString *dishName = @"testDishName";
    NSString *optionName = @"testOptionName";
    NSNumber *optionPrice = @0.99;
    
    // Create the dicitonary of options.
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:optionPrice, optionName, nil];
    
    // Retrieve the course object.
    PFQuery *courseQuery = [self queryForObjectWithClassName:@"Course" withName:courseName];
    [courseQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *createdCourse = [objects firstObject];
        
        // Pass the created course to the add dish view controller.
        [addDishController setCourseForDish:createdCourse];
        
        // Create the dish object.
        [addDishController createNewDishWithName:dishName withOptions:options];
        
        // Check if the dish has been stored on the database and can be retrieved.
        PFQuery *dishQuery = [self queryForObjectWithClassName:@"Dish" withName:dishName];
        [dishQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdDish = [objects firstObject];
            
            [_createdObjects addObject:createdDish];
            
            __block NSDictionary *createdDishOptions = createdDish[@"options"];
            __block NSString *createdDishOptionName = [[createdDishOptions allKeys] firstObject];
            __block NSNumber *createdDishOptionPrice = [createdDishOptions valueForKey:createdDishOptionName];
            
            // Test the properties of the created dish.
            if ([createdDish[@"name"] isEqualToString:dishName] && [createdDish[@"type"] isEqualToString:type] && [createdDish[@"ofCourse"] isEqual:createdCourse] && [createdDish[@"options"] isEqual:options] && [createdDishOptionName isEqualToString:optionName] && [createdDishOptionPrice isEqualToNumber:optionPrice]) {
                XCTAssert(YES, @"Dish created successfully with the correct option, option price, and for the correct course and type.");
            } else if (![createdDish[@"type"] isEqualToString:type]) {
                XCTAssert(NO, @"Created dish has incorrect type");
            } else if (![createdDish[@"ofCourse"] isEqual:createdCourse]) {
                XCTAssert(NO, @"Created dish has incorrect course");
            } else if (![createdDish[@"options"] isEqual:options]) {
                XCTAssert(NO, @"Created dish has incorrect options");
            } else if (![createdDishOptionName isEqualToString:optionName]) {
                XCTAssert(NO, @"Created dish has incorrect option name");
            } else if (![createdDishOptionPrice isEqualToNumber:optionPrice]) {
                XCTAssert(NO, @"Created dish has incorrect option price");
            } else {
                XCTAssert(NO, @"Dish creation failed");
            }
        }];
    }];
}

- (void)testCreateItemForCourseWithNoOptions {
    AddDishViewController *addDishController = [[AddDishViewController alloc] init];
    AddCourseViewController *addCourseController = [[AddCourseViewController alloc] init];
    
    // Initially create the course we'll use for testing the created dish.
    NSString *courseName = @"testFoodCourse";
    NSString *type = @"Food";
    
    // Create the new course.
    [addCourseController createNewCourseWithName:courseName withType:type];
    
    // Specify the dish details.
    NSString *dishName = @"testDishName";
    NSNumber *dishPrice = @0.99;
    
    // Retrieve the course object.
    PFQuery *courseQuery = [self queryForObjectWithClassName:@"Course" withName:courseName];
    [courseQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *createdCourse = [objects firstObject];
        
        // Pass the created course to the add dish view controller.
        [addDishController setCourseForDish:createdCourse];
        
        // Create the dish object.
        [addDishController createNewBasicDishWithName:dishName withPrice:dishPrice];
        
        // Check if the dish has been stored on the database and can be retrieved.
        PFQuery *dishQuery = [self queryForObjectWithClassName:@"Dish" withName:dishName];
        [dishQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            __block PFObject *createdDish = [objects firstObject];
            
            [_createdObjects addObject:createdDish];
            
            // Test the properties of the created dish.
            if ([createdDish[@"name"] isEqualToString:dishName] && [createdDish[@"type"] isEqualToString:type] && [createdDish[@"ofCourse"] isEqual:createdCourse] && [createdDish[@"price"] isEqual:dishPrice]) {
                XCTAssert(YES, @"Dish created successfully, for the correct course and type.");
            } else if (![createdDish[@"type"] isEqualToString:type]) {
                XCTAssert(NO, @"Created dish has incorrect type");
            } else if (![createdDish[@"ofCourse"] isEqual:createdCourse]) {
                XCTAssert(NO, @"Created dish has incorrect course");
            } else {
                XCTAssert(NO, @"Dish creation failed");
            }
        }];
    }];
}

#pragma mark - Waiters

- (void)testCreateNewWaiter {
    WaiterViewController *waiterController = [[WaiterViewController alloc] init];
    
    NSString *firstName = @"testFirstName";
    NSString *surname = @"testSurname";
    
    [waiterController createNewWaiterWithFirstName:firstName withSurname:surname];
    
    // Check if the waiter has been stored on the database and can be retrieved.
    PFQuery *query = [PFQuery queryWithClassName:@"Waiter"];
    [query whereKey:@"firstName" equalTo:firstName];
    [query whereKey:@"surname" equalTo:surname];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        __block PFObject *createdWaiter = [objects firstObject];
        
        [_createdObjects addObject:createdWaiter];
        
        if ([createdWaiter[@"firstName"] isEqualToString:firstName] && [createdWaiter[@"surname"] isEqualToString:surname]) {
            XCTAssert(YES, @"Waiter created successfully");
        } else if (![createdWaiter[@"firstName"] isEqualToString:firstName]){
            XCTAssert(NO, @"Waiter has incorrect first name");
        } else if (![createdWaiter[@"surname"] isEqualToString:surname]) {
            XCTAssert(NO, @"Waiter has incorrect surname");
        } else {
            XCTAssert(NO, @"Waiter creation failed");
        }
    }];
}

@end

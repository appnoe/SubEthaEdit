//
//  TCMMMUserManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserManager.h"
#import "TCMMMUser.h"


NSString * const TCMMMUserManagerUserDidChangeNotification = @"TCMMMUserManagerUserDidChangeNotification";

static TCMMMUserManager *sharedInstance=nil;

@implementation TCMMMUserManager

+ (TCMMMUserManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (TCMMMUser *)me {
    return [[self sharedInstance] me];
}


+ (NSString *)myUserID {
    return [[self sharedInstance] myUserID];
}

- (id)init {
    if ((self=[super init])) {
        I_usersByID=[NSMutableDictionary new];
        I_userRequestsByID=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_userRequestsByID release];
    [I_usersByID release];
    [I_me release];
    [super dealloc];
}

- (void)setMe:(TCMMMUser *)aUser {
    [I_me autorelease];
     I_me = [aUser retain];
    [self setUser:I_me forUserID:[I_me userID]];
}
- (TCMMMUser *)me {
    return I_me;
}
- (NSString *)myUserID {
    return [[self me] userID];
}
- (TCMMMUser *)userForUserID:(NSString *)aID {
    return [I_usersByID objectForKey:aID];
}
- (void)setUser:(TCMMMUser *)aUser forUserID:(NSString *)aID {
    DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"Set user:%@ forID:%@",aUser,aID);
    [I_usersByID setObject:aUser forKey:aID];
}

- (void)addUser:(TCMMMUser *)aUser {
    NSLog(@"AddUser: %@",aUser);
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    BOOL userDidChange=NO;
    if (user) {
        if ([aUser changeCount] > [user changeCount]) {
            userDidChange=YES;
            [user updateWithUser:aUser];
        }
    } else {
        userDidChange=YES;
        [I_usersByID setObject:aUser forKey:userID];
        NSLog(@"new user set");
    }
    if (userDidChange) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] >= [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [I_userRequestsByID removeObjectForKey:userID];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:aUser forKey:@"User"]];
    }
}

- (BOOL)sender:(id)aSender shouldRequestUser:(TCMMMUser *)aUser {
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    if (!user) {
        user=[TCMMMUser new];
        [user setChangeCount:0];
        [user setUserID:userID];
        [user setName:[aUser name]];
        [self setUser:[user autorelease] forUserID:userID];
        return YES;
    } 
    if ([user changeCount]<[aUser changeCount]) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] > [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [request setObject:aUser forKey:@"User"];
                [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
                return YES;
            } else {
                return NO;
            }
        } else {
            request=[NSMutableDictionary dictionary];
            [request setObject:aUser forKey:@"User"];
            [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
            [I_userRequestsByID setObject:request forKey:userID];
            return YES;
        }
    } else {
        return NO;
    }
}

@end

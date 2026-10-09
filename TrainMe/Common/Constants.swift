//
//  Constants.swift
//  TrainMe
//
//  Created by ShabeerAli K on 09/10/26.
//

import Foundation

enum Constants {
    
    //Secure Storage
    enum KeyChain {
        static let service = "com.trainme.auth"
        static let account = "authToken"
    }
    
    enum SystemImage {
        static let userEmail = "house.fill"
        static let userPassword = "gearshape"
    }
    enum MockData {
        static let loginDemoUserEmail = "test@example.com"
        static let loginDemoUserPassword = "password123"
    }
    
    enum Error {
        static let noConnectivity = "You appear to be offline. Check your internet connection and try again."
        
    }
    
    enum Presentation {
        //CourseDetailView
        //Common.Presentation.trainMe
        static let trainMe      =    "TrainMe"
        static let loadingLessonMsg = "Loading lessons…"
        static let noInternet = "No Internet Connection"
        static let lessonLoadFailed = "Couldn't Load Lessons"
        static let courseLoadFailed = "Couldn't Load Courses"
        static let tryAgain = "Try Again"
        static let lessonUpdateFailed = "Couldn't update lesson"
        static let okay     =   "OK"
        static let complete     =   "complete"
        static let lessons     =   "lessons"
        static let with     =   "with"
        static let completed     =  "Completed"
        static let pending     =   "Pending"
        static let markComplete     =   "Mark Complete"
        //DashBoardView
        static let continueMsg  = "Continue"
        static let myCourses     =   "My Courses"
        static let logout     =   "Log Out"
        static let noCourses     =  "No courses yet"
        static let coursesEnrollMsg     =   "Courses you enroll in will show up here."
        static let courseOfflineMsg     =   "You're offline. Showing your saved courses."
        static let loadingCoursesMsg    =   "Loading courses…"
        //LoginView
        static let loginToContinueMsg   =  "Log in to continue learning"
        static let loginMsg   =  "Log In"
        static let demoAccount = "Demo account:"
        static let emailPlaceholder = "Email"
        static let passPlaceHolder = "Password"

    }
    
}


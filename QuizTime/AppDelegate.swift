//
//  AppDelegate.swift
//  QuizTime
//
//  Created by Wes Bosman on 5/1/17.
//  Copyright © 2017 Wes Bosman. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // URL of JSON data
    let quizUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz1.json")!
    let session = URLSession.shared
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let task = session.dataTask(with: quizUrl, completionHandler: {
            (data, response, error) -> Void in
            
            print("Task Completion Handler")
            
            if let d = data{
                print("Data: \(d)")
            }
            
            if let r = response as? HTTPURLResponse{
                print("Response: \(r)")
                
                if r.statusCode == 200{
                    print("Successfully getting info from server")
                    do{
                        // Read JSON Data as a Dictionary
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: Any]
                        
                        
                        if  let numQuestions = json["numberOfQuestions"] as? Int,
                            let questions = json["questions"],
                            let topic = json["topic"] as? String {
                            
                            print("Number of Questions: \(numQuestions)")
                            print("Topic: \(topic)")
                            
                            
                            // Parse the questions into an array
                            if let questionsArray = questions as? NSArray{
                                for question in questionsArray{
                                    
                                    if let quest = question as? NSDictionary{
                                        
                                        if let correctOption  = quest["correctOption"],
                                            let number        = quest["number"],
                                            let options       = quest["options"],
                                            let questionSent  = quest["questionSentence"]{
                                            
                                            // Parse the elements into data types
                                            if let cor = correctOption as? String,
                                                let num = number as? Int,
                                                let opt = options as? NSDictionary,
                                                let sen = questionSent as? String{
                                                
                                                print("Corr -> \(cor)")
                                                print("Num  -> \(num)")
                                                print("Opt  -> \(opt)")
                                                print("Sen  -> \(sen)")
                                                
                                                let newQuestion = Question(correct: cor,
                                                                           num:     num,
                                                                           opt:     opt,
                                                                           sent:    sen)
                                                
                                                // Add the new question to the array
                                                Globals.arrayOfQuestions.append(newQuestion)
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch let err as NSError{
                        print("ERROR: \(err.localizedDescription)")
                    }
                }
            }
            
            if let e = error{
                print("Error: \(e)")
            }
            
        })
        task.resume()

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


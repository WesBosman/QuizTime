//
//  QuizViewController.swift
//  QuizTime
//
//  Created by Wes Bosman on 5/1/17.
//  Copyright © 2017 Wes Bosman. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity

class QuizViewController: UIViewController {
    // People images
    @IBOutlet weak var personOne: UIImageView!
    @IBOutlet weak var personTwo: UIImageView!
    @IBOutlet weak var personThree: UIImageView!
    @IBOutlet weak var personFour: UIImageView!
    
    // Text Bubble Images
    @IBOutlet weak var textBubbleImageOne: UIImageView!
    @IBOutlet weak var textBubbleImageTwo: UIImageView!
    @IBOutlet weak var textBubbleImageThree: UIImageView!
    @IBOutlet weak var textBubbleImageFour: UIImageView!
    
    // Text Bubble Labels
    @IBOutlet weak var textBubbleOne: UILabel!
    @IBOutlet weak var textBubbleTwo: UILabel!
    @IBOutlet weak var textBubbleThree: UILabel!
    @IBOutlet weak var textBubbleFour: UILabel!
    
    // Header Label For Question
    @IBOutlet weak var questionHeaderLabel: UILabel!
    
    // Actual Question Label
    @IBOutlet weak var questionLabel: UILabel!
    
    // Answer Buttons
    @IBOutlet weak var answerButtonA: UIButton!
    @IBOutlet weak var answerButtonB: UIButton!
    @IBOutlet weak var answerButtonC: UIButton!
    @IBOutlet weak var answerButtonD: UIButton!
    
    // Booleans for selecting answers
    var aSelected = false
    var bSelected = false
    var cSelected = false
    var dSelected = false
    
    // Passed in variables
    var numberOfPlayers = 0
    var sessionOfPlayers: MCSession!
    
    // URL of JSON data
    let quizUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz1.json")!
    let session = URLSession.shared
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                        
                        
                        if let numQuestions = json["numberOfQuestions"]{
                            print("Number of Questions: \(numQuestions)")
                        }
                        
                        if let questions = json["questions"]{
                            print("Questions: \(questions)")
                        }
                        
                        if let topic = json["topic"]{
                            print("Topic: \(topic)")
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
        
        // Selectors for buttons
        answerButtonA.addTarget(self, action: #selector(buttonASelected), for: .touchUpInside)
        answerButtonB.addTarget(self, action: #selector(buttonBSelected), for: .touchUpInside)
        answerButtonC.addTarget(self, action: #selector(buttonCSelected), for: .touchUpInside)
        answerButtonD.addTarget(self, action: #selector(buttonDSelected), for: .touchUpInside)
        
    }
    
    func updateSelectedButtonColor(){
        if(aSelected){
            answerButtonA.backgroundColor = UIColor.cyan
            answerButtonB.backgroundColor = UIColor.lightGray
            answerButtonC.backgroundColor = UIColor.lightGray
            answerButtonD.backgroundColor = UIColor.lightGray
        }
        else if (bSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.cyan
            answerButtonC.backgroundColor = UIColor.lightGray
            answerButtonD.backgroundColor = UIColor.lightGray
        }
        else if (cSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.lightGray
            answerButtonC.backgroundColor = UIColor.cyan
            answerButtonD.backgroundColor = UIColor.lightGray
        }
        else if (dSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.lightGray
            answerButtonC.backgroundColor = UIColor.lightGray
            answerButtonD.backgroundColor = UIColor.cyan
        }
    }
    
    func buttonASelected(){
        aSelected = true
        bSelected = false
        cSelected = false
        dSelected = false
        updateSelectedButtonColor()
    }
    
    func buttonBSelected(){
        aSelected = false
        bSelected = true
        cSelected = false
        dSelected = false
        updateSelectedButtonColor()
    }
    
    func buttonCSelected(){
        aSelected = false
        bSelected = false
        cSelected = true
        dSelected = false
        updateSelectedButtonColor()
    }
    
    func buttonDSelected(){
        aSelected = false
        bSelected = false
        cSelected = false
        dSelected = true
        updateSelectedButtonColor()
    }
}

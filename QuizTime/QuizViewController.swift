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

class QuizViewController:
    UIViewController,
    MCSessionDelegate{
    
    // People images
    @IBOutlet weak var personOne: UIImageView!
    @IBOutlet weak var personTwo: UIImageView!
    @IBOutlet weak var personThree: UIImageView!
    @IBOutlet weak var personFour: UIImageView!
    
    // Timer Label
    @IBOutlet weak var timerLabel: UILabel!
    
    // Text Bubble Images
    @IBOutlet weak var textBubbleImageOne: UIImageView!
    @IBOutlet weak var textBubbleImageTwo: UIImageView!
    @IBOutlet weak var textBubbleImageThree: UIImageView!
    @IBOutlet weak var textBubbleImageFour: UIImageView!

    // Text Bubble Labels
    let bubbleOneLabel:   UILabel! = UILabel()
    let bubbleTwoLabel:   UILabel! = UILabel()
    let bubbleThreeLabel: UILabel! = UILabel()
    let bubbleFourLabel:  UILabel! = UILabel()
    
    // Header Label For Question
    @IBOutlet weak var questionHeaderLabel: UILabel!
    
    // Actual Question Label
    @IBOutlet weak var questionLabel: UILabel!
    
    // Player Scores
    @IBOutlet weak var playerOneScore: UILabel!
    @IBOutlet weak var playerTwoScore: UILabel!
    @IBOutlet weak var playerFourScore: UILabel!
    @IBOutlet weak var playerThreeScore: UILabel!
    
    // Score Variables
    var pOneScore   = 0
    var pTwoScore   = 0
    var pThreeScore = 0
    var pFourScore  = 0
    
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
    var arrayOfQuestions: [Question] = []
    
    // Timer
    var questionTimer = Timer()
    var correctTimer  = Timer()
    var count         = 0
    var timerLabelVar = 0
    var currentQuestion: Question? = nil
    var currentQuestionIndex: Int  = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionOfPlayers.delegate = self
        startQuestionTimer()
        setUpTextLabelsForBubbles()
        grayOutPersons()
        
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
                                                
                                                self.currentQuestion = newQuestion
                                                
                                                // Add the new question to the array
                                                self.arrayOfQuestions.append(newQuestion)

                                            }
                                        }
                                    }
                                }
                                
                            }
                            
                            // Set up question one
                            let qOne = self.arrayOfQuestions[0]
                            
                            if  let a = qOne.options["A"] as? String,
                                let b = qOne.options["B"] as? String,
                                let c = qOne.options["C"] as? String,
                                let d = qOne.options["D"] as? String{
                                
                                let answerA = "A) \(a)"
                                let answerB = "B) \(b)"
                                let answerC = "C) \(c)"
                                let answerD = "D) \(d)"
                                
                                self.answerButtonA.setTitle(answerA, for: .normal)
                                self.answerButtonB.setTitle(answerB, for: .normal)
                                self.answerButtonC.setTitle(answerC, for: .normal)
                                self.answerButtonD.setTitle(answerD, for: .normal)
                            }
                            
                            let questNum = qOne.number
                            let totalNum = self.arrayOfQuestions.count
                            
                            // Set the first question
                            self.questionLabel.text = qOne.questionSentence
                            self.questionHeaderLabel.text = "Question \(questNum)/\(totalNum)"
                            

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
    
    func grayOutPersons(){
        let opacity: Float = 0.2
        
        playerOneScore.text   = "\(pOneScore)"
        playerTwoScore.text   = "\(pTwoScore)"
        playerThreeScore.text = "\(pThreeScore)"
        playerFourScore.text  = "\(pFourScore)"
        
        switch(numberOfPlayers){
        case 1:
            print("Single Player")
            // Person Two
            personTwo.layer.opacity = opacity
            bubbleTwoLabel.layer.opacity = opacity
            textBubbleImageTwo.layer.opacity = opacity
            playerTwoScore.text = ""
            
            // Person Three
            personThree.layer.opacity = opacity
            bubbleThreeLabel.layer.opacity = opacity
            textBubbleImageThree.layer.opacity  = opacity
            playerThreeScore.text = ""
            
            // Person Four
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.text = ""
            
        case 2:
            print("Two Players")
            
            // Person Three
            personThree.layer.opacity = opacity
            bubbleThreeLabel.layer.opacity = opacity
            textBubbleImageThree.layer.opacity  = opacity
            playerThreeScore.text = ""
            
            // Person Four
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.text = ""
            
        case 3:
            print("Three Players")
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.isHidden = true
            
        case 4:
            print("Four Players")
            
        default:
            break
        }
    }
    
    func setUpTextLabelsForBubbles(){
        let font = UIFont(name: "Helvetica", size: 20)
        
        // Button Label One
        bubbleOneLabel.bounds = textBubbleImageOne.bounds
        bubbleOneLabel.center = textBubbleImageOne.center
        bubbleOneLabel.frame  = textBubbleImageOne.frame
        bubbleOneLabel.textAlignment = .center
        bubbleOneLabel.font = font
        textBubbleImageOne.addSubview(bubbleOneLabel)
        
        // Button Label Two
        bubbleTwoLabel.bounds = textBubbleImageTwo.bounds
        bubbleTwoLabel.center = textBubbleImageTwo.center
        bubbleTwoLabel.frame  = textBubbleImageOne.frame
        bubbleTwoLabel.textAlignment = .center
        bubbleTwoLabel.font = font
        textBubbleImageTwo.addSubview(bubbleTwoLabel)
        
        // Button Label Three
        bubbleThreeLabel.bounds = textBubbleImageThree.bounds
        bubbleThreeLabel.center = textBubbleImageThree.center
        bubbleThreeLabel.frame  = textBubbleImageThree.frame
        bubbleThreeLabel.textAlignment = .center
        bubbleThreeLabel.font = font
        textBubbleImageThree.addSubview(bubbleThreeLabel)
        
        // Button Label Four
        bubbleFourLabel.bounds = textBubbleImageFour.bounds
        bubbleFourLabel.center = textBubbleImageFour.center
        bubbleFourLabel.frame  = textBubbleImageFour.frame
        bubbleFourLabel.textAlignment = .center
        bubbleFourLabel.font = font
        textBubbleImageFour.addSubview(bubbleFourLabel)
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
    
    // Start the question timer
    func startQuestionTimer(){
        count = 20
        questionTimer = Timer.scheduledTimer(timeInterval: 1,
                                             target: self,
                                             selector: #selector(timerStarted),
                                             userInfo: nil,
                                             repeats: true)
    }
    
    func timerStarted(){
        print("Question Timer Started")
        timerLabel.text = "\(count)"
        count = count - 1
        
        if count == 0{
            timerLabel.text = "\(count)"
            count = count - 1
            questionTimer.invalidate()
            
            // Show the correct answer
            if let correct = currentQuestion?.correctOption{
                switch(correct){
                case "A":
                    print("Case A was correct")
                    answerButtonA.backgroundColor = UIColor.green
                case "B":
                    print("Case B was correct")
                    answerButtonB.backgroundColor = UIColor.green
                case "C":
                    print("Case C was correct")
                    answerButtonC.backgroundColor = UIColor.green
                case "D":
                    print("Case D was correct")
                    answerButtonD.backgroundColor = UIColor.green
                default:
                    break
                }
                
                // Go to the next question
                goToNextQuestion()
            }
            
        }
    }
    
    /*
    *   Add Core Motion for user selection
    *   Add a three second timer for correct answers
    *
    */
    
    func goToNextQuestion(){
        // Reset the button colors
        answerButtonA.backgroundColor = UIColor.lightGray
        answerButtonB.backgroundColor = UIColor.lightGray
        answerButtonC.backgroundColor = UIColor.lightGray
        answerButtonD.backgroundColor = UIColor.lightGray
        currentQuestionIndex = currentQuestionIndex + 1
        let currentIndx = currentQuestionIndex
        
        if currentIndx < arrayOfQuestions.count{
            let question = arrayOfQuestions[currentIndx]
            
            if  let a = question.options["A"],
                let b = question.options["B"],
                let c = question.options["C"],
                let d = question.options["D"]{
                
                let current = question.number
                let total   = arrayOfQuestions.count
                questionLabel.text = question.questionSentence
                questionHeaderLabel.text = "Question \(current)/\(total)"
                answerButtonA.setTitle("A) \(a)", for: .normal)
                answerButtonB.setTitle("B) \(b)", for: .normal)
                answerButtonC.setTitle("C) \(c)", for: .normal)
                answerButtonD.setTitle("D) \(d)", for: .normal)
                
                // Start new timer 
                startQuestionTimer()
            }
        }
    }
    
    func buttonASelected(){
        aSelected = true
        bSelected = false
        cSelected = false
        dSelected = false
        updateSelectedButtonColor()
        
        let data = NSKeyedArchiver.archivedData(withRootObject: "A")
        do{
            try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.unreliable)
        }
        catch let err as NSError{
            print("ERROR: \(err.localizedDescription)")
        }
    }
    
    func buttonBSelected(){
        aSelected = false
        bSelected = true
        cSelected = false
        dSelected = false
        updateSelectedButtonColor()
        
        let data = NSKeyedArchiver.archivedData(withRootObject: "B")
        do{
            try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.unreliable)
        }
        catch let err as NSError{
            print("ERROR: \(err.localizedDescription)")
        }
    }
    
    func buttonCSelected(){
        aSelected = false
        bSelected = false
        cSelected = true
        dSelected = false
        updateSelectedButtonColor()
        
        let data = NSKeyedArchiver.archivedData(withRootObject: "C")
        do{
            try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.unreliable)
        }
        catch let err as NSError{
            print("ERROR: \(err.localizedDescription)")
        }
    }
    
    func buttonDSelected(){
        aSelected = false
        bSelected = false
        cSelected = false
        dSelected = true
        updateSelectedButtonColor()
        
        let data = NSKeyedArchiver.archivedData(withRootObject: "D")
        do{
            try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.unreliable)
        }
        catch let err as NSError{
            print("ERROR: \(err.localizedDescription)")
        }
    }
    
    
    // MARK - Session Methods
    
    // When a peer sends data to this device
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Session Did Receive Data")
        print("Data: \(data)")
        print("Peer: \(peerID.displayName)")
        
        // If data is equal to segue key then go to the quiz controller
        if let dataString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String{
            print("Data String Received: \(dataString)")
            
            switch(dataString){
            case "A":
                print("Case A")
            case "B":
                print("Case B")
            case "C":
                print("Case C")
            case "D":
                print("Case D")
            default:
                break
            }
            
            
        }
    }
    
    // Called when a connected peer changes its state
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Session Did Change State")
        switch(state){
        case MCSessionState.connected:
            print("Connected to \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting to \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected \(peerID.displayName)")
        }
        
        
        
    }
    
    // Called when a peer establishes a stream with this device
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Session Did Receive Stream With Name")
        
    }
    
    // Called when a peer starts sending a file to this device
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Session Did Start Receiving Resource With Name")
        
    }
    
    // Called when a file has finished transfering from a peer
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("Session Did Finish Receiving Resource")
        
    }
}

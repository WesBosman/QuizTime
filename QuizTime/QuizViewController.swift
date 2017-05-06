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
    
    // Restart Button
    @IBOutlet weak var restartButton: UIButton!
    
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
    
    // Player Name Labels
    @IBOutlet weak var playerOneNameLabel: UILabel!
    @IBOutlet weak var playerTwoNameLabel: UILabel!
    @IBOutlet weak var playerThreeNameLabel: UILabel!
    @IBOutlet weak var playerFourNameLabel: UILabel!
    
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
    var selectedAnswer: String? = nil
    
    // Passed in variables
    var numberOfPlayers = 0
    var sessionOfPlayers: MCSession!
    
    // Timer
    var questionTimer = Timer()
    var correctTimer  = Timer()
    var count         = 0
    var timerLabelVar = 0
    var currentQuestion: Question? = nil
    var currentQuestionIndex: Int  = 0
    var correctCounter = 3
    
    // Motion Manager
    let motionManager = CMMotionManager()
    var motionTimer   = Timer()
    var myPeers: [MCPeerID] = []
    var userCorrect = false
    var restartNumber = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        Globals.arrayOfQuestions = Globals.quizOne
        setUpGame()
        
    }
    
    func setUpGame(){
        timerLabel.text = ""
        restartButton.isHidden = true
        sessionOfPlayers.delegate = self
        startQuestionTimer()
        setUpTextLabelsForBubbles()
        grayOutPersons()
        setUpQuestionOne()
        
        self.currentQuestion = Globals.arrayOfQuestions[0]
        self.currentQuestionIndex = 0
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        motionTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                           target: self,
                                           selector: #selector(updateMotion),
                                           userInfo: nil,
                                           repeats: true)
        
        // Selectors for buttons
        answerButtonA.addTarget(self, action: #selector(buttonASelected), for: .touchUpInside)
        answerButtonB.addTarget(self, action: #selector(buttonBSelected), for: .touchUpInside)
        answerButtonC.addTarget(self, action: #selector(buttonCSelected), for: .touchUpInside)
        answerButtonD.addTarget(self, action: #selector(buttonDSelected), for: .touchUpInside)
        
        self.becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool{
        get{
            return true
        }
    }
    
    // Handle Shake motion
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake{
            print("USER IS SHAKING THE DEVICE!")
            // Select an answer at random
            selectRandomAnswer()
        }
    }
    
    @IBAction func userPressedRestartButton(_ sender: Any) {
        print("User Pressed Restart Button")
        
        // How to restart the game?
        restartNumber += 1
        if restartNumber == 1{
            Globals.arrayOfQuestions = Globals.quizTwo
        }
        else if restartNumber == 2{
            Globals.arrayOfQuestions = Globals.quizOne
            restartNumber = 0
        }
        setUpGame()
    }
    
    
    func setUpQuestionOne(){
        // Set up question one
        let qOne = Globals.arrayOfQuestions[0]
        
        if  let a = qOne.options["A"] as? String,
            let b = qOne.options["B"] as? String,
            let c = qOne.options["C"] as? String,
            let d = qOne.options["D"] as? String{
            
            let answerA = "A) \(a)"
            let answerB = "B) \(b)"
            let answerC = "C) \(c)"
            let answerD = "D) \(d)"
            
            // Sometimes setting the title doesn't update the buttons?
            self.answerButtonA.setTitle(answerA, for: .normal)
            self.answerButtonB.setTitle(answerB, for: .normal)
            self.answerButtonC.setTitle(answerC, for: .normal)
            self.answerButtonD.setTitle(answerD, for: .normal)
            
            self.answerButtonA.titleLabel?.text = answerA
            self.answerButtonB.titleLabel?.text = answerB
            self.answerButtonC.titleLabel?.text = answerC
            self.answerButtonD.titleLabel?.text = answerD
        }
        
        let questNum = qOne.number
        let totalNum = Globals.arrayOfQuestions.count
        
        // Set the first question
        self.questionLabel.text = qOne.questionSentence
        self.questionHeaderLabel.text = "Question \(questNum)/\(totalNum)"
    }
    
    func updateMotion(){
        if let data = self.motionManager.deviceMotion{
            let attitude     = data.attitude
            let pitch        = attitude.pitch
            let roll         = attitude.roll
            let yaw          = attitude.yaw
            let acceleration = data.userAcceleration.z
            
            // Roll and Pitch do not submit
            // Yaw and acceleration do submit
            
            // Go Right
            if(roll > 1.0){
                if(aSelected){
                    bSelected = true
                    aSelected = false
                    updateSelectedButtonColor()
                }
                else if(cSelected){
                    dSelected = true
                    cSelected = false
                    updateSelectedButtonColor()
                }
            }
            
            // Go Left
            else if(roll < -1.0){
                if(bSelected){
                    aSelected = true
                    bSelected = false
                    updateSelectedButtonColor()
                }
                else if(dSelected){
                    cSelected = true
                    bSelected = false
                    updateSelectedButtonColor()
                }
            }
            
            // Control pitch
            // Forward
            if(pitch > 1.0){
                if(aSelected){
                    cSelected = true
                    aSelected = false
                    updateSelectedButtonColor()
                }
                else if(bSelected){
                    dSelected = true
                    bSelected = false
                    updateSelectedButtonColor()
                }
            }
            
            // Backward
            else if(pitch < -1.0){
                if(cSelected){
                    aSelected = true
                    cSelected = false
                    updateSelectedButtonColor()
                }
                else if(dSelected){
                    bSelected = true
                    dSelected = false
                    updateSelectedButtonColor()
                }
            }
            
            // Select an answer using acceleration in z direction
            if(acceleration < -1.0){
                userSubmittedAnswer()
            }
            
            // Let user select an answer using yaw
            if(yaw > 1.0){
                userSubmittedAnswer()
            }
            else if(yaw < -1.0){
                userSubmittedAnswer()
            }
            
        }
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
            playerOneNameLabel.text = sessionOfPlayers.myPeerID.displayName
                
            // Person Two
            personTwo.layer.opacity = opacity
            bubbleTwoLabel.layer.opacity = opacity
            textBubbleImageTwo.layer.opacity = opacity
            playerTwoScore.text = ""
            playerTwoNameLabel.text = ""
            
            // Person Three
            personThree.layer.opacity = opacity
            bubbleThreeLabel.layer.opacity = opacity
            textBubbleImageThree.layer.opacity  = opacity
            playerThreeScore.text = ""
            playerThreeNameLabel.text = ""
            
            // Person Four
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.text = ""
            playerFourNameLabel.text = ""
            
        case 2:
            print("Two Players")
            playerOneNameLabel.text = sessionOfPlayers.myPeerID.displayName
            playerTwoNameLabel.text = sessionOfPlayers.connectedPeers[0].displayName
            
            // Person Three
            personThree.layer.opacity = opacity
            bubbleThreeLabel.layer.opacity = opacity
            textBubbleImageThree.layer.opacity  = opacity
            playerThreeScore.text = ""
            playerThreeNameLabel.text = ""
            
            // Person Four
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.text = ""
            playerFourNameLabel.text = ""
            
        case 3:
            print("Three Players")
            playerOneNameLabel.text = sessionOfPlayers.myPeerID.displayName
            playerTwoNameLabel.text = sessionOfPlayers.connectedPeers[0].displayName
            playerThreeNameLabel.text = sessionOfPlayers.connectedPeers[1].displayName
            
            personFour.layer.opacity = opacity
            bubbleFourLabel.layer.opacity = opacity
            textBubbleImageFour.layer.opacity = opacity
            playerFourScore.isHidden = true
            playerFourNameLabel.text = ""
            
        case 4:
            print("Four Players")
            playerOneNameLabel.text = sessionOfPlayers.myPeerID.displayName
            playerTwoNameLabel.text = sessionOfPlayers.connectedPeers[0].displayName
            playerThreeNameLabel.text = sessionOfPlayers.connectedPeers[1].displayName
            playerFourNameLabel.text  = sessionOfPlayers.connectedPeers[2].displayName
            
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
            selectedAnswer = "A"
        }
        else if (bSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.cyan
            answerButtonC.backgroundColor = UIColor.lightGray
            answerButtonD.backgroundColor = UIColor.lightGray
            selectedAnswer = "B"
        }
        else if (cSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.lightGray
            answerButtonC.backgroundColor = UIColor.cyan
            answerButtonD.backgroundColor = UIColor.lightGray
            selectedAnswer = "C"
        }
        else if (dSelected){
            answerButtonA.backgroundColor = UIColor.lightGray
            answerButtonB.backgroundColor = UIColor.lightGray
            answerButtonC.backgroundColor = UIColor.lightGray
            answerButtonD.backgroundColor = UIColor.cyan
            selectedAnswer = "D"
        }
    }
    
    // Start the question timer
    func startQuestionTimer(){
        count = 20
        questionTimer = Timer.scheduledTimer(timeInterval: 1,
                                             target:   self,
                                             selector: #selector(timerStarted),
                                             userInfo: nil,
                                             repeats:  true)
    }
    
    func timerStarted(){
        print("Question Timer Count \(count)")
        timerLabel.text = "\(count)"
        count = count - 1
        
        if count == -1 || userCorrect{
            questionTimer.invalidate()
            if (userCorrect){
                pOneScore += 1
                playerOneScore.text = "\(pOneScore)"
            }
            userCorrect = false
            
            // Show the correct answer on a timer
            correctTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(showCorrectAnswer), userInfo: nil, repeats: true)
        }
    }
    
    func showCorrectAnswer(){
        print("Show Correct Answer")
        
        // Show the correct answer
        if let correct = self.currentQuestion?.correctOption{
            switch(correct){
            case "A":
                print("Case A was correct")
                self.answerButtonA.backgroundColor = UIColor.green
            case "B":
                print("Case B was correct")
                self.answerButtonB.backgroundColor = UIColor.green
            case "C":
                print("Case C was correct")
                self.answerButtonC.backgroundColor = UIColor.green
            case "D":
                print("Case D was correct")
                self.answerButtonD.backgroundColor = UIColor.green
            default:
                break
            }
        }
        else{
            print("No Current Question")
        }
        
        correctCounter = correctCounter - 1
        
        if correctCounter == 0{
            self.correctCounter = 3
            correctTimer.invalidate()
            
            if let index = Globals.arrayOfQuestions.index(where: {$0.questionSentence == currentQuestion?.questionSentence}){
                print("Index of Question: \(index)")
                print("Count of questions: \(Globals.arrayOfQuestions.count - 1)")
                
                if index < Globals.arrayOfQuestions.count - 1{
                    // Go to the next question
                    goToNextQuestion()
                }
            }
        }
    }
    
    func goToNextQuestion(){
        // Reset the button colors
        print("Go To Next Question")
        currentQuestionIndex = currentQuestionIndex + 1
        let currentIndx = currentQuestionIndex
        print("Current Question Index: \(currentQuestionIndex)")
        
        // Update the current question
        self.currentQuestion = Globals.arrayOfQuestions[currentIndx - 1]
        
        if let lastQuestion = Globals.arrayOfQuestions.last{
            // If we are on the last question unhide the restart button
            if self.currentQuestion?.questionSentence == lastQuestion.questionSentence{
                print("Reached Last Question")
                restartButton.isHidden = false
            }
            // Otherwise reset the buttons and text labels and start again
            else{
                // Set button backgrounds back to normal
                answerButtonA.backgroundColor = UIColor.lightGray
                answerButtonB.backgroundColor = UIColor.lightGray
                answerButtonC.backgroundColor = UIColor.lightGray
                answerButtonD.backgroundColor = UIColor.lightGray
                
                if currentIndx < Globals.arrayOfQuestions.count{
                    let question = Globals.arrayOfQuestions[currentIndx]
                    
                    if  let a = question.options["A"],
                        let b = question.options["B"],
                        let c = question.options["C"],
                        let d = question.options["D"]{
                        
                        let current = question.number
                        let total   = Globals.arrayOfQuestions.count
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
    
    // When user is submitting an answer.
    
    func userSubmittedAnswer(){
        print("Submitting Answer")
        if let selectedAns = selectedAnswer{
            print("User Submitted Answer: \(selectedAns)")
            buttonSubmitted(button: selectedAns)
        }
        else{
            print("No Answer Selected")
        }
    }
    
    // Button that the user submitted
    
    func buttonSubmitted(button: String){
        switch(button){
        case "A":
            setUserScoreAndAnswer(index: 0, answer: "A")
            
            if currentQuestion?.correctOption == "A"{
                userCorrect = true
            }
            
            if sessionOfPlayers.connectedPeers.count == 0{
                
            }
            else{
                let data = NSKeyedArchiver.archivedData(withRootObject: "A")
                do{
                    try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.reliable)
                }
                catch let err as NSError{
                    print("ERROR: \(err.localizedDescription)")
                }
            }
            
        case "B":
            setUserScoreAndAnswer(index: 0, answer: "B")
            
            if currentQuestion?.correctOption == "B"{
                userCorrect = true
            }
            
            if sessionOfPlayers.connectedPeers.count == 0{
                
            }
            else{
                let data = NSKeyedArchiver.archivedData(withRootObject: "B")
                do{
                    try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.reliable)
                }
                catch let err as NSError{
                    print("ERROR: \(err.localizedDescription)")
                }
            }

        case "C":
            setUserScoreAndAnswer(index: 0, answer: "C")
            
            
            if currentQuestion?.correctOption == "C"{
                userCorrect = true
            }
            
            if sessionOfPlayers.connectedPeers.count == 0{
                
            }
            else{
                let data = NSKeyedArchiver.archivedData(withRootObject: "C")
                do{
                    try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.reliable)
                }
                catch let err as NSError{
                    print("ERROR: \(err.localizedDescription)")
                }
            }
            
        case "D":
            setUserScoreAndAnswer(index: 0, answer: "D")
            
            if currentQuestion?.correctOption == "D"{
                userCorrect = true
            }
            
            // No Peers are connected go to next question
            if sessionOfPlayers.connectedPeers.count == 0{
                
            }
                // Peers are connected send them data
            else{
                let data = NSKeyedArchiver.archivedData(withRootObject: "D")
                do{
                    try sessionOfPlayers.send(data, toPeers: sessionOfPlayers.connectedPeers, with: MCSessionSendDataMode.reliable)
                }
                catch let err as NSError{
                    print("ERROR: \(err.localizedDescription)")
                }
            }
        default:
            break
        }
    }
    
    // If the player gets the question correct
    
    func setUserScoreAndAnswer(index: Int, answer: String){
        print("Set User Answer and Score")
        
        switch(index){
        case 0:
            bubbleOneLabel.text = "\(answer)"
        case 1:
            bubbleTwoLabel.text = "\(answer)"
        case 2:
            bubbleThreeLabel.text = "\(answer)"
        case 3:
            bubbleFourLabel.text = "\(answer)"
        default:
            break
        }
    }
    
    // MARK - Random Selection of Answers
    
    // Generate a random integer for selecting random answer
    func generateRandomInt(min: Int, max: Int) -> Int{
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    // Actually select random answer should not cause submission
    func selectRandom(rand: Int){
        switch(rand){
        case 0:
            aSelected = true
            bSelected = false
            cSelected = false
            dSelected = false
            updateSelectedButtonColor()
        case 1:
            aSelected = false
            bSelected = true
            cSelected = false
            dSelected = false
            updateSelectedButtonColor()
        case 2:
            aSelected = false
            bSelected = false
            cSelected = true
            dSelected = false
            updateSelectedButtonColor()
        default:
            aSelected = false
            bSelected = false
            cSelected = false
            dSelected = true
            updateSelectedButtonColor()
        }
    }
    
    // Select random answer that is not the same consecutively
    func selectRandomAnswer(){
        print("Selecting random answer")
        var rand = generateRandomInt(min: 0, max: 3)
        
        if let selectedAns = self.selectedAnswer{
            // User has already selected an answer do not pick same one twice
            switch(selectedAns){
            case "A":
                rand = generateRandomInt(min: 1, max: 3)
                selectRandom(rand: rand)
            case "B":
                let newRand = generateRandomInt(min: 0, max: 1)
                if newRand == 0{
                    rand = generateRandomInt(min: 0, max: 0)
                    selectRandom(rand: rand)
                }
                else{
                    rand = generateRandomInt(min: 2, max: 3)
                    selectRandom(rand: rand)
                }
            case "C":
                let newRand = generateRandomInt(min: 0, max: 1)
                if newRand == 0{
                    rand = generateRandomInt(min: 0, max: 1)
                    selectRandom(rand: rand)
                }
                else{
                    rand = generateRandomInt(min: 3, max: 3)
                    selectRandom(rand: rand)
                }

            case "D":
                rand = generateRandomInt(min: 0, max: 2)
                selectRandom(rand: rand)
            default:
                break
            }
        }
        else{
            // User has not selected an answer
            selectRandom(rand: rand)
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
            
            if let peerIndx = session.connectedPeers.index(of: peerID),
                let correct = currentQuestion?.correctOption{
                print("Peer Indx: \(peerIndx)")
                print("Data String Received: \(dataString)")
                print("Correct Answer: \(correct)")
                
                // If the answer is correct
                if currentQuestion?.correctOption == dataString{
                    setUserScoreAndAnswer(index: peerIndx + 1, answer: dataString)
                }
                
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

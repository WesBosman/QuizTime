//
//  ViewController.swift
//  QuizTime
//
//  Created by Wes Bosman on 5/1/17.
//  Copyright © 2017 Wes Bosman. All rights reserved.
//

import UIKit
import MultipeerConnectivity

struct Globals{
    static var session = URLSession.shared
    static var arrayOfQuestions: [Question] = []
    static var quizOneUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz1.json")!
    static var quizTwoUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz2.json")!
    static var quizThreeUrl = URL(string: "http://www.people.vcu.edu/~ebulut/jsonFiles/quiz3.json")!
    static var quizOne:   [Question] = []
    static var quizTwo:   [Question] = []
    static var quizThree: [Question] = []
    
    static func loadQuizData(quizUrl: URL, quizNumber: Int){
        
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
                                                switch(quizNumber){
                                                case 1:
                                                    Globals.quizOne.append(newQuestion)
                                                case 2:
                                                    Globals.quizTwo.append(newQuestion)
                                                case 3:
                                                    Globals.quizThree.append(newQuestion)
                                                default:
                                                    break
                                                }
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
    }
}

class ViewController:
    UIViewController,
    MCBrowserViewControllerDelegate,
    MCSessionDelegate{
    
    var session: MCSession!
    var peerID: MCPeerID!
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var singlePlayerSelected: Bool = true
    let maxPlayersToInvite: Int    = 4
    let serviceType: String        = "chat"
    let quizSegue:   String        = "showQuizController"
    let segueKey:    String        = "shouldSegueToQuizController"
    
    @IBOutlet weak var playerSegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add a target for the player control
        // Had to set security identiy to nil and encryption preference to none in order to connect
        self.peerID  = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        self.browser = MCBrowserViewController(serviceType: serviceType, session: session)
        self.assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
        
        assistant.start()
        browser.maximumNumberOfPeers = maxPlayersToInvite
        session.delegate = self
        browser.delegate = self
        playerSegmentedControl.addTarget(self, action: #selector(playerSegmentChanged), for: .valueChanged)
        
    }
    
    func playerSegmentChanged(sender: UISegmentedControl){
        print("Player Segment Control Changed")
        switch(sender.selectedSegmentIndex){
        case 0:
            print("Single Player Selected")
            singlePlayerSelected = true
        case 1:
            print("Multiplayer Selected")
            singlePlayerSelected = false
        default:
            break
        }
    }

    @IBAction func connectBarButtonPressed(_ sender: Any) {
        print("Connect Bar Button Pressed")
        present(browser, animated: true, completion: nil)
        
    }
    
    @IBAction func startQuizButtonPressed(_ sender: Any) {
        print("Start Quiz Button Pressed")
        // Should switch anyone that is connected to the quiz screen
        for peer in session.connectedPeers{
            print("Connected Peer: \(peer.displayName)")
        }
        
        // If multiplayer selected and no one is connected error
        if singlePlayerSelected == false && session.connectedPeers.count == 0{
            let alert = UIAlertController(title: "Error", message: "Multiplayer was selected but there are no connected peers. Please Connect to other players to continue playing multiplayer", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
        // More than three peers are connected
        // Only allowed to have at most 4 players total
        else if singlePlayerSelected == false && session.connectedPeers.count > 3{
            let alert = UIAlertController(title: "Error", message: "There are too many connected peers. Please reduce the number of connected peers to continue.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
        // Otherwise begin the game
        else{
            // Use a key to send everyone to the quiz segue
            // Reliabile sends data in order but is slow
            // Unreliable sends data faster but may be out of order
            let data = NSKeyedArchiver.archivedData(withRootObject: segueKey)
            do{
                try session.send(data, toPeers: session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            }
            catch let err as NSError{
                print("ERROR: \(err.localizedDescription)")
            }
            
            performSegue(withIdentifier: quizSegue, sender: self)
            
        }
        
    }
    
    // MARK - Browser View Controller Methods
    
    // Called when the browser view controller should dismiss
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        print("Browser View Controller Did Finish")
        dismiss(animated: true, completion: nil)
    }
    
    // Called when the browser view controller gets cancelled
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        print("Browser View Controller Was Cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    // Optional method to implement
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        return true
    }
    
    // MARK - Session Methods
    
    // When a peer sends data to this device
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Session Did Receive Data")
        print("Data: \(data)")
        
        // If data is equal to segue key then go to the quiz controller
        if let dataString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String{
            print("Data String Received: \(dataString)")
            
            if dataString == segueKey{
                self.performSegue(withIdentifier: self.quizSegue, sender: self)
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
        
        if session.connectedPeers.count > 0{
            // Switch to multiplayer if there are connected peers
            playerSegmentedControl.selectedSegmentIndex = 1
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
    
    /*
     *  Should send single player or multiplayer
     *  May want to send the session to the quiz controller
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Segue to Quiz View Controller")
        
        if let destination = segue.destination as? QuizViewController{
            destination.numberOfPlayers  = session.connectedPeers.count + 1
            destination.sessionOfPlayers = session
            
            print("Number of Players: \(session.connectedPeers.count)")
        }
    }

}


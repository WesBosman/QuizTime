//
//  Question.swift
//  QuizTime
//
//  Created by Wes Bosman on 5/3/17.
//  Copyright © 2017 Wes Bosman. All rights reserved.
//

import Foundation

struct Question{
    var correctOption: String
    var number: Int
    var options: NSDictionary // [String:AnyObject]
    var questionSentence: String
    
    init(correct: String, num: Int, opt: NSDictionary, sent: String){
        self.correctOption = correct
        self.number = num
        self.options = opt
        self.questionSentence = sent
    }
}

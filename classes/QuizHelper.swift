//
//  QuizHelper.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import Foundation

import XamoomSDK

class QuizHelper {
    
    static let pointskey = "POINTS"
    static let quizzesKey = "QUIZZES"
    static let voucherAmountKey = "VOUCHERS"
    
    
    public static func getSubmittedQuizzes() -> [Quiz] {
        let quizzesData = UserDefaults.standard.data(forKey: quizzesKey)
        if let quizzesData = quizzesData {
            let quizzesArray = try! JSONDecoder().decode([Quiz]?.self, from: quizzesData)
            return quizzesArray ?? [Quiz]()
        } else {
            return [Quiz]()
        }
    }
    
    
    public static func saveQuiz(quiz: Quiz) {
        var submittedQuizzes = getSubmittedQuizzes()
        submittedQuizzes.append(quiz)
        let quizzesData = try! JSONEncoder().encode(submittedQuizzes)
        UserDefaults.standard.set(quizzesData, forKey: quizzesKey)
    }
    
    public static func incrementVouchersAmount(on scoredPoints: Int) {
        let points = getPointsAmount()
        let oldPointsValue = points - scoredPoints
        
        var vouchersAmount = getVoucherAmount()
        
        if points / 300 > oldPointsValue / 300 {
            vouchersAmount += 1
            UserDefaults.standard.set(vouchersAmount, forKey: voucherAmountKey)
        }
    }
    
    public static func isQuizSubmitted(pageId: String) -> Bool {
        for submittedQuiz in getSubmittedQuizzes() {
            if let tempId = submittedQuiz.pageId, pageId.elementsEqual(tempId) {
                return true
            }
        }
        
        return false
    }
    
    public static func getPointsAmount() -> Int {
        return UserDefaults.standard.integer(forKey: pointskey)
    }
    
    public static func getCurrentLevel() -> Int {
        return (QuizHelper.getPointsAmount() / 300) + 1
    }
    
    public static func getVoucherAmount() -> Int {
        return UserDefaults.standard.integer(forKey: voucherAmountKey)
    }
    
    public static func increasePointsAmount(scoredPoints: Int) {
        let newPointsAmount = getPointsAmount() + scoredPoints
        UserDefaults.standard.set(newPointsAmount, forKey: pointskey)
    }
    
    
    public static func spendVoucher(vouchersAmount: Int) {
        let currentVouchersAmount = getVoucherAmount()
        let vouchersAmountNewValue = currentVouchersAmount - vouchersAmount
        UserDefaults.standard.set(vouchersAmountNewValue, forKey: voucherAmountKey)
    }

    
    public static func filterQuizzes(quizzes: [XMMContent], isPassed: Bool) -> [XMMContent] {
        var passedQuizzes: [XMMContent] = []
        var notPassedQuizzes: [XMMContent] = []
        
        for quiz in quizzes {
            if let quizId = quiz.id {
                if isQuizSubmitted(pageId: quizId as! String) {
                    passedQuizzes.append(quiz)
                } else {
                    notPassedQuizzes.append(quiz)
                }
            }
        }
        return isPassed ? passedQuizzes : notPassedQuizzes
    }
}

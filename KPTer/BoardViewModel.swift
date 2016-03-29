//
//  BoardViewModel.swift
//  KPTer
//
//  Created by Kaori Sawamura on 3/21/16.
//  Copyright © 2016 HanaLucky. All rights reserved.
//

import Foundation
import RealmSwift

class BoardViewModel {
    
    class func create(title: String) -> Board? {
        let board = Board()
        board.board_title = title
        let realm = try! Realm()
        try! realm.write {
            realm.add(board)
        }
        return board
    }
    
    class func delete(board: Board){
        let realm = try! Realm()
        try! realm.write {
            for var i = board.cards.count - 1; i >= 0; i-- {
                realm.delete(board.cards.first!)
            }
            realm.delete(board)
        }
    }
    
    class func edit(board: Board, title: String){
        let realm = try! Realm()
        try! realm.write {
            board.board_title = title
        }
    }
    
    class func addCard(board: Board, title: String, detail: String, type: Card.CardType) {
        let card = CardViewModel.create(title, detail: detail, type: type)
        let realm = try! Realm()
        try! realm.write {
            board.cards.append(card!)
        }
    }
    
    // Boardに紐づくKeep Cardを取得する
    class func findKeepCard(board: Board) -> Results<Card> {
        return findCardByType(board, type: Card.CardType.Keep)
    }
    
    // Boardに紐づくProblem Cardを取得する
    class func findProblemCard(board: Board) -> Results<Card> {
        return findCardByType(board, type: Card.CardType.Problem)
    }
    
    // Boardに紐づくTry Cardを取得する
    class func findTryCard(board: Board) -> Results<Card> {
        return findCardByType(board, type: Card.CardType.Try)
    }
    
    // Boardに紐づくCardをタイプ別に取得する
    private class func findCardByType(board: Board, type: Card.CardType) -> Results<Card> {
        return board.cards.filter("type = '\(type.rawValue)'")
    }

}



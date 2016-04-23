//
//  CardViewController.swift
//  KPTer
//
//  Created by yoshikawa atsushi on 3/11/16.
//  Copyright © 2016 HanaLucky. All rights reserved.
//

import UIKit
import RealmSwift

class CardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    // 画面内オブジェクト
    // card typeセグメント
    @IBOutlet weak var typeSegment: UISegmentedControl!
    // card titleフィールド
    @IBOutlet weak var titleField: UITextField!
    // descriptionフィールド
    @IBOutlet weak var descriptionField: UITextView!
    // relation card table view
    @IBOutlet weak var relationCardTableView: UITableView!
    // cart typeセグメントコントローラー
    @IBOutlet weak var cardTypeSegumentedControl: UISegmentedControl!
    // relation card ラベル
    @IBOutlet weak var cardRelationLabel: UILabel!
    // saveボタン
    @IBOutlet weak var save: UIBarButtonItem!
    
    // KPTエリアから受け取るパラメーター
    // KPTエリアから受け取るボード
    var board: Board! = nil
    // KPTエリアから受け取るカード
    var card: Card? = nil
    // 画面遷移の識別子(ボード一覧のAddから来たかEditからきたか判別)
    var identifier: String = ""
    
    // 内部利用変数
    // リレーション選択テーブルのセクション（Keep, Problem）
    let relationCardTableSections = [Card.CardType.Keep.rawValue, Card.CardType.Problem.rawValue]
    // リレーション選択テーブルに表示するKeepカードリスト
    var keepCardEntities: Results<Card>!
    // リレーション選択テーブルに表示するProblemカードリスト
    var problemCardEntities: Results<Card>!
    // リレーション選択テーブルで選択されたカード
    var selectedRelationCard: Card? = nil
    // セグメントに割り当てたカードタイプの値
    enum CardTypeSegmentIndex: Int {
        case Keep = 0
        case Problem = 1
        case Try = 2
    }
    // relation cardセクション
    enum CardTypeSectionIndex: Int {
        case Keep = 0
        case Problem = 1
        // Tryはリレーションで使わないので不要
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        
        // selfをデリゲートにする
        self.titleField.delegate = self
        
        // relationテーブルにKeep, Problemカードを設定する
        keepCardEntities = BoardViewModel.findKeepCard(self.board)
        problemCardEntities = BoardViewModel.findProblemCard(self.board)
        
        if (Identifiers.isCardEdit(self.identifier)) {

            // カードエンティティが渡ってきたら（編集時のみ）
            // FIXME: card typeは、KPTエリアで追加ボタン押下時に選択させるUIにする。
            // それまでは、変更できないように非活性にする
            for (var i = 0; i < typeSegment.numberOfSegments; i++) {
                typeSegment.setEnabled(false, forSegmentAtIndex: i)
            }
            
            // card情報を画面に設定
            typeSegment.selectedSegmentIndex = self.getSegmentIndexFromCardType(self.card!)
            titleField.text = self.card!.card_title
            descriptionField.text = self.card!.detail
            
            // カードタイプがKeep, Problemの場合、リレーションテーブルを非表示にする
            if (self.card!.isKeep()
                || self.card!.isProblem()) {
                relationCardTableView.hidden = true
                cardRelationLabel.hidden = true
            }
            
            // カードタイプがTryの場合、リレーションカードに値を設定する
            if (self.card!.isTry()) {
                self.selectedRelationCard = CardViewModel.findCardRelation(self.card!)
            }
            
        } else if (Identifiers.isCardAdd(self.identifier)) {
            // 新規作成の場合、relationカードは非表示
            relationCardTableView.hidden = true
            cardRelationLabel.hidden = true
        } else {
            // FIXME: 例外処理したい

        }
        
        // saveボタン非活性
        if (titleField.text! == "") {
            save.enabled = false
        }
        
        // CardTypeのセグメントのイベントを設定する
        cardTypeSegumentedControl.addTarget(self, action: "segmentedControlChanged:", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UITextFieldが編集されると呼ばれるデリゲートメソッド
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var textLength: Int;
        textLength = ( textField.text!.characters.count - range.length ) + string.characters.count;
        if (textLength != 0) {
            save.enabled = true
        } else {
            save.enabled = false
        }
        print(titleField.text)
        return true
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        if (Identifiers.isCardAdd(self.identifier)) {
            // カード追加の場合
            if (self.isKeepSegment(self.typeSegment)) {
                // Keepカード追加
                BoardViewModel.addKeepCard(self.board!, title: self.titleField.text!, detail: self.descriptionField.text)
            } else if (self.isProblemSegment(self.typeSegment)) {
                // Problemカード追加
                BoardViewModel.addProblemCard(self.board!, title: self.titleField.text!, detail: self.descriptionField.text)
            } else if (self.isTrySegment(self.typeSegment)) {
                // Tryカード追加
                // Tryカードの紐付け元を設定する
                if let relationCard = self.selectedRelationCard {
                    BoardViewModel.addTryCard(self.board, title: self.titleField.text!, detail: self.descriptionField.text, fromCard: relationCard)
                } else {
                    // リレーションカードが選択されていない場合、エラーポップアップ表示
                    let alertController = UIAlertController(title: "Not selected relation card.", message: "Please select a relation card on relation table.", preferredStyle: .Alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(defaultAction)
                    presentViewController(alertController, animated: true, completion: nil)

                    return
                }
            }
            
        } else if (Identifiers.isCardEdit(self.identifier)) {
            // カード編集
            let editCard: Card = Card()
            editCard.card_title = self.titleField.text!
            editCard.detail = self.descriptionField.text
            editCard.type = self.getCardTypeFromSegmentIndex(self.typeSegment.selectedSegmentIndex).rawValue
            CardViewModel.edit(self.card!, editCard: editCard)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    /**
    カードタイプに紐づくセグメントindexを取得する
    
    - parameter card: カードエンティティ
    
    - returns: カードタイプのセグメントindex
    */
    private func getSegmentIndexFromCardType (card: Card) -> Int {
        switch card.type {
        case Card.CardType.Keep.rawValue:
            return CardTypeSegmentIndex.Keep.rawValue
        case Card.CardType.Problem.rawValue:
            return CardTypeSegmentIndex.Problem.rawValue
        case Card.CardType.Try.rawValue:
            return CardTypeSegmentIndex.Try.rawValue
        default:
            return 0
            // FIXME: 想定外のタイプである場合例外処理とする
            // throw NSError(domain: "illegal card type. card type is [" + card.type + "]", code: -1, userInfo: nil)
        }
    }
    
    /**
     セグメントindexに紐づくカードタイプを取得する
     
     - parameter segmentIndex: カードタイプのセグメントindex
     
     - returns: カードタイプ
     */
    private func getCardTypeFromSegmentIndex(segmentIndex: Int) -> Card.CardType {
        switch segmentIndex {
        case CardTypeSegmentIndex.Keep.rawValue:
            return Card.CardType.Keep
        case CardTypeSegmentIndex.Problem.rawValue:
            return Card.CardType.Problem
        case CardTypeSegmentIndex.Try.rawValue:
            return Card.CardType.Try
        default:
            // FIXME: 想定外のセグメントindexである場合例外処理とする
            // throw NSError(domain: "illegal segment index. segment index is [" + segmentIndex + "]", code: -1, userInfo: nil)
            return Card.CardType.Keep
        }
    }
    
    /*
    segmentが切り替わったときに呼ばれるイベント
    */
    func segmentedControlChanged(sender: UISegmentedControl) {
        if (self.isTrySegment(sender)) {
            // relationテーブルにカードを表示する
            keepCardEntities = BoardViewModel.findKeepCard(self.board)
            problemCardEntities = BoardViewModel.findProblemCard(self.board)
            relationCardTableView.hidden = false
            cardRelationLabel.hidden = false
        } else {
            // relationテーブルを非表示（または非活性）にする
            relationCardTableView.hidden = true
            cardRelationLabel.hidden = true
        }
    }

    /*
    セクションの数を返す.
    */
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Keep, Problem, Tryテーブルそれぞれ1セクション固定
        return relationCardTableSections.count
    }
    
    /*
    セクションのタイトルを返す.
    */
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return relationCardTableSections[section]
    }
    
    /*
    Cellが選択された際に呼び出される.
    */
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 選択されたCardを保持しておく
        if (self.isKeepSection(indexPath.section)) {
            selectedRelationCard = keepCardEntities[indexPath.row]
        } else if(self.isProblemSection(indexPath.section)) {
            selectedRelationCard = problemCardEntities[indexPath.row]
        }
        // チェックをつける
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    /*
    Cellの選択が外れた時に呼び出される
    */
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        // チェックを外す
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.accessoryType = UITableViewCellAccessoryType.None
    }
    
    /*
    テーブルに表示する配列の総数を返す.
    */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.isKeepSection(section)) {
            return keepCardEntities.count
        } else if (self.isProblemSection(section)) {
            return problemCardEntities.count
        } else {
            return 0
        }
    }
    
    /*
    Cellに値を設定する.
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
        
        if (self.isKeepSection(indexPath.section)) {
            // Keepカードセクションの場合、Keepカードエンティティのタイトル、詳細をセルに設定する
            cell.textLabel!.text = keepCardEntities[indexPath.row].card_title
            cell.detailTextLabel!.text = keepCardEntities[indexPath.row].detail
            
            // 紐付けたカードのセルにチェックマークをつける
            if let relationCard = self.selectedRelationCard {
                if (relationCard.id == keepCardEntities[indexPath.row].id) {
                    // チェックをつける
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            }
            
        } else if (self.isProblemSection(indexPath.section)) {
            // Problemカードセクションの場合、Problemカードエンティティのタイトル、詳細をセルに設定する
            cell.textLabel!.text = problemCardEntities[indexPath.row].card_title
            cell.detailTextLabel!.text = problemCardEntities[indexPath.row].detail
            
            // 紐付けたカードのセルにチェックマークをつける
            if let relationCard = self.selectedRelationCard {
                if (relationCard.id == problemCardEntities[indexPath.row].id) {
                    // チェックをつける
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            }
        }
        return cell
    }
    
    /**
     カードタイプにKeepが選択されているか
     - parameter segment: セグメントコントロール
     - returns: true YES、false No
     */
    private func isKeepSegment(segment: UISegmentedControl) -> Bool {
        return segment.selectedSegmentIndex == CardTypeSegmentIndex.Keep.rawValue
    }
    
    /**
     カードタイプにProblemが選択されているか
     - parameter segment: セグメントコントロール
     - returns: true YES、false No
     */
    private func isProblemSegment(segment: UISegmentedControl) -> Bool {
        return segment.selectedSegmentIndex == CardTypeSegmentIndex.Problem.rawValue
    }
    
    /**
     カードタイプにTryが選択されているか
     - parameter segment: セグメントコントロール
     - returns: true YES、false No
     */
    private func isTrySegment(segment: UISegmentedControl) -> Bool {
        return segment.selectedSegmentIndex == CardTypeSegmentIndex.Try.rawValue
    }
    
    /**
     リレーションカード選択テーブルの中のKeepカードセクションかどうか
     - parameter section: セクション番号
     - returns: true YES、false No
     */
    private func isKeepSection(section: Int) -> Bool {
        return section == CardTypeSectionIndex.Keep.rawValue
    }
    
    /**
     リレーションカード選択テーブルの中のProblemカードセクションかどうか
     - parameter section: セクション番号
     - returns: true YES、false No
     */
    private func isProblemSection(section: Int) -> Bool {
        return section == CardTypeSectionIndex.Problem.rawValue
    }
}

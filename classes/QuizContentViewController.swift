//
//  QuizContentViewController.swift
//  tourismtemplate
//
//  Created by Kostiantyn Nikitchenko on 31.08.2021.
//  Copyright © 2021 xamoom GmbH. All rights reserved.
//

import UIKit
import XamoomSDK
import MBProgressHUD

class QuizContentViewController: ContentViewController {
    
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
      super.viewDidLoad()
        
        if let content = content, let tags = content.tags as? [String], tags.contains(Globals.Tag.quiz) || tags.contains(Globals.Tag.quiz.uppercased()) {
          if QuizHelper.isQuizSubmitted(pageId: content.id as! String) {
            contentBlocks?.showCBFormOverlay = true
          }
        }
    }
    
    override func createContentVC() -> ContentViewControllerProtocol {
      return QuizContentViewController(nibName: "QuizContentViewController", bundle: Bundle.main)
    }
    
    override func showContent(content: XMMContent) {
      self.hideNothingFoundView()

      if let blocks = self.content?.contentBlocks as? [XMMContentBlock] {
        if blocks.count <= 1 {
          self.content = ContentHelper.addContentDescription(content: content);
        } else if let firstBlock = blocks[1] as? XMMContentBlock, firstBlock.blockType != 100 {
          self.content = ContentHelper.addContentDescription(content: content);
        }
      } else {
        self.content = ContentHelper.addContentDescription(content: content);
      }
      
      if let tags = content.tags as? [String], tags.contains(Globals.Tag.voucher) || tags.contains(Globals.Tag.voucher.uppercased()) {
          ApiHelper.shared.getVoucherStatus(withId: content.id as! String, completion: { status in
            if let _ = self.getVouchersNeededToRedeem() { self.showRedeemVoucherButton() }
            if UserDefaults.standard.bool(forKey: Globals.Settings.isSocialSharingEnabled) {
                self.tableHeaderView?.addShareButton()
                self.tableHeaderView?.shareButton.addTarget(self, action: #selector(self.shareTapped), for: .touchUpInside)
            }
          })
      }
      
      if let title = content.title {
        AnalyticsHelper.reportGoogleAnalyticsScreen(screenName: "iOS Content screen \(title)")
      }
      self.contentBlocks?.display(self.content, addHeader: false)
      reloadContent = false
      showHeaderImage(imageUrl: content.imagePublicUrl)
    }
    
    private func showRedeemVoucherButton() {
      self.tableHeaderView?.releaseViewLabel.text = NSLocalizedString("voucher.redeem", comment: "")
      tableHeaderView?.releaseActionView.isHidden = false
      tableHeaderView?.releaseActionView.alpha = 1
      tableHeaderView?.releaseActionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.didClickScanQrNfcButton(sender:))))
    }
    
    private func handleScanResult(scannedText: String, type: ScanType, scanVC: ScanViewController) {
      ApiHelper.shared.redeemVoucher(withId: content!.id as! String, redeemCode: scannedText, completion: { (status, error) in
        if (error == nil) {
          self.showRedemptionNotification(title: String(format: NSLocalizedString("voucher.redemption.successful.notification", comment: ""), "\(self.content?.title ?? "")"))
          AnalyticsHelper.reportCustomEvent(name: "Voucher", action: "Voucher Redeemed",
                                            description: "Content id: \(self.content!.id)", code: nil)
            if let _ = self.getVouchersNeededToRedeem() {
                self.showRedeemVoucherButton()
                if let vouchersNeededToRedeem = self.getVouchersNeededToRedeem() {
                    QuizHelper.spendVoucher(vouchersAmount: vouchersNeededToRedeem)
                }
              } else {
                  self.showRedemptionNotification(title: String(format: NSLocalizedString("voucher.redemption.error.notification", comment: ""), "\(self.content?.title ?? "")"))
              }
            }
      })
    }
    
    private func showRedemptionNotification(title: String){
      let alert = UIAlertController(title: title,
                                    message: "",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(alert, animated: true)
    }
    
    @objc override func didClickScanQrNfcButton(sender: Any) {
      let currentVouchersAmount = QuizHelper.getVoucherAmount()
      if let vouchersNeededToRedeem = getVouchersNeededToRedeem() {
        if currentVouchersAmount >= vouchersNeededToRedeem {
            showVouchersCostAlert(vouchersAmount: currentVouchersAmount, vouchersCost: vouchersNeededToRedeem)
        } else {
            showVouchersNotEnoughAlert(vouchersAmount: currentVouchersAmount, vouchersCost: vouchersNeededToRedeem)
          }
      }
    }
    
    private func getVouchersNeededToRedeem() -> Int? {
        if let vouchersCost = content?.customMeta["vouchers"] as? String {
          return Int(vouchersCost)
        } else { return nil }
      }
    
    private func showVouchersCostAlert(vouchersAmount: Int, vouchersCost: Int) {
        let alert = UIAlertController(title: NSLocalizedString("quiz.voucher.redemption.successful.alert.title", comment: ""), message: String(format: NSLocalizedString("quiz.voucher.redemption.successful.alert.subtitle", comment: ""), vouchersCost, vouchersAmount), preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.answer.button.close", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.voucher.redemption.successful.alert.scan", comment: ""), style: .default, handler: { action in
          self.goToScanVC()
        }))

        self.present(alert, animated: true)
      }
    
    private func showVouchersNotEnoughAlert(vouchersAmount: Int, vouchersCost: Int) {
        let alert = UIAlertController(title: NSLocalizedString("quiz.voucher.redemption.fail.alert.title", comment: ""), message: String(format: NSLocalizedString("quiz.voucher.redemption.fail.alert.subtitle", comment: ""), vouchersCost, vouchersAmount), preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.answer.button.close", comment: ""), style: .cancel, handler: nil))

        self.present(alert, animated: true)
      }
    
    private func goToScanVC() {
        let scanVC = ScanViewController(nibName: "ScanViewController", bundle: nil)
        scanVC.didScanAction = { (text, type) in
          self.handleScanResult(scannedText: text, type: type, scanVC: scanVC)
        }
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(scanVC, animated: true)
        self.hidesBottomBarWhenPushed = false
      }
    
    @objc override func didClickRedeemedVoucherButton(sender: Any) {
        let alert = UIAlertController(
          title: NSLocalizedString("voucher.redeemed.alert.title", comment: ""),
          message: NSLocalizedString("voucher.redeemed.alert.description", comment: ""),
          preferredStyle: .alert)
        
        let okAction = UIAlertAction(
          title: "OK",
          style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
        
      }
    
    private func showSuccessAlert(pointsAchieved: Int, successMessage: String?) {
      var alertSubtitle = "\(pointsAchieved)\n"
      alertSubtitle.append(NSLocalizedString("quiz.right.answer.subtitle", comment: ""))
      if let message = successMessage {
        alertSubtitle.append(message)
      }
      
      let alert = UIAlertController(title: NSLocalizedString("quiz.right.answer.title", comment: ""), message: alertSubtitle, preferredStyle: .alert)

      alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.answer.button.close", comment: ""), style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.answer.button.goToScore", comment: ""), style: .default, handler: { action in
        let quizScoreVC = QuizScoreViewController(nibName: "QuizScoreViewController", bundle: Bundle.main)
        self.navigationController?.pushViewController(quizScoreVC, animated: true)
      }))

      self.present(alert, animated: true)
    }
    
    private func showFailAlert() {
      let alert = UIAlertController(title: NSLocalizedString("quiz.wrong.answer.title", comment: ""), message: NSLocalizedString("quiz.wrong.answer.subtitle", comment: ""), preferredStyle: .alert)

      alert.addAction(UIAlertAction(title: NSLocalizedString("quiz.answer.button.close", comment: ""), style: .cancel, handler: nil))

      self.present(alert, animated: true)
    }
    
    override func onQuizHTMLResponse(_ htmlResponse: String!) {
      if let content = content, let tags = content.tags as? [String], tags.contains(Globals.Tag.quiz) || tags.contains(Globals.Tag.quiz.uppercased()) {
        
        let pointsString = getPointsFromQuizHTMLResponse(html: htmlResponse)
        
        if let parsedPoints = pointsString {
          var points = Int(parsedPoints) ?? 0
          if points > 0 {
            points = 100 // All quizes have 100 points
            playSound(named: Globals.Sound.correctAnswerKey)
            QuizHelper.increasePointsAmount(scoredPoints: points)
            QuizHelper.saveQuiz(quiz: Quiz(pageId: content.id as! String, submittedDate: Date()))
            QuizHelper.incrementVouchersAmount(on: points)
            
            let message = getSuccessMessageFromQuizHTMLResponse(html: htmlResponse)
            showSuccessAlert(pointsAchieved: points, successMessage: message)
          } else {
            playSound(named: Globals.Sound.incorrectAnswerKey)
            showFailAlert()
          }
        }
      }
    }
    
    private func getPointsFromQuizHTMLResponse(html: String!) -> String? {
        print(html)
      if let range = html.range(of: "id=\"score\"") {
          print()
        let stringAfterScoreValue = html.substring(from: range.lowerBound)
        var pointsValue = String()
        
        for char in stringAfterScoreValue {
          if isCharDigit(char: char) {
            pointsValue.append(char)
            continue
          }
          if pointsValue.count > 0  && !isCharDigit(char: char) {
            break
          }
          
        }
        return pointsValue
      }
      else {
        return nil
      }
    }
    
    private func getSuccessMessageFromQuizHTMLResponse(html: String!) -> String? {
      return HTMLHelper.matches(for: "(?<=gquiz-answer-explanation\">)[^<]*", in: html)
    }
    
    private func isCharDigit(char: String.Element) -> Bool {
      return char.isASCII && char.isNumber
    }
}

extension QuizContentViewController: SoundEffectProtocol {}

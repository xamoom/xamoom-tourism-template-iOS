import UIKit

class ContentTableHeaderView: UIView {
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var releaseActionView: UIView!
    @IBOutlet weak var releaseViewLabel: UILabel!
    var shareButton: UIButton!
        
    func addShareButton() {
            if self.shareButton != nil {
                self.shareButton.removeFromSuperview()
            }
            shareButton = UIButton()
            shareButton.setImage(UIImage(named: "shareIcon"), for: .normal)
            self.addSubview(shareButton)
            shareButton.translatesAutoresizingMaskIntoConstraints = false
            shareButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            shareButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
            shareButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        
            if releaseActionView.isHidden {
                shareButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
            } else {
                shareButton.bottomAnchor.constraint(equalTo: self.releaseActionView.topAnchor, constant: -8).isActive = true
            }
    }

}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

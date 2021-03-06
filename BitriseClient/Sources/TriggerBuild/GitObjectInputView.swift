import ActionPopoverButton
import RxSwift
import RxCocoa
import UIKit

private final class GitObjectTypeButton: ActionPopoverButton {

    let imageView: UIImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override func updateConstraints() {
        super.updateConstraints()

        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.gitRed
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = UIColor.gitRedHighlight
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = UIColor.gitRed
    }

    private func configure() {
        addSubview(imageView)
    }

}

private func _button(_ image: UIImage) -> UIButton {
    let b = UIButton(type: .system)
    b.setImage(image, for: .normal)
    b.layer.cornerRadius = 6
    b.tintColor = .white
    b.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        b.heightAnchor.constraint(equalToConstant: 40),
        b.widthAnchor.constraint(equalToConstant: 40),
    ])
    return b
}

final class GitObjectInputView: UIView, UITextFieldDelegate {

    struct Placeholder {
        let text: String

        init(_ gitObject: GitObject) {
            switch gitObject {
            case .branch:
                self.text = "branch"
            case .tag:
                self.text = "tag"
            case .commitHash:
                self.text = "commit"
            }
        }
    }

    // Input result
    let newInput: Property<GitObject>
    private let _newInput = BehaviorRelay<GitObject>(value: .branch(""))

    let textFieldDelegate = TextFieldDelegate()

    private let objectTypeButton: GitObjectTypeButton = {
        let button = GitObjectTypeButton()
        button.backgroundColor = UIColor.baseGreen
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 0.3
        button.layer.borderColor = UIColor(hex: 0x888888).cgColor
        button.tintColor = .white
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        return button
    }()

    @IBOutlet private weak var stackView: UIStackView! {
        didSet {
            stackView.insertArrangedSubview(objectTypeButton, at: 0)
        }
    }

    @IBOutlet private weak var objectTextField: UITextField! {
        didSet {
            objectTextField.delegate = textFieldDelegate

            textFieldDelegate.didEndEditing
                .subscribe(onNext: { [weak self] text in
                    guard let me = self else { return }

                    let str: String = text ?? ""
                    me._newInput.accept(me._newInput.value.updateAssociatedValue(str))
                    me.updatePlaceholder()
                })
                .disposed(by: rx.disposeBag)
        }
    }

    override init(frame: CGRect) {
        self.newInput = Property(_newInput)
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        self.newInput = Property(_newInput)
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 6

        for gitObject in GitObject.enumerated() {
            objectTypeButton.addActionButton(_button(gitObject.image)) { [weak self] in
                guard let me = self else { return }

                me.objectTypeButton.imageView.image = gitObject.image

                me._newInput.accept(gitObject.updateAssociatedValue(me.objectTextField.text ?? ""))
                me.updatePlaceholder()

                Haptic.generate(.heavy)
            }
        }

        objectTypeButton.onFocusActionChanged {
            Haptic.generate(.light)
        }
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        objectTextField.resignFirstResponder()

        return super.resignFirstResponder()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hit = super.hitTest(point, with: event) {
            return hit
        }

        return objectTypeButton.hitTest(convert(point, to: objectTypeButton), with: event)
    }

    // MARK: Utilities

    /// - relay: False to set initial value without emitting Event via newInput Property.
    func updateUI(_ gitObject: GitObject, relay: Bool) {
        objectTextField.text = gitObject.text
        objectTextField.placeholder = Placeholder(gitObject).text
        objectTypeButton.imageView.image = gitObject.image

        if relay {
            _newInput.accept(gitObject)
        }
    }

    private func updatePlaceholder() {
        objectTextField.placeholder = Placeholder(_newInput.value).text
    }
}


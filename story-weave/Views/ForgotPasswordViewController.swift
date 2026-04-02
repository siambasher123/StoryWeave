import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) { performSendReset() }
    @IBAction func backToLoginTapped(_ sender: UIButton) { navigationController?.popViewController(animated: true) }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(container)

        let iconView = UIImageView(image: UIImage(systemName: "lock.rotation"))
        iconView.tintColor = .systemIndigo
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Reset Password"
        if let serif = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.serif) {
            titleLabel.font = UIFont(descriptor: serif, size: 34)
        }
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Enter your email to receive a reset link"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let emailTF = makeTextField(placeholder: "Email", icon: "envelope", isSecure: false)
        emailTF.keyboardType = .emailAddress
        emailField = emailTF

        let fbLabel = UILabel()
        fbLabel.font = .preferredFont(forTextStyle: .footnote)
        fbLabel.textAlignment = .center
        fbLabel.numberOfLines = 0
        fbLabel.isHidden = true
        fbLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel = fbLabel

        let btn = makePrimaryButton(title: "Send Reset Link")
        btn.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton = btn

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator = indicator

        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setTitle("Back to Login", for: .normal)
        backBtn.setTitleColor(.systemIndigo, for: .normal)
        backBtn.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        backBtn.addTarget(self, action: #selector(backToLoginTapped), for: .touchUpInside)

        [iconView, titleLabel, subtitleLabel,
         emailTF, btn, indicator, fbLabel, backBtn
        ].forEach { container.addSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            container.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 60),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            emailTF.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            emailTF.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            emailTF.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            emailTF.heightAnchor.constraint(equalToConstant: 54),

            btn.topAnchor.constraint(equalTo: emailTF.bottomAnchor, constant: 24),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            btn.heightAnchor.constraint(equalToConstant: 54),

            indicator.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: btn.centerYAnchor),

            fbLabel.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 12),
            fbLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            fbLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            backBtn.topAnchor.constraint(equalTo: fbLabel.bottomAnchor, constant: 20),
            backBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            backBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40),
        ])
    }

    private func makeTextField(placeholder: String, icon: String, isSecure: Bool) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = isSecure
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 14
        tf.layer.masksToBounds = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 54))
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = .secondaryLabel
        img.contentMode = .scaleAspectFit
        img.frame = CGRect(x: 12, y: 17, width: 20, height: 20)
        iconContainer.addSubview(img)
        tf.leftView = iconContainer
        tf.leftViewMode = .always
        let rightPad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 54))
        tf.rightView = rightPad
        tf.rightViewMode = .always
        return tf
    }

    private func makePrimaryButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemIndigo
        btn.layer.cornerRadius = 14
        btn.layer.masksToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func isValidEmail(_ value: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: value)
    }

    private func performSendReset() {
        guard let email = emailField.text, !email.isEmpty else {
            showFeedback("Enter your email address.", isSuccess: false)
            return
        }
        guard isValidEmail(email) else {
            showFeedback("Enter a valid email address.", isSuccess: false)
            return
        }
        setLoading(true)
        AuthService.shared.sendPasswordReset(email: email) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .success:
                    self.showFeedback("Check your inbox for a reset link.", isSuccess: true)
                    self.sendButton.isEnabled = false
                case .failure(let error):
                    self.showFeedback(error.localizedDescription, isSuccess: false)
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        sendButton.isEnabled = !loading
        if loading {
            sendButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
        } else {
            sendButton.setTitle("Send Reset Link", for: .normal)
            activityIndicator.stopAnimating()
        }
    }
    
    private func showFeedback(_ message: String, isSuccess: Bool) {
        feedbackLabel.text = message
        feedbackLabel.textColor = isSuccess ? .systemGreen : .systemRed
        feedbackLabel.isHidden = false
    }
}

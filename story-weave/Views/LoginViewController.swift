import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) { performLogin() }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        navigationController?.pushViewController(RegisterViewController(), animated: true)
    }

    @objc private func forgotPasswordTapped() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(container)

        let iconView = UIImageView(image: UIImage(systemName: "books.vertical.fill"))
        iconView.tintColor = .systemIndigo
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "StoryWeave"
        if let serif = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.serif) {
            titleLabel.font = UIFont(descriptor: serif, size: 38)
        }
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your interactive story library"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let emailTF = makeTextField(placeholder: "Email", icon: "envelope", isSecure: false)
        emailTF.keyboardType = .emailAddress
        emailField = emailTF

        let passwordTF = makeTextField(placeholder: "Password", icon: "lock", isSecure: true)
        passwordField = passwordTF

        let errLabel = UILabel()
        errLabel.font = .preferredFont(forTextStyle: .footnote)
        errLabel.textColor = .systemRed
        errLabel.textAlignment = .center
        errLabel.numberOfLines = 0
        errLabel.isHidden = true
        errLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel = errLabel

        let btn = makePrimaryButton(title: "Log In")
        btn.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton = btn

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator = indicator

        let signUpBtn = UIButton(type: .system)
        signUpBtn.translatesAutoresizingMaskIntoConstraints = false
        let signUpAttr = NSMutableAttributedString(
            string: "Don't have an account?  ",
            attributes: [.foregroundColor: UIColor.secondaryLabel, .font: UIFont.preferredFont(forTextStyle: .subheadline)]
        )
        signUpAttr.append(NSAttributedString(
            string: "Sign Up",
            attributes: [.foregroundColor: UIColor.systemIndigo, .font: UIFont.systemFont(ofSize: 15, weight: .semibold)]
        ))
        signUpBtn.setAttributedTitle(signUpAttr, for: .normal)
        signUpBtn.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)

        let forgotBtn = UIButton(type: .system)
        forgotBtn.translatesAutoresizingMaskIntoConstraints = false
        forgotBtn.setTitle("Forgot Password?", for: .normal)
        forgotBtn.setTitleColor(.systemIndigo, for: .normal)
        forgotBtn.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        forgotBtn.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        [iconView, titleLabel, subtitleLabel,
         emailTF, passwordTF, errLabel, btn, indicator, signUpBtn, forgotBtn
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

            passwordTF.topAnchor.constraint(equalTo: emailTF.bottomAnchor, constant: 16),
            passwordTF.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            passwordTF.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            passwordTF.heightAnchor.constraint(equalToConstant: 54),

            errLabel.topAnchor.constraint(equalTo: passwordTF.bottomAnchor, constant: 12),
            errLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            errLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            btn.topAnchor.constraint(equalTo: errLabel.bottomAnchor, constant: 12),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            btn.heightAnchor.constraint(equalToConstant: 54),

            indicator.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: btn.centerYAnchor),

            signUpBtn.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 20),
            signUpBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            forgotBtn.topAnchor.constraint(equalTo: signUpBtn.bottomAnchor, constant: 12),
            forgotBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            forgotBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40),
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

    private func performLogin() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showError("Enter your email and password.")
            return
        }
        guard isValidEmail(email) else {
            showError("Enter a valid email address.")
            return
        }
        setLoading(true)
        AuthService.shared.login(email: email, password: password) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .success(let user):
                    AppSession.shared.set(userId: user.userId, email: user.email)
                    self.navigationController?.setViewControllers([MainHostViewController()], animated: true)
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        loginButton.isEnabled = !loading
        if loading {
            loginButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
        } else {
            loginButton.setTitle("Log In", for: .normal)
            activityIndicator.stopAnimating()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

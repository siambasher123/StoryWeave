import UIKit

class RegisterViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Actions

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        performRegister()
    }

    @IBAction func backToLoginTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Private UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(container)

        // ── Hero ─────────────────────────────────────────────────────────
        let iconView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
        iconView.tintColor = .systemIndigo
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Create Account"
        if let serif = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif) {
            titleLabel.font = UIFont(descriptor: serif, size: 34)
        }
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Join StoryWeave today"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Fields ───────────────────────────────────────────────────────
        let emailTF = makeTextField(placeholder: "Email", icon: "envelope", isSecure: false)
        emailTF.keyboardType = .emailAddress
        emailField = emailTF

        let passwordTF = makeTextField(placeholder: "Password", icon: "lock", isSecure: true)
        passwordField = passwordTF

        let confirmTF = makeTextField(
            placeholder: "Confirm Password", icon: "lock.rotation", isSecure: true)
        confirmPasswordField = confirmTF

        // ── Error label ──────────────────────────────────────────────────
        let errLabel = UILabel()
        errLabel.font = .preferredFont(forTextStyle: .footnote)
        errLabel.textColor = .systemRed
        errLabel.textAlignment = .center
        errLabel.numberOfLines = 0
        errLabel.isHidden = true
        errLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel = errLabel

        // ── Primary button ───────────────────────────────────────────────
        let btn = makePrimaryButton(title: "Create Account")
        btn.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        registerButton = btn

        // ── Activity indicator ───────────────────────────────────────────
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator = indicator

        // ── Back to login button ─────────────────────────────────────────
        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        let attrStr = NSMutableAttributedString(
            string: "Already have an account?  ",
            attributes: [.foregroundColor: UIColor.secondaryLabel,
                         .font: UIFont.preferredFont(forTextStyle: .subheadline)]
        )
        attrStr.append(NSAttributedString(
            string: "Log In",
            attributes: [.foregroundColor: UIColor.systemIndigo,
                         .font: UIFont.systemFont(ofSize: 15, weight: .semibold)]
        ))
        backBtn.setAttributedTitle(attrStr, for: .normal)
        backBtn.addTarget(self, action: #selector(backToLoginTapped), for: .touchUpInside)

        // ── Add to hierarchy ─────────────────────────────────────────────
        [iconView, titleLabel, subtitleLabel,
         emailTF, passwordTF, confirmTF, errLabel, btn, indicator, backBtn
        ].forEach { container.addSubview($0) }

        // ── Constraints ──────────────────────────────────────────────────
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

            confirmTF.topAnchor.constraint(equalTo: passwordTF.bottomAnchor, constant: 16),
            confirmTF.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            confirmTF.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            confirmTF.heightAnchor.constraint(equalToConstant: 54),

            errLabel.topAnchor.constraint(equalTo: confirmTF.bottomAnchor, constant: 12),
            errLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            errLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            btn.topAnchor.constraint(equalTo: errLabel.bottomAnchor, constant: 12),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            btn.heightAnchor.constraint(equalToConstant: 54),

            indicator.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: btn.centerYAnchor),

            backBtn.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 20),
            backBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            backBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Reusable UI helpers

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

    // MARK: - Register logic

    private func performRegister() {
        guard
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty,
            let confirm = confirmPasswordField.text, !confirm.isEmpty
        else {
            showError("Please fill in all fields.")
            return
        }
        guard password == confirm else {
            showError("Passwords do not match.")
            return
        }
        setLoading(true)
        AuthService.shared.register(email: email, password: password) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.setLoading(false)
                self.showError(error.localizedDescription)
            case .success(let user):
                FirestoreService.shared.createUser(userId: user.userId, email: user.email) { _ in
                    self.setLoading(false)
                    AppSession.shared.set(userId: user.userId, email: user.email)
                    self.navigationController?.setViewControllers(
                        [MainHostViewController()], animated: true)
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func setLoading(_ loading: Bool) {
        registerButton.isEnabled = !loading
        if loading {
            registerButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
        } else {
            registerButton.setTitle("Create Account", for: .normal)
            activityIndicator.stopAnimating()
        }
    }
}

import UIKit

final class ActivityTimerActionView: UIView {
    var onRecordTapped: (() -> Void)?
    var onTimerStatusTapped: (() -> Void)?

    private let timerStatusButton = UIButton(type: .system)
    private let accentColor = UIColor(red: 0.42, green: 0.39, blue: 0.96, alpha: 1)
    private let pausedColor = UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1)

    private lazy var recordButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Record"
        configuration.image = UIImage(systemName: "plus.circle.fill")
        configuration.imagePadding = 6
        configuration.buttonSize = .small
        configuration.cornerStyle = .fixed
        configuration.baseBackgroundColor = accentColor
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)

        let button = UIButton(configuration: configuration)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(
            UIAction { [weak self] _ in
                self?.onRecordTapped?()
            },
            for: .touchUpInside
        )
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    func configure(timerState: ActivityTimerState) {
        switch timerState {
        case .none:
            recordButton.isHidden = false
            timerStatusButton.isHidden = true
        case .running:
            recordButton.isHidden = true
            timerStatusButton.isHidden = false
            timerStatusButton.setImage(UIImage(systemName: "timer"), for: .normal)
            timerStatusButton.tintColor = accentColor
            timerStatusButton.backgroundColor = .clear
            timerStatusButton.layer.borderColor = accentColor.cgColor
            timerStatusButton.layer.borderWidth = 0
            timerStatusButton.accessibilityLabel = "Timer running"
        case .paused:
            recordButton.isHidden = true
            timerStatusButton.isHidden = false
            timerStatusButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            timerStatusButton.tintColor = pausedColor
            timerStatusButton.backgroundColor = .clear
            timerStatusButton.layer.borderWidth = 0
            timerStatusButton.accessibilityLabel = "Timer paused"
        }
    }

    func prepareForReuse() {
        onRecordTapped = nil
        onTimerStatusTapped = nil
        configure(timerState: .none)
    }

    private func configureView() {
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        timerStatusButton.tintColor = accentColor
        timerStatusButton.isHidden = true
        timerStatusButton.addAction(
            UIAction { [weak self] _ in
                self?.onTimerStatusTapped?()
            },
            for: .touchUpInside
        )

        recordButton.translatesAutoresizingMaskIntoConstraints = false
        timerStatusButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(recordButton)
        addSubview(timerStatusButton)

        NSLayoutConstraint.activate([
            recordButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            recordButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            recordButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            timerStatusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            timerStatusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            timerStatusButton.widthAnchor.constraint(equalToConstant: 36),
            timerStatusButton.heightAnchor.constraint(equalToConstant: 36),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            widthAnchor.constraint(greaterThanOrEqualTo: timerStatusButton.widthAnchor)
        ])
    }
}

import UIKit
import SwiftData

final class TagsManagementViewController: UIViewController {
    enum PrimaryActionMode {
        case createTag
        case saveSelection
    }

    static let activityTypeEmptyStateMessage = "Create tags for activity types, then attach them to types like Groceries, Morning commute, or Exercise.\n\nExamples: Chores, Commute, Fitness"

    private static let maximumTagCount = 7
    private static let maximumTagNameLength = 15

    private final class CompactChipFlowLayout: UICollectionViewFlowLayout {
        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            guard let attributes = super.layoutAttributesForElements(in: rect) else {
                return nil
            }

            var currentRowMinY: CGFloat = -1
            var currentX = sectionInset.left

            return attributes.map { attributes in
                let adjustedAttributes = attributes.copy() as? UICollectionViewLayoutAttributes ?? attributes
                guard adjustedAttributes.representedElementCategory == .cell else {
                    return adjustedAttributes
                }

                if abs(adjustedAttributes.frame.minY - currentRowMinY) > 1 {
                    currentRowMinY = adjustedAttributes.frame.minY
                    currentX = sectionInset.left
                }

                adjustedAttributes.frame.origin.x = currentX
                currentX = adjustedAttributes.frame.maxX + minimumInteritemSpacing
                return adjustedAttributes
            }
        }

        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            true
        }
    }

    private struct TagRow {
        let tag: ActivityTag
        let name: String
    }

    private final class TagChipCell: UICollectionViewCell {
        static let reuseIdentifier = "TagChipCell"
        private static let horizontalPadding: CGFloat = 28
        private static let chipHeight: CGFloat = 34
        private static let font = UIFont.systemFont(ofSize: 15, weight: .medium)

        private let nameLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: TagRow, isSelected: Bool) {
            nameLabel.text = row.name
            contentView.backgroundColor = isSelected ? .systemBlue : .secondarySystemGroupedBackground
            contentView.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.separator.cgColor
            nameLabel.textColor = isSelected ? .white : .label
        }

        static func fittingSize(for text: String, maximumWidth: CGFloat) -> CGSize {
            let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
            return CGSize(
                width: min(textWidth + horizontalPadding, maximumWidth),
                height: chipHeight
            )
        }

        private func configureCell() {
            contentView.backgroundColor = .secondarySystemGroupedBackground
            contentView.layer.cornerRadius = 17
            contentView.layer.cornerCurve = .continuous
            contentView.layer.borderColor = UIColor.separator.cgColor
            contentView.layer.borderWidth = 0.5
            contentView.clipsToBounds = true

            nameLabel.font = Self.font
            nameLabel.textColor = .label
            nameLabel.numberOfLines = 1
            nameLabel.lineBreakMode = .byTruncatingTail
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(nameLabel)

            NSLayoutConstraint.activate([
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
                nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        }
    }

    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private let emptyStateLabel = UILabel()
    private let tagLimitMessageLabel = UILabel()
    private let createTagButton = UIButton(type: .system)
    private var tagRows: [TagRow] = []
    private var initialSelectedTagIDs: Set<UUID> = []

    var modelContext: ModelContext?
    var sheetTitle = "Tags"
    var emptyStateMessage = "No tags"
    var selectedTagIDs: Set<UUID> = []
    var primaryActionMode: PrimaryActionMode = .createTag
    var groupsSelectedTagsFirst = false
    var commitsSelectionImmediately = true
    var allowsTagManagement = true
    var selectsCreatedTags = false
    var switchesToSaveSelectionAfterCreatingTag = false
    var onSelectionChange: ((Set<UUID>) -> Void)?
    var onTagsChange: (() -> Void)?
    var onTagCreate: ((ActivityTag) -> Void)?
    var onSaveSelection: ((Set<UUID>) -> Void)?

    init() {
        let layout = CompactChipFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 20, right: 20)
        layout.estimatedItemSize = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let layout = CompactChipFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 20, right: 20)
        layout.estimatedItemSize = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initialSelectedTagIDs = selectedTagIDs
        configureAppearance()
        loadTags()
    }

    private func configureAppearance() {
        view.backgroundColor = .systemGroupedBackground

        titleLabel.text = sheetTitle
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(TagChipCell.self, forCellWithReuseIdentifier: TagChipCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = emptyStateMessage
        emptyStateLabel.font = .systemFont(ofSize: 15, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        tagLimitMessageLabel.text = "Up to 7 tags for now"
        tagLimitMessageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        tagLimitMessageLabel.textColor = .secondaryLabel
        tagLimitMessageLabel.textAlignment = .right
        tagLimitMessageLabel.numberOfLines = 2
        tagLimitMessageLabel.isHidden = true
        tagLimitMessageLabel.translatesAutoresizingMaskIntoConstraints = false

        configureCreateTagButton()

        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(tagLimitMessageLabel)
        view.addSubview(createTagButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: createTagButton.topAnchor, constant: -12),

            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tagLimitMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            tagLimitMessageLabel.trailingAnchor.constraint(equalTo: createTagButton.leadingAnchor, constant: -12),
            tagLimitMessageLabel.centerYAnchor.constraint(equalTo: createTagButton.centerYAnchor),

            createTagButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            createTagButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createTagButton.heightAnchor.constraint(equalToConstant: 50),
            createTagButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])
    }

    private func configureCreateTagButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Create Tag"
        configuration.buttonSize = .large
        configuration.cornerStyle = .fixed
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 20, bottom: 13, trailing: 20)

        createTagButton.configuration = configuration
        createTagButton.layer.cornerRadius = 12
        createTagButton.layer.cornerCurve = .continuous
        createTagButton.clipsToBounds = true
        createTagButton.layer.shadowColor = UIColor.black.cgColor
        createTagButton.layer.shadowOpacity = 0.16
        createTagButton.layer.shadowRadius = 10
        createTagButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        createTagButton.translatesAutoresizingMaskIntoConstraints = false
        createTagButton.addAction(
            UIAction { [weak self] _ in
                self?.primaryButtonTapped()
            },
            for: .touchUpInside
        )
    }

    private func loadTags() {
        guard let modelContext else {
            tagRows = []
            updateContent()
            return
        }

        do {
            let tags = try modelContext.fetch(FetchDescriptor<ActivityTag>())
            tagRows = tags
                .map { TagRow(tag: $0, name: $0.name) }
                .sorted(by: sortTagRows)
            updateContent()
        } catch {
            assertionFailure("Unable to load tags: \(error)")
        }
    }

    private func updateContent() {
        collectionView.reloadData()
        emptyStateLabel.isHidden = !tagRows.isEmpty
        updateCreateTagButton()
    }

    private func updateCreateTagButton() {
        guard primaryActionMode == .createTag else {
            tagLimitMessageLabel.isHidden = true
            createTagButton.isEnabled = selectedTagIDs != initialSelectedTagIDs
            var configuration = createTagButton.configuration
            configuration?.title = "Save"
            configuration?.baseBackgroundColor = createTagButton.isEnabled ? .systemBlue : .systemGray3
            createTagButton.configuration = configuration
            return
        }

        let canCreateTag = tagRows.count < Self.maximumTagCount
        tagLimitMessageLabel.isHidden = canCreateTag
        createTagButton.isEnabled = canCreateTag

        var configuration = createTagButton.configuration
        configuration?.title = "Create Tag"
        configuration?.baseBackgroundColor = canCreateTag ? .systemBlue : .systemGray4
        createTagButton.configuration = configuration
    }

    private func primaryButtonTapped() {
        switch primaryActionMode {
        case .createTag:
            presentCreateTagAlert()
        case .saveSelection:
            saveSelection()
        }
    }

    private func saveSelection() {
        guard selectedTagIDs != initialSelectedTagIDs else {
            return
        }

        onSaveSelection?(selectedTagIDs)
        dismiss(animated: true)
    }

    private func presentCreateTagAlert() {
        guard tagRows.count < Self.maximumTagCount else {
            presentTagLimitReachedAlert()
            return
        }

        let existingNames = fetchExistingTagNames(excluding: nil)
        let alertController = UIAlertController(
            title: "New Tag",
            message: "Enter a tag name up to \(Self.maximumTagNameLength) characters.",
            preferredStyle: .alert
        )

        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alertController] _ in
            guard let name = alertController?.textFields?.first?.text else {
                return
            }

            self?.createTag(named: name)
        }
        createAction.isEnabled = false

        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Tag name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.addAction(
                UIAction { [weak self, weak textField] _ in
                    createAction.isEnabled = self?.isUniqueTagName(
                        textField?.text,
                        existingNames: existingNames
                    ) ?? false
                },
                for: .editingChanged
            )
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(createAction)
        present(alertController, animated: true)
    }

    private func presentTagLimitReachedAlert() {
        let alertController = UIAlertController(
            title: "Tags Are Full",
            message: "You can keep up to \(Self.maximumTagCount) tags for now.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func createTag(named name: String) {
        guard let modelContext else {
            return
        }

        guard tagRows.count < Self.maximumTagCount else {
            presentTagLimitReachedAlert()
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUniqueTagName(trimmedName, existingNames: fetchExistingTagNames(excluding: nil)) else {
            presentCreateTagAlert()
            return
        }

        let tag = ActivityTag(name: trimmedName)
        modelContext.insert(tag)

        do {
            try modelContext.save()
            if selectsCreatedTags {
                selectedTagIDs.insert(tag.uniqueID)
            }
            onTagCreate?(tag)
            if switchesToSaveSelectionAfterCreatingTag {
                primaryActionMode = .saveSelection
                groupsSelectedTagsFirst = true
                commitsSelectionImmediately = false
                allowsTagManagement = false
                initialSelectedTagIDs = selectedTagIDs
            }
            loadTags()
            onTagsChange?()
        } catch {
            modelContext.delete(tag)
            assertionFailure("Unable to save tag: \(error)")
            presentCreateTagAlert()
        }
    }

    private func presentRenameTagAlert(for tag: ActivityTag) {
        let existingNames = fetchExistingTagNames(excluding: tag)
        let alertController = UIAlertController(
            title: "Rename Tag",
            message: "Enter a tag name up to \(Self.maximumTagNameLength) characters.",
            preferredStyle: .alert
        )

        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self, weak alertController, weak tag] _ in
            guard
                let tag,
                let name = alertController?.textFields?.first?.text
            else {
                return
            }

            self?.renameTag(tag, to: name)
        }

        alertController.addTextField { [weak self] textField in
            textField.text = tag.name
            textField.placeholder = "Tag name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.addAction(
                UIAction { [weak self, weak textField] _ in
                    renameAction.isEnabled = self?.isUniqueTagName(
                        textField?.text,
                        existingNames: existingNames
                    ) ?? false
                },
                for: .editingChanged
            )
        }
        renameAction.isEnabled = false

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(renameAction)
        present(alertController, animated: true)
    }

    private func renameTag(_ tag: ActivityTag, to name: String) {
        guard modelContext != nil else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUniqueTagName(trimmedName, existingNames: fetchExistingTagNames(excluding: tag)) else {
            presentRenameTagAlert(for: tag)
            return
        }

        tag.name = trimmedName

        do {
            try modelContext?.save()
            loadTags()
            onTagsChange?()
        } catch {
            assertionFailure("Unable to rename tag: \(error)")
            presentRenameTagAlert(for: tag)
        }
    }

    private func presentDeleteTagAlert(for tag: ActivityTag) {
        let alertController = UIAlertController(
            title: "Delete Tag?",
            message: "This removes \(tag.name) from every activity type.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(
            UIAlertAction(title: "Delete", style: .destructive) { [weak self, weak tag] _ in
                guard let tag else {
                    return
                }

                self?.deleteTag(tag)
            }
        )
        present(alertController, animated: true)
    }

    private func deleteTag(_ tag: ActivityTag) {
        guard let modelContext else {
            return
        }

        let tagID = tag.uniqueID
        tag.activityTypes.forEach { activityType in
            activityType.tags?.removeAll { $0.uniqueID == tagID }
        }
        selectedTagIDs.remove(tagID)
        onSelectionChange?(selectedTagIDs)
        modelContext.delete(tag)

        do {
            try modelContext.save()
            loadTags()
            onTagsChange?()
        } catch {
            assertionFailure("Unable to delete tag: \(error)")
            loadTags()
        }
    }

    private func toggleSelection(for tag: ActivityTag) {
        if selectedTagIDs.contains(tag.uniqueID) {
            selectedTagIDs.remove(tag.uniqueID)
        } else {
            selectedTagIDs.insert(tag.uniqueID)
        }

        if commitsSelectionImmediately {
            onSelectionChange?(selectedTagIDs)
        }
        updateCreateTagButton()
        collectionView.reloadData()
    }

    private func sortTagRows(_ lhs: TagRow, _ rhs: TagRow) -> Bool {
        if groupsSelectedTagsFirst {
            let lhsIsSelected = selectedTagIDs.contains(lhs.tag.uniqueID)
            let rhsIsSelected = selectedTagIDs.contains(rhs.tag.uniqueID)
            if lhsIsSelected != rhsIsSelected {
                return lhsIsSelected
            }
        }

        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    private func fetchExistingTagNames(excluding excludedTag: ActivityTag?) -> Set<String> {
        guard let modelContext else {
            return []
        }

        do {
            let tags = try modelContext.fetch(FetchDescriptor<ActivityTag>())
            return Set(
                tags
                    .filter { $0.uniqueID != excludedTag?.uniqueID }
                    .map { normalizeTagName($0.name) }
            )
        } catch {
            assertionFailure("Unable to fetch tag names: \(error)")
            return []
        }
    }

    private func isUniqueTagName(
        _ name: String?,
        existingNames: Set<String>
    ) -> Bool {
        let normalizedName = normalizeTagName(name)
        return !normalizedName.isEmpty
            && normalizedName.count <= Self.maximumTagNameLength
            && !existingNames.contains(normalizedName)
    }

    private func normalizeTagName(_ name: String?) -> String {
        name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedLowercase ?? ""
    }
}

extension TagsManagementViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        tagRows.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TagChipCell.reuseIdentifier,
            for: indexPath
        ) as? TagChipCell
        let row = tagRows[indexPath.item]
        cell?.configure(with: row, isSelected: selectedTagIDs.contains(row.tag.uniqueID))
        return cell ?? UICollectionViewCell()
    }
}

extension TagsManagementViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        toggleSelection(for: tagRows[indexPath.item].tag)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard allowsTagManagement else {
            return nil
        }

        let row = tagRows[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Rename") { [weak self] _ in
                    self?.presentRenameTagAlert(for: row.tag)
                },
                UIAction(title: "Delete", attributes: .destructive) { [weak self] _ in
                    self?.presentDeleteTagAlert(for: row.tag)
                }
            ])
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - 40
        return TagChipCell.fittingSize(
            for: tagRows[indexPath.item].name,
            maximumWidth: max(0, availableWidth)
        )
    }
}

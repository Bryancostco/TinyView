import UIKit    // uikit for text fields, switch, text view and stack views

// 10/31/26 screen 4, add or edit a book (nil id = add, real id = edit)
final class edit_book_view_controller: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    private let editing_book_id: UUID?                      // the book being edited, nil when adding
    private let scroll_view = UIScrollView()                // form scrolls when the keyboard is up
    private let form_stack = UIStackView()                  // every section of the form top to bottom
    private let cover_image_view = UIImageView()            // cover preview
    private let title_field = UITextField()                 // title input
    private let author_field = UITextField()                // author input
    private let collection_field = UITextField()            // series / volume input
    private let status_control = UISegmentedControl(items: reading_status.allCases.map { $0.display_name })    // Not started, Reading, On hold, Finished
    private let right_to_left_switch = UISwitch()           // manga mode toggle
    private let description_text_view = UITextView()        // multi line description
    private var working_book = book_item.make_new_book()    // the copy we edit, only goes into the store when Save is tapped
    private var save_item: UIBarButtonItem?                 // kept so we can turn it on and off

    init(book_id: UUID?) {                       // pass nil to add a new book
        editing_book_id = book_id                // remember which mode were in
        super.init(nibName: nil, bundle: nil)    // built in code, no storyboard
    }

    required init?(coder: NSCoder) {                                    // storyboard init, not used
        fatalError("edit_book_view_controller is made in code only")    // crash loudly if someone tries
    }

    override func viewDidLoad() {                                    // uikit calls this once when the screen loads
        super.viewDidLoad()                                          // let uikit do its thing first
        view.backgroundColor = app_theme.background_color            // warm background
        title = editing_book_id == nil ? "Add Book" : "Edit Book"    // title depends on the mode

        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })    // cancel throws away changes
        let save_button_item = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in self?.save_book() })    // save puts it in the store
        save_item = save_button_item                            // keep it so we can disable it
        navigationItem.rightBarButtonItem = save_button_item    // save on the right

        if let book_id = editing_book_id, let existing_book = book_store.shared.book(with: book_id) {    // edit mode and the book exists
            working_book = existing_book    // start from the real book
        }

        build_layout()         // make the views
        load_working_book()    // fill the fields
        update_save_state()    // save is off if the title is empty
    }

    // 10/31/26 cover on top, then details card, status, manga switch, description
    private func build_layout() {
        scroll_view.keyboardDismissMode = .interactive                   // drag down to hide the keyboard
        scroll_view.alwaysBounceVertical = true                          // natural bounce
        scroll_view.translatesAutoresizingMaskIntoConstraints = false    // pinned below
        view.addSubview(scroll_view)                                     // put it on screen

        form_stack.axis = .vertical                                     // sections top to bottom
        form_stack.spacing = 20                                         // gap between sections
        form_stack.isLayoutMarginsRelativeArrangement = true            // respect the padding below
        form_stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: app_theme.side_padding, bottom: 32, trailing: app_theme.side_padding)    // padding around the form
        form_stack.translatesAutoresizingMaskIntoConstraints = false    // pinned below
        scroll_view.addSubview(form_stack)                              // form lives in the scroll view

        NSLayoutConstraint.activate([                                                               // turn on constraints
            scroll_view.topAnchor.constraint(equalTo: view.topAnchor),                              // fill top
            scroll_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),                      // fill left
            scroll_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),                    // fill right
            scroll_view.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),       // stop at the keyboard so fields are never hidden behind it
            form_stack.topAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.topAnchor),     // form fills the scroll content
            form_stack.leadingAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.leadingAnchor),    // left
            form_stack.trailingAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.trailingAnchor),    // right
            form_stack.bottomAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.bottomAnchor),    // bottom
            form_stack.widthAnchor.constraint(equalTo: scroll_view.frameLayoutGuide.widthAnchor)    // no sideways scrolling
        ])

        form_stack.addArrangedSubview(make_cover_section())                                            // cover + change cover button
        form_stack.addArrangedSubview(make_section(title: "Details", content: make_details_card()))    // title, author, collection
        form_stack.addArrangedSubview(make_section(title: "Reading status", content: status_control))    // segmented control
        form_stack.addArrangedSubview(make_section(title: "Reading direction", content: make_direction_card()))    // manga switch
        form_stack.addArrangedSubview(make_section(title: "Description", content: make_description_card()))    // description box
    }

    // 10/31/26 cover preview centered with a change cover button under it
    private func make_cover_section() -> UIStackView {
        cover_image_view.contentMode = .scaleAspectFill                       // fill without stretching
        cover_image_view.clipsToBounds = true                                 // cut off overflow
        cover_image_view.layer.cornerRadius = 8                               // rounded corners
        cover_image_view.translatesAutoresizingMaskIntoConstraints = false    // fixed size below

        var change_configuration = UIButton.Configuration.plain()            // plain text button
        change_configuration.title = "Change cover"                          // button text
        change_configuration.baseForegroundColor = app_theme.accent_color    // orange
        let change_button = UIButton(configuration: change_configuration, primaryAction: UIAction { [weak self] _ in self?.show_cover_note() })    // tap explains its coming later

        let cover_stack = UIStackView(arrangedSubviews: [cover_image_view, change_button])    // cover then button
        cover_stack.axis = .vertical                                                          // top to bottom
        cover_stack.alignment = .center                                                       // centered on screen
        cover_stack.spacing = 6                                                               // small gap

        NSLayoutConstraint.activate([                                         // turn on constraints
            cover_image_view.widthAnchor.constraint(equalToConstant: 120),    // cover width
            cover_image_view.heightAnchor.constraint(equalToConstant: 170)    // cover height
        ])
        return cover_stack    // hand it back
    }

    // 10/31/26 white card with the 3 text field rows
    private func make_details_card() -> UIView {
        configure_field(title_field, placeholder: "Book title", return_key: .next)               // title field
        configure_field(author_field, placeholder: "Author or artist", return_key: .next)        // author field
        configure_field(collection_field, placeholder: "Series or volume", return_key: .done)    // collection field, last one so return = done
        title_field.addAction(UIAction { [weak self] _ in self?.handle_title_change() }, for: .editingChanged)    // live update the cover and save button as they type

        return make_card(rows: [                                                 // stack the rows with lines between them
            make_field_row(label_text: "Title", field: title_field),             // row 1
            make_separator(),                                                    // line
            make_field_row(label_text: "Author", field: author_field),           // row 2
            make_separator(),                                                    // line
            make_field_row(label_text: "Collection", field: collection_field)    // row 3
        ])
    }

    // 10/31/26 manga switch with a little explanation under the label
    private func make_direction_card() -> UIView {
        let label_text = app_theme.make_label("Right to left (manga)", size: 16)     // main label
        let detail_text = app_theme.make_label("Turn pages from right to left for this book", size: 13, color: app_theme.secondary_text_color, lines: 0)    // explanation, can wrap
        let text_stack = UIStackView(arrangedSubviews: [label_text, detail_text])    // label over explanation
        text_stack.axis = .vertical                                                  // top to bottom
        text_stack.spacing = 2                                                       // tight gap

        right_to_left_switch.onTintColor = app_theme.accent_color                      // orange when on
        right_to_left_switch.accessibilityLabel = "Right to left reading"              // voiceover label
        right_to_left_switch.setContentHuggingPriority(.required, for: .horizontal)    // switch stays its natural size

        let row_stack = UIStackView(arrangedSubviews: [text_stack, right_to_left_switch])    // text then switch
        row_stack.axis = .horizontal                                                         // side by side
        row_stack.alignment = .center                                                        // centered vertically
        row_stack.spacing = 12                                                               // gap between text and switch
        row_stack.isLayoutMarginsRelativeArrangement = true                                  // respect padding below
        row_stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)    // inner padding
        return make_card(rows: [row_stack])                                                  // wrap it in the white card
    }

    // 10/31/26 multi line description box
    private func make_description_card() -> UIView {
        description_text_view.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 16))    // normal body size
        description_text_view.adjustsFontForContentSizeCategory = true                                 // grows with text size setting
        description_text_view.textColor = app_theme.primary_text_color                                 // dark text
        description_text_view.backgroundColor = .clear                                                 // card behind it provides the white
        description_text_view.isScrollEnabled = false                                                  // grows taller as they type instead of scrolling inside itself
        description_text_view.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)    // inner padding
        description_text_view.accessibilityLabel = "Description"                                       // voiceover label
        description_text_view.translatesAutoresizingMaskIntoConstraints = false                        // min height below
        description_text_view.heightAnchor.constraint(greaterThanOrEqualToConstant: 110).isActive = true    // at least a few lines tall even when empty
        return make_card(rows: [description_text_view])                                                // wrap it in the white card
    }

    // 10/31/26 small helpers so the form code above stays short

    private func configure_field(_ field: UITextField, placeholder: String, return_key: UIReturnKeyType) {    // shared text field setup
        field.placeholder = placeholder                                                // gray hint text
        field.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 16))    // normal body size
        field.adjustsFontForContentSizeCategory = true                                 // grows with text size setting
        field.textColor = app_theme.primary_text_color                                 // dark text
        field.clearButtonMode = .whileEditing                                          // little x to clear while typing
        field.autocapitalizationType = .words                                          // capitalize each word, its mostly names
        field.returnKeyType = return_key                                               // next or done on the keyboard
        field.delegate = self                                                          // so we can handle the return key
    }

    private func make_field_row(label_text: String, field: UITextField) -> UIView {    // label on the left, text field on the right
        let row_label = app_theme.make_label(label_text, size: 15, color: app_theme.secondary_text_color)    // gray label
        row_label.translatesAutoresizingMaskIntoConstraints = false                    // fixed width below
        row_label.widthAnchor.constraint(equalToConstant: 90).isActive = true          // same width on every row so the fields line up
        field.accessibilityLabel = label_text                                          // voiceover says the label when the field is focused
        let row_stack = UIStackView(arrangedSubviews: [row_label, field])              // label then field
        row_stack.axis = .horizontal                                                   // side by side
        row_stack.alignment = .center                                                  // centered vertically
        row_stack.spacing = 12                                                         // gap
        row_stack.isLayoutMarginsRelativeArrangement = true                            // respect padding below
        row_stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)    // inner padding, makes rows about 47 tall like the figma
        return row_stack                                                               // hand it back
    }

    private func make_separator() -> UIView {                                    // thin line between rows
        let line_view = UIView()                                                 // the line
        line_view.backgroundColor = app_theme.border_color                       // light gray
        line_view.translatesAutoresizingMaskIntoConstraints = false              // fixed height below
        line_view.heightAnchor.constraint(equalToConstant: 1).isActive = true    // 1 point tall
        return line_view                                                         // hand it back
    }

    private func make_card(rows: [UIView]) -> UIView {                   // white rounded card that stacks whatever rows you give it
        let card_stack = UIStackView(arrangedSubviews: rows)             // the rows
        card_stack.axis = .vertical                                      // top to bottom
        card_stack.backgroundColor = app_theme.surface_color             // white
        card_stack.layer.cornerRadius = 12                               // rounded
        card_stack.layer.borderWidth = 1                                 // thin border
        card_stack.layer.borderColor = app_theme.border_color.cgColor    // light border
        card_stack.clipsToBounds = true                                  // rows respect the rounded corners
        return card_stack                                                // hand it back
    }

    private func make_section(title section_title: String, content: UIView) -> UIStackView {    // small caps heading above a section
        let heading_label = app_theme.make_label(section_title.uppercased(), size: 12, weight: .semibold, color: app_theme.secondary_text_color)    // gray caps heading
        let section_stack = UIStackView(arrangedSubviews: [heading_label, content])             // heading then content
        section_stack.axis = .vertical                                                          // top to bottom
        section_stack.spacing = 8                                                               // gap under the heading
        return section_stack                                                                    // hand it back
    }

    // 10/31/26 copy the book into the form
    private func load_working_book() {
        title_field.text = working_book.title                         // title
        author_field.text = working_book.author                       // author
        collection_field.text = working_book.collection               // collection
        status_control.selectedSegmentIndex = reading_status.allCases.firstIndex(of: working_book.status) ?? 0    // pick the matching segment
        right_to_left_switch.isOn = working_book.is_right_to_left     // manga switch
        description_text_view.text = working_book.description_text    // description
        refresh_cover()                                               // draw the cover
    }

    private func refresh_cover() {                                             // redraws the cover preview with whatever title is typed
        var preview_book = working_book                                        // copy so we dont touch the real one
        let typed_title = title_field.text ?? ""                               // whatever is in the field
        preview_book.title = typed_title.isEmpty ? "New Book" : typed_title    // placeholder title when empty
        cover_image_view.image = app_theme.make_cover_image(for: preview_book, size: CGSize(width: 240, height: 340))    // 2x size so its sharp
    }

    private func handle_title_change() {    // runs on every keystroke in the title field
        refresh_cover()                     // update the cover
        update_save_state()                 // maybe turn save on or off
    }

    private func update_save_state() {                                                                // a book needs at least a title
        let typed_title = (title_field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)    // ignore just spaces
        save_item?.isEnabled = !typed_title.isEmpty                                                   // save only works with a title
    }

    // 10/31/26 copy the form back into the book and save it to the store
    private func save_book() {
        let typed_title = (title_field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)      // cleaned up title
        guard !typed_title.isEmpty else { return }                                                      // no title, no save (button should already be off)
        let typed_author = (author_field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)    // cleaned up author

        working_book.title = typed_title                                                              // title
        working_book.author = typed_author.isEmpty ? "Unknown author" : typed_author                  // fallback so the list never shows a blank author
        working_book.collection = (collection_field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)    // collection
        working_book.status = reading_status.allCases[max(0, status_control.selectedSegmentIndex)]    // segment back to a status, max 0 just in case nothing is picked
        working_book.is_right_to_left = right_to_left_switch.isOn                                     // manga switch
        working_book.description_text = description_text_view.text                                    // description
        book_store.shared.save(working_book)                                                          // put it in the store, other screens refresh from the notification
        dismiss(animated: true)                                                                       // close the sheet
    }

    private func show_cover_note() {                                    // change cover button
        let alert = UIAlertController(title: "Change cover", message: "Picking a cover from Files is coming in Milestone 3. For now the cover is drawn from the title.", preferredStyle: .alert)    // quick explanation
        alert.addAction(UIAlertAction(title: "OK", style: .default))    // close button
        present(alert, animated: true)                                  // show it
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {    // UITextFieldDelegate, return key got tapped
        if textField == title_field {                                 // on title
            author_field.becomeFirstResponder()                       // jump to author
        } else if textField == author_field {                         // on author
            collection_field.becomeFirstResponder()                   // jump to collection
        } else {                                                      // on collection, the last field
            textField.resignFirstResponder()                          // hide the keyboard
        }
        return true    // let uikit finish handling the key
    }
}

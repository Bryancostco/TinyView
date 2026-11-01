import UIKit    // uikit for the table cell, labels and stack views

// 10/31/26 custom row for the library table (cover on the left, info on the right)
final class book_cell: UITableViewCell {
    static let reuse_identifier = "book_cell"    // name the table uses to recycle these cells

    private let cover_image_view = UIImageView()                                                      // small cover
    private let title_label = app_theme.make_label(size: 17, weight: .semibold)                       // book title
    private let meta_label = app_theme.make_label(size: 13, color: app_theme.secondary_text_color)    // author + format
    private let status_container = UIStackView()                                                      // holds the dot + status, swapped out per book
    private let progress_bar = UIProgressView(progressViewStyle: .default)                            // reading progress
    private let percent_label = app_theme.make_label(size: 12, color: app_theme.secondary_text_color)    // 30% etc

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {    // uikit calls this when it makes a new cell
        super.init(style: style, reuseIdentifier: reuseIdentifier)                 // let uikit do its setup first
        build_layout()                                                             // then build our views
    }

    required init?(coder: NSCoder) {                    // only used by storyboards, which we arent using
        fatalError("book_cell is made in code only")    // crash loudly if someone tries
    }

    // 10/31/26 builds the row with stack views + auto layout
    private func build_layout() {
        accessoryType = .disclosureIndicator         // the > on the right so people know they can tap it
        backgroundColor = app_theme.surface_color    // white row

        cover_image_view.contentMode = .scaleAspectFill                       // fill the frame without stretching
        cover_image_view.clipsToBounds = true                                 // cut off whatever goes past the edges
        cover_image_view.layer.cornerRadius = 5                               // little rounded corners
        cover_image_view.translatesAutoresizingMaskIntoConstraints = false    // size comes from constraints below

        title_label.numberOfLines = 2                                           // long titles can wrap once
        progress_bar.trackTintColor = app_theme.border_color                    // empty part of the bar
        percent_label.font = UIFontMetrics.default.scaledFont(for: .monospacedDigitSystemFont(ofSize: 12, weight: .regular))    // every digit same width so numbers dont wiggle
        percent_label.setContentHuggingPriority(.required, for: .horizontal)    // keep the % tight so the bar gets the rest of the room

        status_container.axis = .horizontal                                                // just one row
        let progress_row = UIStackView(arrangedSubviews: [progress_bar, percent_label])    // bar then %
        progress_row.axis = .horizontal                                                    // side by side
        progress_row.spacing = 10                                                          // gap between bar and %
        progress_row.alignment = .center                                                   // center the skinny bar with the text

        let text_stack = UIStackView(arrangedSubviews: [title_label, meta_label, status_container, progress_row])    // right side of the row
        text_stack.axis = .vertical                                // top to bottom
        text_stack.spacing = 4                                     // tight gap between lines
        text_stack.setCustomSpacing(8, after: status_container)    // little extra room before the bar

        let row_stack = UIStackView(arrangedSubviews: [cover_image_view, text_stack])    // cover then text
        row_stack.axis = .horizontal                                                     // side by side
        row_stack.spacing = 14                                                           // gap between cover and text
        row_stack.alignment = .center                                                    // cover sits in the middle vertically
        row_stack.translatesAutoresizingMaskIntoConstraints = false                      // pinned with constraints below
        contentView.addSubview(row_stack)                                                // always add to contentView, not the cell itself

        let bottom_constraint = row_stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)    // bottom padding
        bottom_constraint.priority = .defaultHigh                                                      // slightly lower priority so it doesnt fight the table while it sizes rows
        NSLayoutConstraint.activate([                                                                  // turn on all the constraints
            cover_image_view.widthAnchor.constraint(equalToConstant: 52),                              // cover width
            cover_image_view.heightAnchor.constraint(equalToConstant: 74),                             // cover height (book shaped)
            row_stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),              // top padding
            row_stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),      // left padding
            row_stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),    // right padding before the >
            bottom_constraint                                                                          // bottom padding from above
        ])
    }

    // 10/31/26 fills the row with one books info, gets called every time a row scrolls on screen
    func configure(with item: book_item) {
        cover_image_view.image = app_theme.make_cover_image(for: item, size: CGSize(width: 104, height: 148))    // draw at 2x so its sharp
        title_label.text = item.title                                                       // title
        meta_label.text = item.meta_text                                                    // author + format
        status_container.arrangedSubviews.forEach { $0.removeFromSuperview() }              // clear the old status, cells get recycled
        status_container.addArrangedSubview(app_theme.make_status_row(for: item.status))    // add this books status
        progress_bar.progress = item.progress                                               // fill the bar
        progress_bar.progressTintColor = item.status.tint_color                             // bar color matches the status
        percent_label.text = item.percent_text                                              // the %
        accessibilityLabel = "\(item.title), \(item.author), \(item.status.display_name), \(item.percent_text) read"    // what voiceover reads out loud
    }
}

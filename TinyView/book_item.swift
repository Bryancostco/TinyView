import UIKit    // need UIColor for the cover colors

// 10/31/26 every state a book can be in
enum reading_status: CaseIterable {    // CaseIterable lets us loop over every case (used for the segmented control)
    case not_started                   // imported but never opened
    case reading                       // currently reading it
    case on_hold                       // paused for now
    case finished                      // read the whole thing

    var display_name: String {                     // the word we show on screen
        switch self {                              // pick based on which case this is
        case .not_started: return "Not started"    // never opened
        case .reading: return "Reading"            // in progress
        case .on_hold: return "On hold"            // paused
        case .finished: return "Finished"          // done
        }
    }

    var tint_color: UIColor {                                       // color for the dot and progress bar
        switch self {                                               // pick based on which case this is
        case .not_started: return app_theme.secondary_text_color    // plain gray, nothing happened yet
        case .reading: return app_theme.accent_color                // terracotta for active
        case .on_hold: return app_theme.on_hold_color               // warm gray for paused
        case .finished: return app_theme.finished_color             // green for done
        }
    }
}

// 10/31/26 file types the reader supports
enum file_format: String {    // String raw value so we can print it straight to a label
    case cbz = "CBZ"          // zipped comic file
    case pdf = "PDF"          // normal pdf
}

// 10/31/26 one book in the library (struct = gets copied, so editing a copy wont mess up the store)
struct book_item {
    let id: UUID                    // unique id so we can find the book again after edits
    var title: String               // book title
    var author: String              // author or artist
    var collection: String          // series or volume
    var format: file_format         // cbz or pdf
    var status: reading_status      // where the reader is at with it
    var current_page: Int           // last page they were on
    var total_pages: Int            // how many pages the file has
    var is_right_to_left: Bool      // true for manga
    var description_text: String    // short summary for the edit screen
    var cover_color: UIColor        // base color for the fake cover
    var last_opened: Date           // used for the recently opened sort

    var progress: Float {                                  // how much of the book is read, 0 to 1
        guard total_pages > 0 else { return 0 }            // dont divide by zero
        return Float(current_page) / Float(total_pages)    // pages read / total pages
    }

    var percent_text: String {                   // progress as text like 30%
        "\(Int((progress * 100).rounded()))%"    // round to a whole number
    }

    var meta_text: String {                 // author + format line for the table
        "\(author) · \(format.rawValue)"    // ex: Nora Ellis · CBZ
    }

    // 10/31/26 blank book for the add screen to fill in
    static func make_new_book() -> book_item {
        book_item(                                                                 // build it with default values
            id: UUID(),                                                            // brand new id
            title: "",                                                             // user fills this in
            author: "",                                                            // user fills this in
            collection: "",                                                        // user fills this in
            format: .pdf,                                                          // default until real file import exists
            status: .not_started,                                                  // new books start unread
            current_page: 0,                                                       // nothing read yet
            total_pages: 120,                                                      // fake page count for the milestone
            is_right_to_left: false,                                               // left to right by default
            description_text: "",                                                  // user fills this in
            cover_color: UIColor(red: 0.45, green: 0.40, blue: 0.36, alpha: 1),    // neutral brown cover
            last_opened: Date()                                                    // counts as just added
        )
    }
}

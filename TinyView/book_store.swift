import UIKit    // need UIColor for the sample data

extension Notification.Name {                                                        // custom notification names live here
    static let book_store_did_change = Notification.Name("book_store_did_change")    // fired any time books get added, edited or deleted
}

// 10/31/26 holds all the books in memory for milestone 1 (no saving to disk yet, thats milestone 3)
final class book_store {
    static let shared = book_store()       // one store the whole app shares (singleton)
    private(set) var books: [book_item]    // every book, other files can read it but only the store can change it

    private init() {                              // private so nobody makes a second store by accident
        books = book_store.make_sample_books()    // start with the hard coded sample books
    }

    var continue_reading_book: book_item? {             // the book on the home screen card
        books.filter { $0.status == .reading }          // only books being read
            .max { $0.last_opened < $1.last_opened }    // grab the one opened most recently
    }

    func count(for status: reading_status) -> Int {    // how many books are in a status
        books.filter { $0.status == status }.count     // filter then count
    }

    func book(with book_id: UUID) -> book_item? {    // find one book by id
        books.first { $0.id == book_id }             // nil if it doesnt exist
    }

    // 10/31/26 adds a new book or overwrites an existing one
    func save(_ item: book_item) {
        if let index = books.firstIndex(where: { $0.id == item.id }) {    // already in the library
            books[index] = item                                           // swap in the edited copy
        } else {                                                          // new book
            books.insert(item, at: 0)                                     // put it at the top
        }
        NotificationCenter.default.post(name: .book_store_did_change, object: nil)    // tell the screens to refresh
    }

    // 10/31/26 removes a book (from swipe or edit mode delete)
    func delete(book_id: UUID) {
        books.removeAll { $0.id == book_id }                                          // drop it
        NotificationCenter.default.post(name: .book_store_did_change, object: nil)    // tell the screens to refresh
    }

    // 10/31/26 sample books, same titles as the figma
    private static func make_sample_books() -> [book_item] {
        let now = Date()                 // right now, used to fake last opened times
        let hour: TimeInterval = 3600    // 1 hour in seconds
        return [                         // the 7 books
            book_item(id: UUID(), title: "The Last Light", author: "Nora Ellis", collection: "Volume 1", format: .cbz, status: .reading, current_page: 48, total_pages: 160, is_right_to_left: false, description_text: "A lighthouse keeper's daughter returns to the island the night the light comes back on.", cover_color: UIColor(red: 0.33, green: 0.37, blue: 0.45, alpha: 1), last_opened: now.addingTimeInterval(-1 * hour)),    // continue reading book (opened most recently)
            book_item(id: UUID(), title: "Orbit, Alone", author: "Jules Moreno", collection: "Volume 2", format: .cbz, status: .reading, current_page: 124, total_pages: 200, is_right_to_left: false, description_text: "The last astronaut on a quiet station counts the days until a reply.", cover_color: UIColor(red: 0.55, green: 0.30, blue: 0.22, alpha: 1), last_opened: now.addingTimeInterval(-2 * hour)),    // reading, 62%
            book_item(id: UUID(), title: "The Quiet Garden", author: "Aki Tanaka", collection: "Volume 1", format: .cbz, status: .reading, current_page: 18, total_pages: 100, is_right_to_left: true, description_text: "Two neighbors share a garden and slowly learn each other's stories.", cover_color: UIColor(red: 0.36, green: 0.42, blue: 0.33, alpha: 1), last_opened: now.addingTimeInterval(-3 * hour)),    // manga so its right to left
            book_item(id: UUID(), title: "After the Rain", author: "Mika Sato", collection: "Collected Edition", format: .pdf, status: .on_hold, current_page: 53, total_pages: 120, is_right_to_left: true, description_text: "A city waits for the storm to pass and a detective waits for a confession.", cover_color: UIColor(red: 0.42, green: 0.36, blue: 0.55, alpha: 1), last_opened: now.addingTimeInterval(-4 * hour)),    // on hold
            book_item(id: UUID(), title: "Wildwood", author: "Rowan Blake", collection: "Volume 1", format: .cbz, status: .finished, current_page: 96, total_pages: 96, is_right_to_left: false, description_text: "A girl follows a fox into the forest behind her grandmother's house.", cover_color: UIColor(red: 0.24, green: 0.33, blue: 0.24, alpha: 1), last_opened: now.addingTimeInterval(-5 * hour)),    // finished
            book_item(id: UUID(), title: "Blue Hours", author: "Léa Martin", collection: "Stories", format: .pdf, status: .finished, current_page: 140, total_pages: 140, is_right_to_left: false, description_text: "Short stories set in the hour between sunset and night.", cover_color: UIColor(red: 0.20, green: 0.30, blue: 0.48, alpha: 1), last_opened: now.addingTimeInterval(-6 * hour)),    // finished
            book_item(id: UUID(), title: "Paper Planets", author: "Theo Park", collection: "Volume 1", format: .pdf, status: .not_started, current_page: 0, total_pages: 88, is_right_to_left: false, description_text: "A kid builds a solar system out of paper and one of the planets wakes up.", cover_color: UIColor(red: 0.62, green: 0.50, blue: 0.30, alpha: 1), last_opened: .distantPast)    // never opened so it sorts last
        ]
    }
}

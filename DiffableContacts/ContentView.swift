// 1. struct DiffableContainer: UIViewControllerRepresentable
// 2. class DiffableTableViewController: UITableViewController
// 3.  private func setupSource() {
// 4. let source: UITableViewDiffableDataSource<SectionType, Contact> = .init(
// enum SectionType, struct Contact created for generic labels needed
// 5. create UITableViewCell()
// 6.  var snapshot = source.snapshot()
// 7. UITableViewCell class

import SwiftUI
import UIKit

enum SectionType: Hashable {
    case ceo
    case peasants
}

struct Contact: Hashable {
    let id: UUID = UUID()
    let name: String
    var isFavorite = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }
}


class ContactViewModel: ObservableObject {
    @Published var name = ""
    @Published var isFavorite = false
}

struct ContactRowView: View {
    @ObservedObject var viewModel: ContactViewModel
    
    var name = "Test123"
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
            Text(viewModel.name)
            Spacer()
            Image(systemName:
                viewModel.isFavorite ?
                    "star.fill" : "star")
        }.padding(20)
    }
}

class ContactCell: UITableViewCell {
    
    let viewModel = ContactViewModel()
    lazy var row = ContactRowView(viewModel: viewModel)
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        backgroundColor = .red
        //setup my SwiftUI view somehow
        let hostingController = UIHostingController(rootView: row)
        addSubview(hostingController.view)
        hostingController.view.fillSuperview()
        
        viewModel.name = "something new"
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactsSource: UITableViewDiffableDataSource<SectionType, Contact> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
}

class DiffableTableViewController: UITableViewController {
    
    //UITableViewDiffableDataSource
    let viewModel = ContactViewModel()
    
    lazy var source: ContactsSource = .init(
    tableView: self.tableView) { (_, indexPath, contact)
        -> UITableViewCell? in
        
        let cell = ContactCell(style: .default, reuseIdentifier: nil)
        cell.viewModel.name = contact.name
        cell.viewModel.isFavorite = self.viewModel.isFavorite
//        cell.textLabel?.text = contact.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete") { (action, view, completion) in
                completion(true)
                var snapshot = self.source.snapshot()
                //what contact do we need to delete?
                guard let contact = self.source.itemIdentifier(for: indexPath) else { return }
                snapshot.deleteItems([contact])
                self.source.apply(snapshot, animatingDifferences: true)
        }
        
        let favoriteAction = UIContextualAction(
            style: .normal,
            title: "Favorite") { (_, _, completion) in
                
                completion(true)
                
                var snapshot = self.source.snapshot()
                
                guard var contact = self.source.itemIdentifier(for: indexPath) else { return }
                
                self.viewModel.isFavorite.toggle()
                contact.isFavorite.toggle()
                
                snapshot.reloadItems([contact])
                
                self.source.apply(
                    snapshot,
                    animatingDifferences: true
                )
                
                
        }
        
        return .init(actions: [deleteAction, favoriteAction])
    }
    
    private func setupSource() {
        
        var snapshot = source.snapshot()
        snapshot.appendSections([.ceo, .peasants])
        snapshot.appendItems([
            .init(name: "Elon Musk"),
            .init(name: "Tim Cook"),
            .init(name: "Steve Jobs")
        ], toSection: .ceo)
        
        snapshot.appendItems([
            .init(name: "Bill Gates")
            ], toSection: .peasants)
        source.apply(snapshot)
    }
    
    func reloadSnapshot(section: SectionType, entries: [Contact], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionType, Contact>()
        snapshot.appendSections([section])
        snapshot.appendItems(entries)
        source.apply(snapshot, animatingDifferences: animated)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = section == 0 ? "CEO" : "Peasants"
        return label
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Contacts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = .init(title: "Add Contact", style: .plain, target: self, action: #selector(handleAdd))
        
        setupSource()
    }
    
    @objc private func handleAdd() {
        let formView = ContactFormView { (name, sectionType) in
            print("add contact")
            var snapshot = self.source.snapshot()
            snapshot.appendItems([.init(name: name)], toSection: sectionType)
            self.source.apply(snapshot)
            self.dismiss(animated: true)
        }
        let hostingController = UIHostingController(rootView: formView)
        present(hostingController, animated: true)
        
        
    }
}

struct ContactFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var sectionType = SectionType.ceo
    
    var didAddContact: (String, SectionType) -> () = { _,_ in }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $name)
            
            Picker(selection: $sectionType,
                   label: Text("ABC")) {
                    Text("CEO").tag(SectionType.ceo)
                    Text("Peasants").tag(SectionType.peasants)
            }.pickerStyle(SegmentedPickerStyle())
            
            Button(action: {
                //run a function/closure
                self.didAddContact(self.name, self.sectionType)
            }, label: {
                HStack {
                    Spacer()
                    Text("Add").foregroundColor(Color(.white))
                    Spacer()
                }.padding().background(Color(.systemBlue)).cornerRadius(5)
            })
            Button(action:dismiss) {
                HStack {
                    Spacer()
                    Text("Cancel").foregroundColor(Color(.white))
                    Spacer()
                }.padding().background(Color(.systemPink)).cornerRadius(5)
            }
            Spacer()
        }.padding()
    }
    func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ContactForm_Previews: PreviewProvider {
    static var previews: some View {
        ContactFormView()
    }
}



struct DiffableContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UINavigationController(rootViewController: DiffableTableViewController(style: .insetGrouped))
        //UITableViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = UIViewController
}


struct DiffableContainer_Previews: PreviewProvider {
    static var previews: some View {
        DiffableContainer()
           // .edgesIgnoringSafeArea(.all)
    }
}

//struct ContentView: View {
//    var body: some View {
//        Text("Hello, World!")
//    }
//}


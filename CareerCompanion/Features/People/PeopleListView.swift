import SwiftUI

/// List view showing all people grouped by relationship type
struct PeopleListView: View {
    @State private var allPeople: [Manager] = []
    @State private var isLoading = false
    @State private var showingAddPerson = false

    // Filtered lists by relationship type
    private var myManagers: [Manager] {
        allPeople.filter { $0.isMyManager }
    }

    private var directReports: [Manager] {
        allPeople.filter { $0.isDirectReport }
    }

    private var otherPeople: [Manager] {
        allPeople.filter { $0.isOtherRelationship }
    }

    var body: some View {
        List {
            if allPeople.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No People",
                    systemImage: "person.badge.plus",
                    description: Text("Tap + to add someone you have 1:1s with.")
                )
            } else {
                // My Managers Section
                if !myManagers.isEmpty {
                    Section("My Managers") {
                        ForEach(myManagers) { person in
                            PersonRow(person: person)
                        }
                        .onDelete { offsets in
                            deletePeople(offsets, from: myManagers)
                        }
                    }
                }

                // Direct Reports Section
                if !directReports.isEmpty {
                    Section("Direct Reports") {
                        ForEach(directReports) { person in
                            PersonRow(person: person)
                        }
                        .onDelete { offsets in
                            deletePeople(offsets, from: directReports)
                        }
                    }
                }

                // Other People Section
                if !otherPeople.isEmpty {
                    Section("Other 1:1s") {
                        ForEach(otherPeople) { person in
                            PersonRow(person: person, showRelationshipType: true)
                        }
                        .onDelete { offsets in
                            deletePeople(offsets, from: otherPeople)
                        }
                    }
                }
            }
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPerson = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonView { newPerson in
                // Add the new person to the list
                allPeople.append(newPerson)
            }
        }
        .task {
            await loadPeople()
        }
        .refreshable {
            await loadPeople()
        }
    }

    private func loadPeople() async {
        isLoading = true

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            allPeople = DemoDataProvider.managers
            isLoading = false
            return
        }

        do {
            allPeople = try await CloudKitManager.shared.fetch()
        } catch {}
        isLoading = false
    }

    private func deletePeople(_ offsets: IndexSet, from list: [Manager]) {
        let peopleToDelete = offsets.map { list[$0] }

        Task {
            for person in peopleToDelete {
                // In demo mode, only update in-memory
                if AppSettings.shared.isDemoMode {
                    allPeople.removeAll { $0.id == person.id }
                    continue
                }

                try? await CloudKitManager.shared.delete(person)
                allPeople.removeAll { $0.id == person.id }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PeopleListView()
    }
}

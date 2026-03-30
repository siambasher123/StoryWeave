import SwiftUI

struct ProfileView: View {
    @StateObject var vm = ProfileViewModel()
    @EnvironmentObject var session: AppSession

    var body: some View {
        List {
            Section {
                Text("Profile")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
            }

            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.12))
                            .frame(width: 60, height: 60)
                        Text(initial)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.indigo)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signed in as")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(session.email)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Reading Stats") {
                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    StatRow(
                        icon: "book.fill", color: .indigo,
                        label: "Stories Started", value: "\(vm.storiesStarted)")
                    StatRow(
                        icon: "checkmark.seal.fill", color: .green,
                        label: "Stories Completed", value: "\(vm.storiesCompleted)")
                    StatRow(
                        icon: "chart.bar.fill", color: .orange,
                        label: "Completion Rate", value: completionRate)
                }
            }

            Section("Account") {
                Button(role: .destructive) {
                    vm.logout(session: session)
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.loadSessions(userId: session.userId ?? "")
        }
    }

    private var initial: String {
        String(session.email.prefix(1)).uppercased()
    }

    private var completionRate: String {
        guard vm.storiesStarted > 0 else { return "0%" }
        let rate = Int((Double(vm.storiesCompleted) / Double(vm.storiesStarted)) * 100)
        return "\(rate)%"
    }
}

struct StatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

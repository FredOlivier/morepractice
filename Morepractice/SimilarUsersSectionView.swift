// SimilarUsersSectionView.swift

import SwiftUI

struct SimilarUsersSectionView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Similar Users")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                if scoreManager.similarUsers.isEmpty {
                    Text("No similar users found.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(scoreManager.similarUsers) { user in
                        HStack {
                            // Replace with your user image if available
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "%.2f", user.similarityScore))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()
            .navigationBarTitle("Similar Users", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SimilarUsersSectionView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        scoreMgr.similarUsers = [
         
           
        ]
        return SimilarUsersSectionView()
            .environmentObject(scoreMgr)
    }
}

//
//  ContentView.swift
//  ExampleApplicationQueueMusicPlayer
//
//  Created by Jake Nelson on 26/6/21.
//

import SwiftUI

import MediaPlayer

struct ContentView: View {
    
    @State var musicLibraryAccess: Bool = false
    
    let musicPlayer = MPMusicPlayerApplicationController.applicationQueuePlayer
    
    let musicLibrary = MPMediaLibrary()
    
    @State var songs: [MPMediaItem] = [MPMediaItem]()
    
    var body: some View {
        NavigationView {
            VStack{
                Button(action: {
                    shuffleSongs()
                }){
                    Text("Shuffle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .controlProminence(.increased)
                
                List{
                    ForEach(songs, id: \.persistentID){
                        song in
                        Text(song.title ?? "No title")
                    }
                }
            }
            .navigationTitle("Songs")
        }
        .listStyle(.plain)
        .task {
            checkForMusicLibraryAccess()
            getSongsFromLibrary()
        }
    }
    
    func shuffleSongs(){
        let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: songs))
        musicPlayer.setQueue(with: queueDescriptor)
        musicPlayer.shuffleMode = .songs
        musicPlayer.play()
        
        
        musicPlayer.perform(queueTransaction: {
            playerqueue in
            print("in queue transaction")
        }, completionHandler: {
            playerqueue, error in
            detach {
                print("in queue completed")
                await setSongs(playerqueue.items)
                print("songs set completed")
                if error != nil {
                    print(error?.localizedDescription ?? "")
                }
            }
        })
    }
    
    func getSongsFromLibrary() {
        detach {
            var results: [MPMediaItem] = []
            if self.musicLibraryAccess {
                let query = MPMediaQuery.songs()
                guard let result = query.items else {
                    return
                }
                results = result
            }
            await setSongs(results)
        }
    }
    
    @MainActor
    func setSongs(_ items: [MPMediaItem]){
        songs = items
    }
    
    func checkForMusicLibraryAccess() {
        
        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .authorized:
            musicLibraryAccess = true
        case .notDetermined:
            
            MPMediaLibrary.requestAuthorization()
            { status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.musicLibraryAccess = true
                    }
                }
            }
        case .restricted:
            // do nothing
            musicLibraryAccess = false
        case .denied:
            musicLibraryAccess = false
        @unknown default: fatalError()
        }
    }
}

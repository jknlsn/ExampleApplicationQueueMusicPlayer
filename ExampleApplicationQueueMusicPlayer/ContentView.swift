//
//  ContentView.swift
//  ExampleApplicationQueueMusicPlayer
//
//  Created by Jake Nelson on 26/6/21.
//

import SwiftUI

import MusicKit
import MediaPlayer

struct ContentView: View {
    
    var body: some View {
        TabView{
            SongsView(10)
                .tabItem {
                    Image(systemName: "bolt")
                    Text("100")
                }
            
            SongsView(100)
                .tabItem {
                    Image(systemName: "hare")
                    Text("100")
                }
            
            SongsView(10000)
                .tabItem {
                    Image(systemName: "tortoise")
                    Text("10000")
                }
            
            SongsView(100, useMusicKitPlayerQueue: true)
                .tabItem {
                    Image(systemName: "hare")
                    Text("100 MK")
                }
            
            SongsView(10000, useMusicKitPlayerQueue: true)
                .tabItem {
                    Image(systemName: "tortoise")
                    Text("10000 MK")
                }
        }
    }
}

struct SongsView: View {
    
    @State var musicLibraryAccess: Bool = false
    
    let musicKitMusicPlayer = ApplicationMusicPlayer.shared
    
    let musicPlayer = MPMusicPlayerApplicationController.applicationQueuePlayer
    
    let musicLibrary = MPMediaLibrary()
    
    var useMusicKitPlayerQueue = false
    
    @State var songs: [MPMediaItem] = [MPMediaItem]()
    
    let count: Int
    
    init(_ count: Int, useMusicKitPlayerQueue: Bool = false){
        self.count = count
        self.useMusicKitPlayerQueue = useMusicKitPlayerQueue
    }
    
    var body: some View {
        NavigationView {
            VStack{
                Button(action: {
                    if useMusicKitPlayerQueue {
                        shuffleSongsGetFromMusicKitMusicPlayer()
                    }
                    else {
                        shuffleSongsGetFromQueueTransaction()
                    }
                }){
                    Text("Shuffle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                List{
                    ForEach(songs, id: \.persistentID){
                        song in
                        Text(song.title ?? "No title")
                            .foregroundColor(song.title == musicPlayer.nowPlayingItem?.title ? .orange : .primary)
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
    
    func shuffleSongsGetFromQueueTransaction(){
        let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: songs))
        musicPlayer.setQueue(with: queueDescriptor)
        
        print(songs.map{$0.title})
        
        musicPlayer.shuffleMode = .songs
        musicPlayer.play()
        
        print(musicKitMusicPlayer.queue.entries.map{$0.title})
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            print(musicKitMusicPlayer.queue.entries.map{$0.title})
        })
        
        musicPlayer.perform(queueTransaction: {
            playerqueue in
            print("in queue transaction")
        }, completionHandler: {
            playerqueue, error in
            Task.detached {
                print("in queue completed")
                await setSongs(playerqueue.items)
                print("songs set completed")
                if error != nil {
                    print(error?.localizedDescription ?? "")
                }
            }
        })
    }
    
    func shuffleSongsGetFromMusicKitMusicPlayer(){
        let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: songs))
        musicPlayer.setQueue(with: queueDescriptor)
        
        print(songs.map{$0.title})
        
        musicPlayer.shuffleMode = .songs
        musicPlayer.play()
        
        print(musicKitMusicPlayer.queue.entries.map{$0.title})
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            print(musicKitMusicPlayer.queue.entries.map{$0.title})
            // TODO: exercise for the reader is now reordering by ID to reflect shuffle!
        })
    }
    
    func getSongsFromLibrary() {
        Task.detached {
            var results: [MPMediaItem] = []
            if self.musicLibraryAccess {
                let query = MPMediaQuery.songs()
                guard let result = query.items else {
                    return
                }
                results = result
            }
            await setSongs(Array(results.prefix(count)))
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

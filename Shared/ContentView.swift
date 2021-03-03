//
//  ContentView.swift
//  Shared
//
//  Created by Ricardo Chavarria on 02/26/21.
//

import SwiftUI
import AVKit
import CoreImage
import QuickLookThumbnailing

struct ContentView: View {
    @State var currentPath = ""
    @State var baseURLs = [URL]()
    @State var thumbnails = [URL: NSImage]()
    @State var thumbnailSize = CGSize(width: 500, height: 500)
    @State var selectedURLs = [URL:URL]()
    
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 1)

    func readFiles(path: URL) -> [URL] {
        let contents = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        return contents ?? []
    }
    
    func generateThumbnailRepresentations(for url: URL, size: CGSize, completion completionHandler: @escaping (QLThumbnailRepresentation?, Error?) -> Void) {
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: NSScreen.main!.backingScaleFactor, representationTypes: .all)
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request, completion: completionHandler)
    }
    
    var body: some View {
        
        VStack {
            HStack {
                TextField("Path", text: $currentPath)
                Button(action: {
                    let dialog = NSOpenPanel()
                    dialog.title = "Choose the folder to check"
                    dialog.showsResizeIndicator = true
                    dialog.showsHiddenFiles = false
                    dialog.allowsMultipleSelection = false
                    dialog.canChooseFiles = false
                    dialog.canChooseDirectories = true
                    
                    if dialog.runModal() == NSApplication.ModalResponse.OK {
                        if let result = dialog.url {
                            currentPath = result.path
                            baseURLs = readFiles(path: result)
                            
                            baseURLs.forEach { (url) in
                                generateThumbnailRepresentations(for: url, size: thumbnailSize) { (representation, error) in
                                    if let image = representation, error == nil && thumbnails[url] == nil {
                                        thumbnails[url] = image.nsImage
                                    }
                                }
                            }
                        }
                    }
                }, label: {
                    Text("Choose Folder")
                })
            }
            Spacer()
            HStack {
                VStack {
                    Text("Files and Folders")
                    List(baseURLs, id: \.path, selection: $selectedURLs) { url in
                        Text(url.path)
                    }
                    .listRowBackground(Color.blue)
                    .listStyle(SidebarListStyle())
                }
                VStack {
                    Text("Previews")
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(baseURLs, id: \.path) { url in
                                VStack {
                                    if let image = thumbnails[url] {
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    }
                                    
                                    if url.isDirectory {
                                        Text(url.path)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension URL {
    var isDirectory: Bool {
       return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

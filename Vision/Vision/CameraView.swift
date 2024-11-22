//
//  CameraView.swift
//  Vision
//
//  Created by Maggie Lam on 11/21/24.
//

import SwiftUI
import AVFoundation
import Photos

struct CameraView : View {
    @StateObject private var camera = Camera()
    let cornerRadius: CGFloat = 25
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let capturedPhoto = camera.capturedPhoto {
                    Image(uiImage: capturedPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                } else if camera.isPreviewReady {
                    CameraPreview(camera: camera)
                } else {
                    Text("Loading...")
                        .foregroundColor(.white)
                }
                
                VStack {
                    Spacer()
                    
                    if camera.isTaken{
                        ZStack {
                            HStack {
                                Button(action: camera.retakePic, label: {
                                    Image(systemName: "arrowshape.turn.up.backward")
                                        .foregroundStyle(.black)
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(Circle())
                                })
                                Spacer() }
                            
                            HStack {
                                Text(camera.caption)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.black)
                                    .background(.white)
                                    .frame(width: 250)
                            }
                        }
                    } else {
                        ZStack {
                            Button(action:camera.takePic, label: {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 50, height:50)
                            })
                        }
                    }
                    
                }
                
            }
            .onAppear(){
                camera.check()
            }
        }
    }

    
    struct CameraPreview: UIViewRepresentable {
        @ObservedObject var camera: Camera
        
        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            
            if let previewLayer = camera.preview {
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
            } else {
                
            }
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            DispatchQueue.main.async {
                if let previewLayer = self.camera.preview {
                    previewLayer.frame = uiView.bounds
                } else {
                    
                }
            }
        }
    }
}


#Preview {
    CameraView()
}

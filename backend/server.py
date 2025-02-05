import cv2
import numpy as np
import ffmpeg

def detect_video_markers(video_path):
    cap = cv2.VideoCapture(video_path)
    
    frame_diffs = []
    prev_frame = None
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        if prev_frame is not None:
            diff = cv2.absdiff(prev_frame, gray)
            frame_diffs.append(np.mean(diff))
        
        prev_frame = gray
    
    cap.release()
    
    start_frame = np.argmax(frame_diffs[:len(frame_diffs)//2])
    end_frame = np.argmax(frame_diffs[len(frame_diffs)//2:]) + len(frame_diffs)//2
    
    return start_frame, end_frame

def trim_video(input_path, output_path, start_frame, end_frame, fps=30):
    start_time = start_frame / fps
    end_time = end_frame / fps
    
    ffmpeg.input(input_path).trim(start=start_time, end=end_time).output(output_path).run()
    print(f"Video gespeichert: {output_path}")

if _name_ == "_main_":
    video_path = "input.mp4"
    output_path = "output.mp4"
    start, end = detect_video_markers(video_path)
    trim_video(video_path, output_path, start, end)
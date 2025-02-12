from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import cv2
import numpy as np
import ffmpeg
import os
from werkzeug.serving import run_simple
import traceback

app = Flask(__name__)

# Configure maximum file size (100 MB)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100 MB
app.config['UPLOAD_FOLDER'] = './uploads'
app.config['OUTPUT_FOLDER'] = './outputs'

# Create upload and output directories if they don't exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['OUTPUT_FOLDER'], exist_ok=True)

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

@app.route('/upload', methods=['POST'])
def upload_video():
    try:
        if 'file' not in request.files:
            print("No file uploaded")  # Debugging
            return jsonify({"status": "error", "message": "No file uploaded"}), 400
        
        file = request.files['file']
        if file.filename == '':
            print("Empty filename")  # Debugging
            return jsonify({"status": "error", "message": "Empty filename"}), 400
        
        # Check file type
        allowed_extensions = {'mp4', 'avi', 'mov', 'mkv'}
        file_extension = file.filename.rsplit('.', 1)[1].lower()
        if file_extension not in allowed_extensions:
            print(f"Unsupported file type: {file_extension}")  # Debugging
            return jsonify({
                "status": "error",
                "message": f"Unsupported file type: {file_extension}. Allowed types: {allowed_extensions}"
            }), 403
        
        # Secure the filename and save to uploads folder
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        print(f"File saved to: {file_path}")

        # Detect markers and trim video
        start, end = detect_video_markers(file_path)
        output_filename = f"trimmed_{filename}"
        output_path = os.path.join(app.config['OUTPUT_FOLDER'], output_filename)
        
        # Trim video using ffmpeg
        trim_video(file_path, output_path, start, end)
        print(f"Trimmed video saved to: {output_path}")

        return jsonify({
            "status": "success",
            "output_path": output_path,
            "message": "Video processed successfully"
        })

    except Exception as e:
        print(f"Error processing video: {str(e)}")  # Debugging
        traceback.print_exc()  # Print full traceback for debugging
        return jsonify({"status": "error", "message": str(e)}), 500
    
def trim_video(input_path, output_path, start_frame, end_frame, fps=30):
    start_time = start_frame / fps
    end_time = end_frame / fps
    (
        ffmpeg
        .input(input_path)
        .trim(start=start_time, end=end_time)
        .output(output_path)
        .run()
    )

@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({
        "status": "error",
        "message": "File too large (max 100 MB)"
    }), 413

if __name__ == "__main__":
    # Run with threading and increased timeout for large files
    run_simple(
        hostname="0.0.0.0",
        port=8000,
        application=app,
        threaded=True
    )
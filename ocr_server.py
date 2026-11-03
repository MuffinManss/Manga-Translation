from flask import Flask, request, jsonify
from manga_ocr import MangaOcr
import PIL.Image, io

app = Flask(__name__)
print("Loading OCR model...")
mocr = MangaOcr()
print("OCR server ready on port 5050")

@app.route('/ocr', methods=['POST'])
def ocr():
    img = PIL.Image.open(io.BytesIO(request.data))
    return jsonify({'text': mocr(img)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)

import requests
from PIL import Image
import io

url = 'https://images.pexels.com/photos/371633/pexels-photo-371633.jpeg?cs=srgb&dl=clouds-country-daylight-371633.jpg&fm=jpg'
img_data = requests.get(url).content

#salva no disco
# with open('teste.jpg', 'wb') as handler:
#     handler.write(img_data)

#salva na memoria
image_data = img_data # byte values of the image
image = Image.open(io.BytesIO(image_data))
image.show()

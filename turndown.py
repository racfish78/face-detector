import dlib
from PIL import Image

from imutils import face_utils
import numpy as np

import moviepy.editor as mpy

#GIF duration
duration = 4

def make_frame(t):
    draw_img = img.convert('RGBA') # returns copy of original image

    if t == 0: # no glasses first image
        return np.asarray(draw_img)

    for face in faces: 
        if t <= duration - 2: # leave 2 seconds for text
            current_x = int(face['final_pos'][0]) # start from proper x
            current_y = int(face['final_pos'][1] * t / (duration - 2)) # move to position w/ 2 secs to spare
            draw_img.paste(face['glasses_image'], (current_x, current_y) , face['glasses_image'])
        else: # draw the text for last 2 seconds
            draw_img.paste(face['glasses_image'], face['final_pos'], face['glasses_image'])
            pos = int(draw_img.height*0.8)
            draw_img.paste(text, (75, pos), text)

    return np.asarray(draw_img)

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor('shape_predictor_68_face_landmarks.dat')

# resize to a max_width to keep gif size small
max_width = 500

# open our image, convert to rgba
img = Image.open('cara.jpeg').convert('RGBA')

# two images we'll need, glasses and deal with it text
deal = Image.open("deals.png")
text = Image.open('text.png')

#resize image
if img.size[0] > max_width:
    scaled_height = int(max_width * img.size[1] / img.size[0])
    img.thumbnail((max_width, scaled_height))

img_gray = np.array(img.convert('L')) # need grayscale for dlib face detection
rects = detector(img_gray, 0)

if len(rects) == 0:
    print("No faces found, exiting.")
    exit()

print("%i faces found in source image" % len(rects))

faces = []
for rect in rects:
    face = {}
    print(rect.top(), rect.right(), rect.bottom(), rect.left())
    shades_width = rect.right() - rect.left()

    # predictor used to detect orientation in place where current face is
    shape = predictor(img_gray, rect)
    shape = face_utils.shape_to_np(shape)

    # grab the outlines of each eye from the input image
    leftEye = shape[36:42]
    rightEye = shape[42:48]

    # compute the center of mass for each eye
    leftEyeCenter = leftEye.mean(axis=0).astype("int")
    rightEyeCenter = rightEye.mean(axis=0).astype("int")

    # compute the angle between the eye centroids
    dY = leftEyeCenter[1] - rightEyeCenter[1] 
    dX = leftEyeCenter[0] - rightEyeCenter[0]
    angle = np.rad2deg(np.arctan2(dY, dX)) 

    # resize glasses to fit face width
    current_deal = deal.resize((shades_width, int(shades_width * deal.size[1] / deal.size[0])),
                               resample=Image.LANCZOS)
    # rotate and flip to fit eye centers
    current_deal = current_deal.rotate(angle, expand=True)
    current_deal = current_deal.transpose(Image.FLIP_TOP_BOTTOM)

    # add the scaled image to a list, shift the final position to the
    # left of the leftmost eye
    face['glasses_image'] = current_deal
    left_eye_x = leftEye[0,0] - shades_width // 4 + 10
    left_eye_y = leftEye[0,1] - shades_width // 6
    face['final_pos'] = (left_eye_x, left_eye_y)
    faces.append(face)

animation = mpy.VideoClip(make_frame, duration=duration)
animation.write_gif("deal.gif", fps=10)

clip = mpy.VideoFileClip("deal.gif")
clip.write_videofile("deal.mp4")
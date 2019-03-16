import dlib
from PIL import Image

from imutils import face_utils
import numpy as np

import moviepy.editor as mpy

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


def coolShades(url):


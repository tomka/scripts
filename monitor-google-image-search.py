#!/usr/bin/python3

import os, sys, requests, datetime, codecs, shutil, hashlib, time
from lxml import html

def monitor(search_term, delay, n_images=50):
    while True:
        get_images(search_term, n_images)
        time.sleep(delay * 60)

def get_images(search_term, n_images=50):
    width = 1920
    height = 1080
    url = "https://www.google.com/search?q={}&biw={}&bih={}&tbm=isch".format(
            search_term, width, height);
    page = requests.get(url)

    # Find all google image search results
    tree = html.fromstring(page.content)
    image_results = tree.xpath('//img[@alt="Image result for {}"]'.format(search_term))

    # Store image result list and images
    headers = {
        "accept": "2image/webp,image/*,*/*;q=0.8",
        "accept-encoding": "gzip, deflate, sdch",
        "accept-language": "en-US,en;q=0.8,de;q=0.6",
        "cache-control": "no-cache",
        "pragma": "no-cache",
        "referer": "https://www.google.com/"
    }

    # Create target dir
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M")
    target_dir = "google-image-search-{}-{}".format(search_term, timestamp)
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)

    print("{}: Found {} images".format(timestamp, len(image_results)))
    
    # Get and write image files
    for n, i in enumerate(image_results):
        src = i.attrib['src']
        img = requests.get(src, headers, stream=True)
        if img.status_code != 200:
            print("Couldn't load image: " + src)
            continue

        img.raw.decode_content = True

        # Get data MD5
        sig = hashlib.md5()
        for chunk in img.iter_content(128):
            sig.update(chunk)
        hex_sig = sig.hexdigest()

        filename = os.path.join(target_dir, "{}_{}.jpeg".format(n, hex_sig))
        f = open(filename, "wb")
        shutil.copyfileobj(img.raw, f)
        f.close()

def print_usage():
    print("{} <search_term> <delay>".format(__file__))
    print("<delay> - Wait time between requests in minutes")

if __name__ == '__main__':
    if 3 != len(sys.argv):
        print_usage()
        sys.exit(1)
    else:
        monitor(sys.argv[1], int(sys.argv[2]))

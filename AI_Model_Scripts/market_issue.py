import numpy as np
import pandas as pd
import unicodedata
import matplotlib.pyplot as plt
import nltk
import requests
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from bs4 import BeautifulSoup
from pandas.core.frame import DataFrame

def get_attractions(url, data=None):
    wb_data=requests.get(url)
    soup=BeautifulSoup(wb_data.text,'html.parser')
    titles=soup.select('.articleListTitle > a')
    times = soup.select('.listRight > span ')
    for title, time in zip (titles, times):
        data={
            'title':title.get_text(),
            'times':time.get_text(),
        }
        print (data)
     return data

urls=['https://tokenpost.kr/regulation?page={}'.format(str(i)) for i in range (1,17)]

data_sum=[]
for single_url in urls:
    data_sum.append(get_attractions(single_url))

title=[]
for i in range(1,16):
    title.append(data_sum[i]['title'])
print(title)

time=[]
for i in range(1,16):
    time.append(data_sum[i]['time'])

c={
    "time": time,
    "title": title
}
df_stocks=DataFrame(c)

df=df_stocks[['time']].copy()
df["compound"] = ''# compound sentence tendency judgement
df["neg"] = ''#negative sentence
df["neu"] = ''#neutral sentence
df["pos"] = ''#positive sentence

# need the translate API here

sid = SentimentIntensityAnalyzer()
for sen in title:
    print(sen)
    ss = sid.polarity_scores(sen)
    for k in ss:
        print('{0}:{1},'.format(k, ss[k]), end='')
    print()


####
view = [ "ICO 신규 규제안 발표",
        "Loved the ambience",
        "The place is not easy to locate"]
sid = SentimentIntensityAnalyzer()
for sen in view:
    print(sen)
    ss = sid.polarity_scores(sen)
    for k in ss:
        print('{0}:{1},'.format(k, ss[k]), end='')
    print()
####

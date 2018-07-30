import numpy as np
import pandas as pd
import unicodedata
import matplotlib.pyplot as plt
import nltk
import requests
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from bs4 import BeautifulSoup
from pandas.core.frame import DataFrame

## crawling
def get_attractions(url, data=None):
    data_sume=[]
    wb_data=requests.get(url)
    soup=BeautifulSoup(wb_data.text,'html.parser')
    titles=soup.select('.articleListTitle > a')
    times = soup.select('.listRight > span ')
    for title, time in zip (titles, times):
        data={
            'title':title.get_text(),
            'time':time.get_text(),
        }
        data_sume.append(data)
    print(data_sume)
    return data_sume

urls=['https://tokenpost.kr/regulation?page={}'.format(str(i)) for i in range (1,18)]
data_sum=[]
for single_url in urls:
    data_sum.append(get_attractions(single_url))

    
#### restruct the event time and event title
title=[]
for i in range(17):
    for j in range(7):
      title.append(data_sum[i][j]['title'])
print(title)
time=[]
for i in range(17):
    for j in range(7):
     time.append(data_sum[i][j]['time'])
c={
    "time": time,
    "title": title
}

### NTLK　패키니를 이용하여 자연어 처리, 제목 분석
df_stocks=DataFrame(c)
df=df_stocks[['time']].copy()
df["compound"] = ''# compound judgement of sentence tendency 
df["neg"] = ''#negative sentence
df["neu"] = ''#neutral sentence
df["pos"] = ''#positive sentence

# need the translate API here

## conducting the SentimentIntensityAnalyzer
sid = SentimentIntensityAnalyzer()
for date, row in df_stocks.T.iteritems():
    try:
        sentence = unicodedata.normalize('NFKD', df_stocks.loc[date, 'title'])
        ss = sid.polarity_scores(sentence)
        df.at[date, 'compound'] = ss['compound']
        df.at[date, 'neg'] = ss['neg']
        df.at[date, 'neu'] = ss['neu']
        df.at[date, 'pos'] = ss['pos']
    except TypeError:
        print(df_stocks.loc[date, 'title'])
        print(date)
print(df)


#### SentimentIntensityAnalyzer test 
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

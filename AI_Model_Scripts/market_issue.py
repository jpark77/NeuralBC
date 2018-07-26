from bs4 import BeautifulSoup
import requests

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

urls=['https://tokenpost.kr/regulation?page={}'.format(str(i)) for i in range (1,17)]

for single_url in urls:
    get_attractions(single_url)

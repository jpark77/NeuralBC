### Our Test model
##### WSAEs-LSTM = Wavelet Transform + Stacked Autoencoder + LSTM From
##### Bao W, Yue J, Rao Y (2017) A deep learning framework for financial time series using stacked autoencoders and long-short term memory. PLOS ONE 12(7): e0180944.
![alt text](./W_Bao_et_al.PNG)

### 참조 모델
##### Ciaian P, Rajcaniova M, Kancs d'A(2016) The Economics of BitCoin Price Formation Applied Economics 48(19):1799-1815
> 1 Supply-Demend Fundamentals  
2 Wikipedia View  
3 Global financial indicators

#### 데이터 수집
##### 종류 : OHLC(Open High Low Close) price, Trading Volume, Market issues, etc
OHLC의 경우는 JSON, csv와 같은 준정형데이터(Semi-structured data)형태로 가지고 올 수 있어서 쉽게 정형데이터(Structured data)로 가공할 수 있음

JSON
> {'price_close': 6.31,
  'price_high': 7.1,
  'price_low': 5.52,
  'price_open': 6.2,
  'time_close': '2012-01-25T21:37:14.0000000Z',
  'volume_traded': 993.32690311}, ... 
  
##### 테이블 스키마(schema)
##### OHLC_BTCvsUSD (From https://kr.investing.com/crypto/currencies)

| Close       | High       | Low       | Open       | Date       | Volume        |
| ----------- | ---------- | --------- | ---------- | ---------- | ------------- |
| 6.31        | 7.1        | 5.52      | 6.2        | 2012-01-25 | 993.32690311  |
| ....        |....        | ....      | ...        | ....       | ....          |         

##### Market_issues (From http://www.decenter.kr/ etc)

| Date        | Issues                                                                             |
| ----------- | ---------------------------------------------------------------------------------- |
| 2018-07-19  | '美 청문회, 긍정적 목소리 높아…"암호화폐는 사회적 산물, 미래 인프라로 지원해야" ' |
| 2018-07-20  | '美 금융소비자보호국, 블록체인 규제 샌드박스 시행'                                 |
| ....        | ....                                                                               |

##### Hash_rate  (From https://blockchain.info/q/hashrate)

| Date        |  Hash_rate   |
| ----------- | ------------ |
| 2018-03-29  | 26162835     | 
| 2018-03-30  | 27884074     |
| ....        | ....         |

##### Macroeconomic indicators (From quandl.com)

| Date        | US_Crude_Oil   |  US_Gov_Interest_rate | US_Treasury_yield_10yr | ... |
| ----------- | -------------- | --------------------- | ---------------------- | --- |
| 2012-01-20  |   98.15        |   0.05                |  2.05                  | ... |
| ....        | .....          | ......                | ......                 | ... |

##### Volume of daily BitCoin views on Wikipedia (From [Wiki PageViews Analysis](https://tools.wmflabs.org/pageviews/?project=en.wikipedia.org&platform=all-access&agent=user&range=latest-20&pages=Cat|Dog) )

| Date        |  Views      |
| ----------- | ----------- |
| 2015-07-01  | 12957       |
| 2015-07-02  | 9802        |
| ....        | ....        |

MongoDB의 경우 데이터를 BSON으로 저장하고, 스키마를 사전에 정의하지 않아도 되지만 
테이블 JOIN이 되지 않고 Embedded document라는 별도의 방식으로 지원하므로 연구가 필요
예를 들어 위의 Date 컬럼을 이용해서 JOIN을 할 수 없다.

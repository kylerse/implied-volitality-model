### Implied Volitality Model
#### This repository contains all the material used for the final project of course *Computer Programming in Financial Engineering* developed by Kai Xiang, including all the codes, reference, data etc.

### Brief Q&A:
Q: What is your question? 

>A: This project intends to model the dynamic mechanism of the implied volatiltiy. The main concern is to find a model to 
predict the future volatility, since we know the volatiltiy is a very functurating parameter.

Q: How you attempt to answer your question? What programming approach have you used? Loops, simulation, packages, etc  

>A: About the model part, I adopt a standard 2-stage methods, first using a multifactor model to capture the characteristics of the implied volatility surface, then build time series models to analysis its behavior. As for the programming part, I use matlab as main language, with some of its package which are specially used for fitting functions, and I use a few python scripts when clean and merge the data.

Q: What is your data set?  

>A: My [dataset](https://github.com/kylerse/implied-volitality-model/tree/master/data) is from CSMAR. It consists of several tables:  
  - 个股期权合约基本信息历史表  
  - 个股期权合约基本信息表  
  - 个股期权合约定价重要参数表  
  - 个股期权合约日交易基础表  
  - 个股期权合约日交易衍生表  
  - 个股期权品种基本信息表  
  - 个股期权当天行情表  
  
Q: What is your main result clearly.  What is the implication if it has? Also graphs and tables should be clearly labelled and annotated. 

>A: The main result is to build a model to predict the implied volatility, and using the model develop several trading strategies. And then I compare to several naive trading stragtegies using yesterday's observation, and find that the model has much better performance.
So the contribution of this work is coming up with a quite noval trading strategy that based on relative implied volatility values.


### Several studies are finished in this project
1. Collect option data of several stocks and indexes that are traded in Shanghai Stock Exchange. Link is [here](https://github.com/kylerse/implied-volitality-model/tree/master/data). I do some effort to merge these datasets into a single excel files, calculate some derivative parameters, rerange some important imformation such as option type, remaing term, trading date etc. 

2. Using a multi-factor model to model the implied volatility surface.
![surface](./pic/surface.png)
3. ARMA(2,1) model to predict nextday's parameters.
![arma](./pic/arma2.png)
4. Kalman Filter (unfinished)
5. Trading strategy comparision.
![strategies](./pic/predict3.png)

#### Further extension
